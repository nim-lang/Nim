discard """
  output: '''
1
2
3
4
1
2
1
6
'''
"""
import asyncdispatch, asyncnet

proc main {.async.} =
  proc f: Future[int] {.async.} =
    discard
    echo 1
    discard
    result = 2
    discard

  let x = await f()
  echo x
  echo 3

  proc g: Future[int] {.async.} =
    discard
    echo 4
    discard
    result = 6
    discard
    echo await f()
    discard await f()

  discard await g()
  echo 6

waitFor(main())
