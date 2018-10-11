discard """
  line: 9
  errormsg: '''ambiguous call; both foobar.async'''
"""

import foobar
import asyncdispatch, macros

proc bar() {.async.} =
  echo 42

proc foo() {.async.} = 
  await bar()

asyncCheck foo()
runForever()
