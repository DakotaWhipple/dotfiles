-- Black-box judge: compiles + runs a user's Kotlin submission against a set
-- of tests via `kotlinc -script`. Only behavior is judged — outputs and
-- measured wall time — never structure or style. No daemon in v1; each run
-- pays ~3s compiler startup, run async so it never blocks the editor.
local M = {}

-- Hard kill for infinite loops / hopelessly slow solutions. Perf budgets
-- (budget_ms) are per-test and much tighter; this is just the safety net.
local EXEC_TIMEOUT_MS = 30000

local function tmp_path()
  local dir = "/tmp/dojo-leetcode"
  vim.fn.mkdir(dir, "p")
  return string.format("%s/submission_%d_%d.kts", dir, os.time(), math.random(100000))
end

-- __dojoEquals: one comparison rule for everything, so archetypes never
-- declare a "compare mode". __dojoShow: human-readable rendering (arrays
-- print their contents, not [I@1a2b3c) so results read like a real console.
local HARNESS_HEADER = [[

fun __dojoEquals(actual: Any?, expected: Any?): Boolean {
    if (actual is IntArray && expected is IntArray) return actual.contentEquals(expected)
    if (actual is Array<*> && expected is Array<*>) return actual.contentDeepEquals(expected)
    return actual == expected
}
fun __dojoShow(v: Any?): String = when (v) {
    is IntArray -> v.contentToString()
    is LongArray -> v.contentToString()
    is DoubleArray -> v.contentToString()
    is BooleanArray -> v.contentToString()
    is CharArray -> v.contentToString()
    is Array<*> -> v.contentDeepToString()
    is String -> "\"" + v + "\""
    else -> v.toString()
}
]]

--- @param tests table[] ordered list of { call = "kotlin expr", expected = "kotlin expr" }
local function render_harness(tests)
  local lines = { HARNESS_HEADER, "val __cases = listOf<Triple<Int, () -> Any?, Any?>>(" }
  for i, t in ipairs(tests) do
    table.insert(
      lines,
      string.format("    Triple(%d, { %s }, %s),", i - 1, t.call, t.expected)
    )
  end
  table.insert(lines, ")")
  table.insert(lines, [[
for ((idx, fn, expected) in __cases) {
    println("DOJO_BEGIN $idx")
    try {
        val __t0 = System.nanoTime()
        val actual = fn()
        val __ms = (System.nanoTime() - __t0) / 1_000_000
        println("DOJO_TIME $idx $__ms")
        println("DOJO_ACTUAL $idx ${__dojoShow(actual)}")
        if (__dojoEquals(actual, expected)) {
            println("DOJO_RESULT $idx PASS")
        } else {
            println("DOJO_RESULT $idx FAIL expected ${__dojoShow(expected)}")
        }
    } catch (e: Throwable) {
        println("DOJO_RESULT $idx ERROR ${e::class.simpleName}: ${e.message}")
    }
}
println("DOJO_DONE")
]])
  return table.concat(lines, "\n")
end

local function run_kotlinc(source, on_done)
  local path = tmp_path()
  local f = io.open(path, "w")
  if not f then
    on_done(nil, "could not write temp file " .. path)
    return
  end
  f:write(source)
  f:close()

  local started = vim.uv.hrtime()
  vim.system(
    { "kotlinc", "-script", path },
    { text = true, timeout = EXEC_TIMEOUT_MS },
    function(res)
      vim.schedule(function()
        os.remove(path)
        res.elapsed_ms = math.floor((vim.uv.hrtime() - started) / 1e6)
        on_done(res)
      end)
    end
  )
end

local function timeout_or_stderr(res)
  if res.signal and res.signal ~= 0 then
    return ("killed after %ds — infinite loop, or a solution too slow to even finish?"):format(
      EXEC_TIMEOUT_MS / 1000
    )
  end
  return (res.stderr ~= "" and res.stderr) or ("kotlinc exited " .. tostring(res.code))
end

--- Runs `user_source` (must define the archetype's `fun solve(...)` — any
--- helpers/classes around it are fine) against `tests` (already flattened
--- across every stage up to the current one, for regression enforcement).
--- Tests may carry `budget_ms`: exceeding it converts a PASS into SLOW.
--- Calls `on_result` with:
---   { ok, compile_error?, elapsed_ms, console = {lines of user println},
---     results = { [i] = { status = PASS|FAIL|ERROR|SLOW, detail, ms, actual } } }
function M.run(user_source, tests, on_result)
  -- How many script lines belong to the user: lets diagnostics map kotlinc
  -- errors back onto the buffer instead of pointing into the harness.
  local user_line_count = #vim.split(user_source, "\n")
  run_kotlinc(user_source .. "\n" .. render_harness(tests), function(res, write_err)
    if write_err then
      on_result({ ok = false, compile_error = write_err, user_line_count = user_line_count })
      return
    end
    if not res.stdout or not res.stdout:find("DOJO_DONE") then
      on_result({
        ok = false,
        compile_error = timeout_or_stderr(res),
        elapsed_ms = res.elapsed_ms,
        user_line_count = user_line_count,
      })
      return
    end

    -- Sequential parse: DOJO_* lines drive state; anything else is the
    -- user's own println output — captured, never discarded. That output
    -- is half the "real console" feel.
    local results, console = {}, {}
    for _, line in ipairs(vim.split(res.stdout, "\n")) do
      local idx, rest

      idx = line:match("^DOJO_BEGIN (%d+)$")
      if idx then
        results[tonumber(idx) + 1] = {}
        goto continue
      end

      idx, rest = line:match("^DOJO_TIME (%d+) (%d+)$")
      if idx then
        results[tonumber(idx) + 1].ms = tonumber(rest)
        goto continue
      end

      idx, rest = line:match("^DOJO_ACTUAL (%d+) (.*)$")
      if idx then
        results[tonumber(idx) + 1].actual = rest
        goto continue
      end

      idx, rest = line:match("^DOJO_RESULT (%d+) (.*)$")
      if idx then
        local r = results[tonumber(idx) + 1]
        r.status = rest:match("^%u+")
        r.detail = vim.trim(rest:sub(#r.status + 1))
        goto continue
      end

      if line ~= "DOJO_DONE" and line ~= "" then
        table.insert(console, line)
      end

      ::continue::
    end

    -- Budget policy lives here (Lua), measurement lives in the harness.
    for i, t in ipairs(tests) do
      local r = results[i]
      if r and r.status == "PASS" and t.budget_ms and r.ms and r.ms > t.budget_ms then
        r.status = "SLOW"
        r.detail = string.format(
          "correct but %dms > %dms budget. %s",
          r.ms,
          t.budget_ms,
          t.slow_msg or "The input is adversarially large — is your approach super-linear?"
        )
      end
    end

    local all_pass = #tests > 0
    for i = 1, #tests do
      if not results[i] or results[i].status ~= "PASS" then
        all_pass = false
        break
      end
    end

    on_result({
      ok = all_pass,
      results = results,
      console = console,
      elapsed_ms = res.elapsed_ms,
      -- kotlinc warnings (unused variable, deprecation, …) still arrive on
      -- stderr when compilation succeeds — surface them as diagnostics.
      compile_warnings = res.stderr ~= "" and res.stderr or nil,
      user_line_count = user_line_count,
    })
  end)
end

--- REPL-ish one-off: compile the buffer, evaluate `expr`, return whatever
--- happened — value, prints, or exception. No judgment, just output.
--- Calls on_result with { value?, error?, console = {...}, elapsed_ms }.
function M.try(user_source, expr, on_result)
  local script = table.concat({
    user_source,
    HARNESS_HEADER,
    "try {",
    "    val __r = run { " .. expr .. " }",
    '    println("DOJO_TRY_VALUE ${__dojoShow(__r)}")',
    "} catch (e: Throwable) {",
    '    println("DOJO_TRY_ERROR ${e::class.simpleName}: ${e.message}")',
    "}",
  }, "\n")

  run_kotlinc(script, function(res, write_err)
    if write_err then
      on_result({ error = write_err })
      return
    end
    if not res.stdout or not (res.stdout:find("DOJO_TRY_VALUE") or res.stdout:find("DOJO_TRY_ERROR")) then
      on_result({ error = timeout_or_stderr(res), elapsed_ms = res.elapsed_ms })
      return
    end

    local out = { console = {}, elapsed_ms = res.elapsed_ms }
    for _, line in ipairs(vim.split(res.stdout, "\n")) do
      local v = line:match("^DOJO_TRY_VALUE (.*)$")
      local e = line:match("^DOJO_TRY_ERROR (.*)$")
      if v then
        out.value = v
      elseif e then
        out.error = e
      elseif line ~= "" then
        table.insert(out.console, line)
      end
    end
    on_result(out)
  end)
end

return M
