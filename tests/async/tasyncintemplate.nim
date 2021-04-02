discard """
  output: '''
42
1
2
3
4
'''
"""

import asyncdispatch

# bug #16159
template foo() =
  proc temp(): Future[int] {.async.} = return 42
  proc tempVoid(): Future[void] {.async.} = echo await temp()

foo()
waitFor tempVoid()


block: # bug #16786
  block:
    proc main(a: int|string)=
      proc bar(b: int|string) = echo b
      bar(a)
    main(1)

  block:
    proc main(a: int) : Future[void] {.async.} =
      proc bar(b: int): Future[void] {.async.} = echo b
      await bar(a)
    waitFor main(2)

  block:
    proc main(a: int) : Future[void] {.async.} =
      proc bar(b: int | string): Future[void] {.async.} = echo b
      await bar(a)
    waitFor main(3)

  block:
    # bug
    proc main(a: int|string) =
      proc bar(b: int): Future[void] {.async.} = echo b
      waitFor bar(a)
    main(4)
