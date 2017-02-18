#
#
#            Nim's Runtime Library
#        (c) Copyright 2015 Rokas Kupstys
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#
## Nim coroutines implementation supports several context switching methods:
## ucontext: available on unix and alike (default)
## setjmp:   available on unix and alike (x86/64 only)
## Fibers:   available and required on windows.
##
## -d:nimCoroutines              Required to build this module.
## -d:nimCoroutinesUcontext      Use ucontext backend.
## -d:nimCoroutinesSetjmp        Use setjmp backend.
## -d:nimCoroutinesSetjmpBundled Use bundled setjmp implementation.

when not nimCoroutines and not defined(nimdoc):
  when defined(noNimCoroutines):
    {.error: "Coroutines can not be used with -d:noNimCoroutines"}
  else:
    {.error: "Coroutines require -d:nimCoroutines".}

import os
import macros
import lists
include system/timers

const defaultStackSize = 512 * 1024

proc GC_addStack(bottom: pointer) {.cdecl, importc.}
proc GC_removeStack(bottom: pointer) {.cdecl, importc.}
proc GC_setActiveStack(bottom: pointer) {.cdecl, importc.}

const
  CORO_BACKEND_UCONTEXT = 0
  CORO_BACKEND_SETJMP = 1
  CORO_BACKEND_FIBERS = 2

when defined(windows):
  const coroBackend = CORO_BACKEND_FIBERS
  when defined(nimCoroutinesUcontext):
    {.warning: "ucontext coroutine backend is not available on windows, defaulting to fibers.".}
  when defined(nimCoroutinesSetjmp):
    {.warning: "setjmp coroutine backend is not available on windows, defaulting to fibers.".}
elif defined(nimCoroutinesSetjmp) or defined(nimCoroutinesSetjmpBundled):
  const coroBackend = CORO_BACKEND_SETJMP
else:
  const coroBackend = CORO_BACKEND_UCONTEXT

when coroBackend == CORO_BACKEND_FIBERS:
  import windows.winlean
  type
    Context = pointer

elif coroBackend == CORO_BACKEND_UCONTEXT:
  type
    stack_t {.importc, header: "<sys/ucontext.h>".} = object
      ss_sp: pointer
      ss_flags: int
      ss_size: int

    ucontext_t {.importc, header: "<sys/ucontext.h>".} = object
      uc_link: ptr ucontext_t
      uc_stack: stack_t

    Context = ucontext_t

  proc getcontext(context: var ucontext_t): int32 {.importc, header: "<sys/ucontext.h>".}
  proc setcontext(context: var ucontext_t): int32 {.importc, header: "<sys/ucontext.h>".}
  proc swapcontext(fromCtx, toCtx: var ucontext_t): int32 {.importc, header: "<sys/ucontext.h>".}
  proc makecontext(context: var ucontext_t, fn: pointer, argc: int32) {.importc, header: "<sys/ucontext.h>", varargs.}

elif coroBackend == CORO_BACKEND_SETJMP:
  proc coroExecWithStack*(fn: pointer, stack: pointer) {.noreturn, importc: "narch_$1", fastcall.}
  when defined(amd64):
    {.compile: "../arch/x86/amd64.S".}
  elif defined(i386):
    {.compile: "../arch/x86/i386.S".}
  else:
    # coroExecWithStack is defined in assembly. To support other platforms
    # please provide implementation of this procedure.
    {.error: "Unsupported architecture.".}

  when defined(nimCoroutinesSetjmpBundled):
    # Use setjmp/longjmp implementation shipped with compiler.
    when defined(amd64):
      type
        JmpBuf = array[0x50 + 0x10, uint8]
    elif defined(i386):
      type
        JmpBuf = array[0x1C, uint8]
    else:
      # Bundled setjmp/longjmp are defined in assembly. To support other
      # platforms please provide implementations of these procedures.
      {.error: "Unsupported architecture.".}

    proc setjmp(ctx: var JmpBuf): int {.importc: "narch_$1".}
    proc longjmp(ctx: JmpBuf, ret=1) {.importc: "narch_$1".}
  else:
    # Use setjmp/longjmp implementation provided by the system.
    type
      JmpBuf {.importc: "jmp_buf", header: "<setjmp.h>".} = object
    
    proc setjmp(ctx: var JmpBuf): int {.importc, header: "<setjmp.h>".}
    proc longjmp(ctx: JmpBuf, ret=1) {.importc, header: "<setjmp.h>".}

  type
    Context = JmpBuf

when defined(unix):
  # GLibc fails with "*** longjmp causes uninitialized stack frame ***" because
  # our custom stacks are not initialized to a magic value.
  {.passC: "-U_FORTIFY_SOURCE -D_FORTIFY_SOURCE=0"}

const
  CORO_CREATED = 0
  CORO_EXECUTING = 1
  CORO_FINISHED = 2

type
  Stack = object
    top: pointer      # Top of the stack. Pointer used for deallocating stack if we own it.
    bottom: pointer   # Very bottom of the stack, acts as unique stack identifier.
    size: int

  Coroutine = ref object
    execContext: Context
    fn: proc()
    state: int
    lastRun: Ticks
    sleepTime: float
    stack: Stack

  CoroutineLoopContext = ref object
    coroutines: DoublyLinkedList[Coroutine]
    current: DoublyLinkedNode[Coroutine]
    loop: Coroutine

var ctx {.threadvar.}: CoroutineLoopContext

proc getCurrent(): Coroutine =
  ## Returns current executing coroutine object.
  var node = ctx.current
  if node != nil:
    return node.value
  return nil

proc initialize() =
  ## Initializes coroutine state of current thread.
  if ctx == nil:
    ctx = CoroutineLoopContext()
    ctx.coroutines = initDoublyLinkedList[Coroutine]()
    ctx.loop = Coroutine()
    ctx.loop.state = CORO_EXECUTING
    when coroBackend == CORO_BACKEND_FIBERS:
      ctx.loop.execContext = ConvertThreadToFiberEx(nil, FIBER_FLAG_FLOAT_SWITCH)

proc runCurrentTask()

proc switchTo(current, to: Coroutine) =
  ## Switches execution from `current` into `to` context.
  to.lastRun = getTicks()
  # Update position of current stack so gc invoked from another stack knows how much to scan.
  GC_setActiveStack(current.stack.bottom)
  var frame = getFrameState()
  block:
    # Execution will switch to another fiber now. We do not need to update current stack
    when coroBackend == CORO_BACKEND_FIBERS:
      SwitchToFiber(to.execContext)
    elif coroBackend == CORO_BACKEND_UCONTEXT:
      discard swapcontext(current.execContext, to.execContext)
    elif coroBackend == CORO_BACKEND_SETJMP:
      var res = setjmp(current.execContext)
      if res == 0:
        if to.state == CORO_EXECUTING:
          # Coroutine is resumed.
          longjmp(to.execContext, 1)
        elif to.state == CORO_CREATED:
          # Coroutine is started.
          coroExecWithStack(runCurrentTask, to.stack.bottom)
          doAssert false
    else:
      {.error: "Invalid coroutine backend set.".}
  # Execution was just resumed. Restore frame information and set active stack.
  setFrameState(frame)
  GC_setActiveStack(current.stack.bottom)

proc suspend*(sleepTime: float=0) =
  ## Stops coroutine execution and resumes no sooner than after ``sleeptime`` seconds.
  ## Until then other coroutines are executed.
  var current = getCurrent()
  current.sleepTime = sleepTime
  switchTo(current, ctx.loop)

proc runCurrentTask() =
  ## Starts execution of current coroutine and updates it's state through coroutine's life.
  var sp {.volatile.}: pointer
  sp = addr(sp)
  block:
    var current = getCurrent()
    current.stack.bottom = sp
    # Execution of new fiber just started. Since it was entered not through `switchTo` we
    # have to set active stack here as well. GC_removeStack() has to be called in main loop
    # because we still need stack available in final suspend(0) call from which we will not
    # return.
    GC_addStack(sp)
    # Activate current stack because we are executing in a new coroutine.
    GC_setActiveStack(sp)
    current.state = CORO_EXECUTING
    try:
      current.fn()                    # Start coroutine execution
    except:
      echo "Unhandled exception in coroutine."
      writeStackTrace()
    current.state = CORO_FINISHED
  suspend(0)                      # Exit coroutine without returning from coroExecWithStack()
  doAssert false

proc start*(c: proc(), stacksize: int=defaultStackSize) =
  ## Schedule coroutine for execution. It does not run immediately.
  if ctx == nil:
    initialize()
  
  var coro = Coroutine()
  coro.fn = c
  when coroBackend == CORO_BACKEND_FIBERS:
    coro.execContext = CreateFiberEx(stacksize, stacksize,
      FIBER_FLAG_FLOAT_SWITCH, (proc(p: pointer): void {.stdcall.} = runCurrentTask()), nil)
    coro.stack.size = stacksize
  else:
    var stack: pointer
    while stack == nil:
      stack = alloc0(stacksize)
    coro.stack.top = stack
    when coroBackend == CORO_BACKEND_UCONTEXT:
      discard getcontext(coro.execContext)
      coro.execContext.uc_stack.ss_sp = cast[pointer](cast[ByteAddress](stack) + stacksize)
      coro.execContext.uc_stack.ss_size = coro.stack.size
      coro.execContext.uc_link = addr ctx.loop.execContext
      makecontext(coro.execContext, runCurrentTask, 0)
  coro.stack.size = stacksize
  coro.state = CORO_CREATED
  ctx.coroutines.append(coro)

proc run*() =
  initialize()
  ## Starts main coroutine scheduler loop which exits when all coroutines exit.
  ## Calling this proc starts execution of first coroutine.
  ctx.current = ctx.coroutines.head
  var minDelay: float = 0
  while ctx.current != nil:
    var current = getCurrent()

    var remaining = current.sleepTime - (float(getTicks() - current.lastRun) / 1_000_000_000)
    if remaining <= 0:
      # Save main loop context. Suspending coroutine will resume after this statement with
      switchTo(ctx.loop, current)
    else:
      if minDelay > 0 and remaining > 0:
        minDelay = min(remaining, minDelay)
      else:
        minDelay = remaining

    if current.state == CORO_FINISHED:
      var next = ctx.current.prev
      if next == nil:
        # If first coroutine ends then `prev` is nil even if more coroutines 
        # are to be scheduled.
        next = ctx.current.next
      ctx.coroutines.remove(ctx.current)
      GC_removeStack(current.stack.bottom)
      when coroBackend == CORO_BACKEND_FIBERS:
        DeleteFiber(current.execContext)
      else:
        dealloc(current.stack.top)
      current.stack.top = nil
      current.stack.bottom = nil
      ctx.current = next
    elif ctx.current == nil or ctx.current.next == nil:
      ctx.current = ctx.coroutines.head
      os.sleep(int(minDelay * 1000))
    else:
      ctx.current = ctx.current.next

proc alive*(c: proc()): bool =
  ## Returns ``true`` if coroutine has not returned, ``false`` otherwise.
  for coro in items(ctx.coroutines):
    if coro.fn == c:
      return coro.state != CORO_FINISHED

proc wait*(c: proc(), interval=0.01) =
  ## Returns only after coroutine ``c`` has returned. ``interval`` is time in seconds how often.
  while alive(c):
    suspend(interval)

when isMainModule:
  var
    stackCheckValue = 1100220033
    first: float64 = 0
    second: float64 = 1
    steps = 10
    i: int
    order = newSeq[int](10)

  proc testFibonacci(id: int, sleep: float32) =
    var sleepTime: float
    while steps > 0:
      echo id, " executing, slept for ", sleepTime
      order[i] = id
      i += 1
      steps -= 1
      swap first, second
      second += first
      var sleepStart = getTicks()
      suspend(sleep)
      sleepTime = float(getTicks() - sleepStart) / 1_000_000_000

  start(proc() = testFibonacci(1, 0.01))
  start(proc() = testFibonacci(2, 0.021))
  run()
  doAssert stackCheckValue == 1100220033
  doAssert first == 55.0
  doAssert order == @[1, 2, 1, 1, 2, 1, 1, 2, 1, 1]

  order = newSeq[int](10)
  i = 0

  proc testExceptions(id: int, sleep: float) =
    try:
      order[i] = id; i += 1
      suspend(sleep)
      order[i] = id; i += 1
      raise (ref ValueError)()
    except:
      order[i] = id; i += 1
      suspend(sleep)
      order[i] = id; i += 1
    suspend(sleep)
    order[i] = id; i += 1

  start(proc() = testExceptions(1, 0.01))
  start(proc() = testExceptions(2, 0.021))
  run()
  doAssert order == @[1, 2, 1, 1, 1, 2, 2, 1, 2, 2]
  doAssert stackCheckValue == 1100220033

  order = newSeq[int](10)
  i = 0

  iterator suspendingIterator(sleep: float): int =
    for i in 0..4:
      yield i
      suspend(sleep)

  proc terstIterators(id: int, sleep: float) =
    for n in suspendingIterator(sleep):
      order[i] = n
      i += 1

  start(proc() = terstIterators(1, 0.01))
  start(proc() = terstIterators(2, 0.021))
  run()
  doAssert order == @[0, 0, 1, 2, 1, 3, 4, 2, 3, 4]
  doAssert stackCheckValue == 1100220033

  type Foo = ref object
    number: int

  GC_fullCollect()
  var occupiedMemory = getOccupiedMem()

  i = 0
  var objects = newSeq[Foo](100)
  proc terstGc(id: int, sleep: float) =
    for n in 0..<50:
      objects[i] = Foo(number: n)
      i += 1

  start(proc() = terstIterators(1, 0.01))
  start(proc() = terstIterators(2, 0.021))
  run()

  doAssert occupiedMemory < getOccupiedMem()
  objects = nil
  GC_fullCollect()
  doAssert occupiedMemory >= getOccupiedMem()
