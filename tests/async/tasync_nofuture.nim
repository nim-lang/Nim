discard """
  errormsg: "await expects Future[T], got int"
  cmd: "nim c $file"
  file: "asyncmacro.nim"
"""
import async

proc a {.async.} =
  await 0

# waitFor is declared in std/asyncdispatch so the following would trigger a different error with nimLazySemcheck
# waitFor a()
