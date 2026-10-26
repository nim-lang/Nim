discard """
  errormsg: "undeclared identifier: 'waitFor'"
  cmd: "nim c --parsem:on --experimental:strictEffects $file"
  line: 15
"""

# `--parsem:on` variant of tests/async/tasync_nofuture: the body of `a`, where
# `await 0` is rejected, is checked after the top-level `waitFor` (which is not
# imported by `async`), so that error comes first.
import async

proc a {.async.} =
  await 0

waitFor a()
