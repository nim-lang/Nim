discard """
  output: '''123
abc'''
"""

# bug #4856

import asyncdispatch

proc say[T](t: T): Future[void] {.async.} =
  echo $t

waitFor(say(123))
waitFor(say("abc"))
