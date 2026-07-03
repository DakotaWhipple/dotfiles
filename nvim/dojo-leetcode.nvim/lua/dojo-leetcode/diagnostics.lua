-- Leetcode-level diagnostics, published through nvim's native diagnostic
-- pipeline so they sit right next to kotlin-lsp's squiggles — same gutter,
-- same virtual text, different source. Two layers:
--   kotlinc compile errors → mapped back onto the real buffer lines
--   judged test failures   → classified (off-by-one? edge case? too slow?)
--                            and anchored to your solve() definition
local M = {}

local ns = vim.api.nvim_create_namespace("dojo-leetcode-judge")

function M.clear(buf)
  if buf and vim.api.nvim_buf_is_valid(buf) then
    vim.diagnostic.set(ns, buf, {})
  end
end

-- The judge compiles user_source + harness as one script, so kotlinc line
-- numbers ≤ the user's line count belong to the buffer verbatim. Anything
-- past that is harness territory (usually a broken test expression).
local function compile_error_diags(compile_error, user_line_count, buf_line_count)
  local diags = {}
  for lnum, col, kind, msg in compile_error:gmatch("%.kts:(%d+):(%d+): (%a+): ([^\n]+)") do
    lnum, col = tonumber(lnum), tonumber(col)
    if kind == "error" or kind == "warning" then
      local in_user_code = lnum <= user_line_count
      diags[#diags + 1] = {
        lnum = in_user_code and math.min(lnum, buf_line_count) - 1 or 0,
        col = in_user_code and col - 1 or 0,
        severity = kind == "error" and vim.diagnostic.severity.ERROR or vim.diagnostic.severity.WARN,
        message = in_user_code and msg or ("in test harness (bad test expression?): " .. msg),
        source = "dojo-judge",
      }
    end
  end
  return diags
end

-- Anchor for test-failure diagnostics: the `fun solve` line. The failure is
-- about behavior, not a token, so the function signature is the honest spot.
local function solve_line(buf)
  local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
  for i, l in ipairs(lines) do
    if l:match("^%s*fun%s+solve%s*%(") then
      return i - 1
    end
  end
  return 0
end

-- Pull the leading number out of a rendered kotlin value ("3", "-2", "[1, 2]").
local function leading_number(s)
  if not s then
    return nil
  end
  return tonumber(s:match("^%-?%d+%.?%d*$"))
end

-- Classify one failed test into a diagnostic. This is where "leetcode level"
-- lives: the judge doesn't just say FAIL, it says what kind of miss it smells.
local function classify(test, r)
  local sev = vim.diagnostic.severity
  local label = test.diag -- archetype-authored classification wins
  local call = test.call

  if r.status == "ERROR" then
    local hint = ""
    if r.detail:match("IndexOutOfBounds") then
      hint = " — indexing past the end: off-by-one in a loop bound?"
    elseif r.detail:match("NullPointer") then
      hint = " — something you assumed non-null wasn't"
    elseif r.detail:match("StackOverflow") then
      hint = " — unbounded recursion: where's the base case?"
    end
    return {
      severity = sev.ERROR,
      message = ("throws on %s: %s%s"):format(call, r.detail, hint),
    }
  end

  if r.status == "SLOW" then
    return {
      severity = sev.INFO,
      message = ("correct but over budget on %s (%dms) — is the approach super-linear?"):format(call, r.ms or 0),
    }
  end

  -- Plain FAIL. Heuristics, cheapest first.
  local expected = r.detail and r.detail:match("^expected (.*)$")
  local a, e = leading_number(r.actual), leading_number(expected)
  if label then
    return {
      severity = sev.WARN,
      message = ("missing %s: %s → %s, expected %s"):format(label, call, r.actual or "?", expected or "?"),
    }
  end
  if a and e and math.abs(a - e) == 1 then
    return {
      severity = sev.WARN,
      message = ("off-by-one? %s → %s, expected %s (check loop bounds / <= vs <)"):format(call, r.actual, expected),
    }
  end
  if r.actual == "[]" or r.actual == "0" or r.actual == "null" or r.actual == '""' then
    return {
      severity = sev.WARN,
      message = ("%s returned the empty/default value %s, expected %s — does the logic ever fire?"):format(
        call, r.actual, expected or "?"
      ),
    }
  end
  return {
    severity = sev.WARN,
    message = ("wrong answer on %s: got %s, expected %s"):format(call, r.actual or "?", expected or "?"),
  }
end

--- Publish diagnostics for a judge result onto the code buffer.
--- Clears everything first, so a clean run wipes the slate.
function M.publish(buf, result)
  if not (buf and vim.api.nvim_buf_is_valid(buf)) then
    return
  end
  local buf_line_count = vim.api.nvim_buf_line_count(buf)
  local diags = {}

  if result.compile_error then
    diags = compile_error_diags(result.compile_error, result.user_line_count or buf_line_count, buf_line_count)
  elseif result.results then
    -- Compile succeeded, but kotlinc may still have warned (unused variable,
    -- deprecation). Same parser — the pattern carries the severity.
    if result.compile_warnings then
      diags = compile_error_diags(result.compile_warnings, result.user_line_count or buf_line_count, buf_line_count)
    end
    local anchor = solve_line(buf)
    for i, test in ipairs(result.tests or {}) do
      local r = result.results[i]
      if r and r.status and r.status ~= "PASS" then
        local d = classify(test, r)
        d.lnum = anchor
        d.col = 0
        d.source = "dojo-judge"
        diags[#diags + 1] = d
      end
    end
  end

  vim.diagnostic.set(ns, buf, diags)
end

return M
