discard """
  errormsg: '''ambiguous call; both foobar.async(body: untyped) [declared in foobar.nim(2, 7)] and asyncdispatch.async(prc: untyped) [declared in ../../lib/pure/asyncmacro.nim(333, 7)] match for: ()'''
  line: 9
"""

import foobar
import asyncdispatch, macros

proc bar() {.async.} =
  echo 42

proc foo() {.async.} =
  await bar()

asyncCheck foo()
runForever()
