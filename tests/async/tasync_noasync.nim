discard """
  errormsg: "undeclared identifier: 'await'"
  cmd: "nim c $file"
  file: "tasync_noasync.nim"
"""
import async

proc a {.async.} =
  discard

await a()

# if we overload a fallback handler to get
# await only available within {.async.}
# we would need `{.dirty.}` templates for await