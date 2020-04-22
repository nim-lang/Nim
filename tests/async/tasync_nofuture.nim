discard """
  errormsg: "await only available within {.async.} or {.multisync.}, if in {.async.} it is expecting Future[T], got int"
  cmd: "nim c $file"
  file: "asyncmacro.nim"
"""
import async

proc a {.async.} =
  await 0

waitFor a()
