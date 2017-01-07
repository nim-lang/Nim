#
#
#            Nim's Runtime Library
#        (c) Copyright 2015 Rokas Kupstys
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

when not defined(nimCoroutines) and not defined(nimdoc):
  {.error: "Coroutines require -d:nimCoroutines".}

import os, times
import macros
import arch
import lists

const defaultStackSize = 512 * 1024

type Coroutine = ref object
  # prev: ptr Coroutine
  # next: ptr Coroutine
  ctx: JmpBuf
  fn: proc()
  started: bool
  lastRun: float
  sleepTime: float
  stack: pointer
  stacksize: int

var coroutines = initDoublyLinkedList[Coroutine]()
var current: Coroutine
var mainCtx: JmpBuf


proc GC_addStack(starts: pointer) {.cdecl, importc.}
proc GC_removeStack(starts: pointer) {.cdecl, importc.}
proc GC_setCurrentStack(starts, pos: pointer) {.cdecl, importc.}

proc start*(c: proc(), stacksize: int=defaultStackSize) =
  ## Adds coroutine to event loop. It does not run immediately.
  var coro = Coroutine()
  coro.fn = c
  while coro.stack == nil:
    coro.stack = alloc0(stacksize)
  coro.stacksize = stacksize
  coroutines.append(coro)

{.push stackTrace: off.}
proc suspend*(sleepTime: float=0) =
  ## Stops coroutine execution and resumes no sooner than after ``sleeptime`` seconds.
  ## Until then other coroutines are executed.
  ##
  ## This is similar to a `yield`:idx:, or a `yieldFrom`:idx in Python.
  var oldFrame = getFrame()
  var sp {.volatile.}: pointer
  GC_setCurrentStack(current.stack, cast[pointer](addr sp))
  current.sleepTime = sleepTime
  current.lastRun = epochTime()
  if setjmp(current.ctx) == 0:
    longjmp(mainCtx, 1)
  setFrame(oldFrame)
{.pop.}

proc run*() =
  ## Starts main event loop which exits when all coroutines exit. Calling this proc
  ## starts execution of first coroutine.
  var node = coroutines.head
  var minDelay: float = 0
  var frame: PFrame
  while node != nil:
    var coro = node.value
    current = coro
    os.sleep(int(minDelay * 1000))

    var remaining = coro.sleepTime - (epochTime() - coro.lastRun);
    if remaining <= 0:
      remaining = 0
      let res = setjmp(mainCtx)
      if res == 0:
        frame = getFrame()
        if coro.started:            # coroutine resumes
          longjmp(coro.ctx, 1)
        else:
          coro.started = true       # coroutine starts
          var stackEnd = cast[pointer](cast[ByteAddress](coro.stack) + coro.stacksize)
          GC_addStack(coro.stack)
          coroSwitchStack(stackEnd)
          coro.fn()
          coroRestoreStack()
          GC_removeStack(coro.stack)
          var next = node.prev
          coroutines.remove(node)
          dealloc(coro.stack)
          node = next
          setFrame(frame)
      else:
        setFrame(frame)

    elif remaining > 0:
      if minDelay > 0 and remaining > 0:
        minDelay = min(remaining, minDelay)
      else:
        minDelay = remaining

    if node == nil or node.next == nil:
      node = coroutines.head
    else:
      node = node.next

proc alive*(c: proc()): bool =
  ## Returns ``true`` if coroutine has not returned, ``false`` otherwise.
  for coro in items(coroutines):
    if coro.fn == c:
      return true

proc wait*(c: proc(), interval=0.01) =
  ## Returns only after coroutine ``c`` has returned. ``interval`` is time in seconds how often.
  while alive(c):
    suspend interval

when defined(nimCoroutines) and isMainModule:
  var stackCheckValue = 1100220033
  proc c2()

  proc c1() =
    for i in 0 .. 3:
      echo "c1"
      suspend 0.05
    echo "c1 exits"


  proc c2() =
    for i in 0 .. 3:
      echo "c2"
      suspend 0.025
    wait(c1)
    echo "c2 exits"

  start(c1)
  start(c2)
  run()
  echo "done ", stackCheckValue
