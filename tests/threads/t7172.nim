discard """
  output: '''
In doStuff()
In initProcess()
initProcess() done
TEST
Crashes before getting here!
'''
"""

import std/os

proc whatever() {.thread, nimcall.} =
  echo("TEST")

proc initProcess(): void =
  echo("In initProcess()")
  var thread: Thread[void]
  createThread(thread, whatever)
  echo("initProcess() done")

proc doStuff(): void =
  echo("In doStuff()")
  # ...
  initProcess()
  sleep(500)
  # ...
  echo("Crashes before getting here!")

doStuff()
