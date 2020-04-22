discard """
  errormsg: "await only available within {.async.}"
  cmd: "nim c $file"
  file: "asyncmacro.nim"
"""
import async

proc a {.async.} =
  discard

await a()

