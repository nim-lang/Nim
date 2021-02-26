discard """
  exitCode: 1
 outputsub: "Error: unhandled exception: foobar: 13"
"""

# note: this needs `--unhandled-rejections=strict`, see D20210217T215950

import std/asyncjs
from std/sugar import `=>`

proc fn(n: int): Future[int] {.async.} =
  if n >= 7: raise newException(ValueError, "foobar: " & $n)
  else: result = n

proc main() {.async.} =
  let x1 = await fn(6)
  doAssert x1 == 6
  await fn(7).catch((a: Error) => (discard))
  let x3 = await fn(13)
  doAssert false # shouldn't go here, should fail before

discard main()
