discard """
  disabled: i386
  output: '''
In doStuff()
In initProcess()
TEST
initProcess() done
Crashes before getting here!
'''
  joinable: false
"""

import std/os
import std/typedthreads

proc whatever() {.thread, nimcall.} =
  echo("TEST")

proc initProcess(): void =
  echo("In initProcess()")
  var thread: Thread[void]
  createThread(thread, whatever)
  joinThread(thread)
  echo("initProcess() done")

proc doStuff(): void =
  echo("In doStuff()")
  # ...
  initProcess()
  sleep(500)
  # ...
  echo("Crashes before getting here!")

doStuff()
