discard """
  errormsg: "'yield' only allowed in an iterator"
  cmd: "nim c $file"
  file: "asyncmacro.nim"
"""
import async

proc a {.async.} =
  discard

await a()

# if we overload a fallback handler to get
# await only available within {.async.}
# we would need `{.dirty.}` templates for await
