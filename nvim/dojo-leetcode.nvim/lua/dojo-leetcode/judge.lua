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

-- Every test's actual/expected values are compared with a single equals
-- helper that special-cases IntArray/Array (reference equality otherwise)
-- so archetypes never need to declare a "compare mode" per test.
local HARNESS_HEADER = [[

fun __dojoEquals(actual: Any?, expected: Any?): Boolean {
    if (actual is IntArray && expected is IntArray) return actual.contentEquals(expected)
    if (actual is Array<*> && expected is Array<*>) return actual.contentDeepEquals(expected)
    return actual == expected
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
    try {
        val __t0 = System.nanoTime()
        val actual = fn()
        val __ms = (System.nanoTime() - __t0) / 1_000_000
        println("DOJO_TIME $idx $__ms")
        if (__dojoEquals(actual, expected)) {
            println("DOJO_RESULT $idx PASS")
        } else {
            println("DOJO_RESULT $idx FAIL actual=$actual expected=$expected")
        }
    } catch (e: Throwable) {
        println("DOJO_RESULT $idx ERROR ${e::class.simpleName}: ${e.message}")
    }
}
println("DOJO_DONE")
]])
  return table.concat(lines, "\n")
end

--- Runs `user_source` (must define the archetype's `fun solve(...)` — any
--- helpers/classes around it are fine) against `tests` (already flattened
--- across every stage up to the current one, for regression enforcement).
--- Tests may carry `budget_ms`: exceeding it converts a PASS into SLOW.
--- Calls `on_result` with:
---   { ok = bool, compile_error = string|nil,
---     results = { [i] = { status = "PASS"|"FAIL"|"ERROR"|"SLOW", detail, ms } } }
function M.run(user_source, tests, on_result)
  local path = tmp_path()
  local f = io.open(path, "w")
  if not f then
    on_result({ ok = false, compile_error = "could not write temp file " .. path })
    return
  end
  f:write(user_source)
  f:write("\n")
  f:write(render_harness(tests))
  f:close()

  vim.system(
    { "kotlinc", "-script", path },
    { text = true, timeout = EXEC_TIMEOUT_MS },
    function(res)
      vim.schedule(function()
        os.remove(path)

        if not res.stdout or not res.stdout:find("DOJO_DONE") then
          local msg
          if res.signal and res.signal ~= 0 then
            msg = ("killed after %ds — infinite loop, or a solution too slow to even finish?"):format(
              EXEC_TIMEOUT_MS / 1000
            )
          else
            msg = (res.stderr ~= "" and res.stderr) or ("kotlinc exited " .. tostring(res.code))
          end
          on_result({ ok = false, compile_error = msg })
          return
        end

        local results = {}
        for idx, status, detail in res.stdout:gmatch("DOJO_RESULT (%d+) (%u+)([^\n]*)") do
          results[tonumber(idx) + 1] = { status = status, detail = vim.trim(detail) }
        end
        for idx, ms in res.stdout:gmatch("DOJO_TIME (%d+) (%d+)") do
          local r = results[tonumber(idx) + 1]
          if r then
            r.ms = tonumber(ms)
          end
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

        local all_pass = true
        for i = 1, #tests do
          if not results[i] or results[i].status ~= "PASS" then
            all_pass = false
            break
          end
        end

        on_result({ ok = all_pass, results = results })
      end)
    end
  )
end

return M
