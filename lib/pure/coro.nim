#
#
#            Nim's Runtime Library
#        (c) Copyright 2015 Rokas Kupstys
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## Nim coroutines implementation, supports several context switching methods:
## --------  ------------
## ucontext  available on unix and alike (default)
## setjmp    available on unix and alike (x86/64 only)
## fibers    available and required on windows.
## --------  ------------
##
## -d:nimCoroutines               Required to build this module.
## -d:nimCoroutinesUcontext       Use ucontext backend.
## -d:nimCoroutinesSetjmp         Use setjmp backend.
## -d:nimCoroutinesSetjmpBundled  Use bundled setjmp implementation.
##
## Unstable API.

import system/coro_detection

when not nimCoroutines and not defined(nimdoc):
  when defined(noNimCoroutines):
    {.error: "Coroutines can not be used with -d:noNimCoroutines".}
  else:
    {.error: "Coroutines require -d:nimCoroutines".}

import os
import lists
include system/timers

const defaultStackSize = 512 * 1024
const useOrcArc = defined(gcArc) or defined(gcOrc)

when useOrcArc:
  proc nimGC_setStackBottom*(theStackBottom: pointer) = discard

proc GC_addStack(bottom: pointer) {.cdecl, importc.}
proc GC_removeStack(bottom: pointer) {.cdecl, importc.}
proc GC_setActiveStack(bottom: pointer) {.cdecl, importc.}
proc GC_getActiveStack() : pointer {.cdecl, importc.}

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
elif defined(haiku) or defined(openbsd):
  const coroBackend = CORO_BACKEND_SETJMP
  when defined(nimCoroutinesUcontext):
    {.warning: "ucontext coroutine backend is not available on haiku, defaulting to setjmp".}
elif defined(nimCoroutinesSetjmp) or defined(nimCoroutinesSetjmpBundled):
  const coroBackend = CORO_BACKEND_SETJMP
else:
  const coroBackend = CORO_BACKEND_UCONTEXT

when coroBackend == CORO_BACKEND_FIBERS:
  import windows/winlean
  type
    Context = pointer

elif coroBackend == CORO_BACKEND_UCONTEXT:
  type
    stack_t {.importc, header: "<ucontext.h>".} = object
      ss_sp: pointer
      ss_flags: int
      ss_size: int

    ucontext_t {.importc, header: "<ucontext.h>".} = object
      uc_link: ptr ucontext_t
      uc_stack: stack_t

    Context = ucontext_t

  proc getcontext(context: var ucontext_t): int32 {.importc,
      header: "<ucontext.h>".}
  proc setcontext(context: var ucontext_t): int32 {.importc,
      header: "<ucontext.h>".}
  proc swapcontext(fromCtx, toCtx: var ucontext_t): int32 {.importc,
      header: "<ucontext.h>".}
  proc makecontext(context: var ucontext_t, fn: pointer, argc: int32) {.importc,
      header: "<ucontext.h>", varargs.}

elif coroBackend == CORO_BACKEND_SETJMP:
  proc coroExecWithStack*(fn: pointer, stack: pointer) {.noreturn,
      importc: "narch_$1", fastcall.}
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
    proc longjmp(ctx: JmpBuf, ret = 1) {.importc: "narch_$1".}
  else:
    # Use setjmp/longjmp implementation provided by the system.
    type
      JmpBuf {.importc: "jmp_buf", header: "<setjmp.h>".} = object

    proc setjmp(ctx: var JmpBuf): int {.importc, header: "<setjmp.h>".}
    proc longjmp(ctx: JmpBuf, ret = 1) {.importc, header: "<setjmp.h>".}

  type
    Context = JmpBuf

when defined(unix):
  # GLibc fails with "*** longjmp causes uninitialized stack frame ***" because
  # our custom stacks are not initialized to a magic value.
  when defined(osx):
    # workaround: error: The deprecated ucontext routines require _XOPEN_SOURCE to be defined
    const extra = " -D_XOPEN_SOURCE"
  else:
    const extra = ""
  {.passc: "-U_FORTIFY_SOURCE -D_FORTIFY_SOURCE=0" & extra.}

const
  CORO_CREATED = 0
  CORO_EXECUTING = 1
  CORO_FINISHED = 2

type
  Stack {.pure.} = object
    top: pointer    # Top of the stack. Pointer used for deallocating stack if we own it.
    bottom: pointer # Very bottom of the stack, acts as unique stack identifier.
    size: int

  Coroutine {.pure.} = object
    execContext: Context
    fn: proc()
    state: int
    lastRun: Ticks
    sleepTime: float
    stack: Stack
    reference: CoroutineRef

  CoroutinePtr = ptr Coroutine

  CoroutineRef* = ref object
    ## CoroutineRef holds a pointer to actual coroutine object. Public API always returns
    ## CoroutineRef instead of CoroutinePtr in order to allow holding a reference to coroutine
    ## object while it can be safely deallocated by coroutine scheduler loop. In this case
    ## Coroutine.reference.coro is set to nil. Public API checks for it being nil and
    ## gracefully fails if it is nil.
    coro: CoroutinePtr

  CoroutineLoopContext = ref object
    coroutines: DoublyLinkedList[CoroutinePtr]
    current: DoublyLinkedNode[CoroutinePtr]
    loop: Coroutine
    ncbottom: pointer # non coroutine stack botttom

var ctx {.threadvar.}: CoroutineLoopContext

proc getCurrent(): CoroutinePtr =
  ## Returns current executing coroutine object.
  var node = ctx.current
  if node != nil:
    return node.value
  return nil

proc initialize() =
  ## Initializes coroutine state of current thread.
  if ctx == nil:
    ctx = CoroutineLoopContext()
    ctx.coroutines = initDoublyLinkedList[CoroutinePtr]()
    ctx.loop = Coroutine()
    ctx.loop.state = CORO_EXECUTING
    when not useOrcArc:
      ctx.ncbottom = GC_getActiveStack()
    when coroBackend == CORO_BACKEND_FIBERS:
      ctx.loop.execContext = ConvertThreadToFiberEx(nil, FIBER_FLAG_FLOAT_SWITCH)

proc runCurrentTask()

proc switchTo(current, to: CoroutinePtr) =
  ## Switches execution from `current` into `to` context.
  to.lastRun = getTicks()
  # Update position of current stack so gc invoked from another stack knows how much to scan.
  when not useOrcArc:
    GC_setActiveStack(current.stack.bottom)
  nimGC_setStackBottom(current.stack.bottom)
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
          #doAssert false
    else:
      {.error: "Invalid coroutine backend set.".}
  # Execution was just resumed. Restore frame information and set active stack.
  setFrameState(frame)
  when not useOrcArc:
    GC_setActiveStack(current.stack.bottom)
  nimGC_setStackBottom(ctx.ncbottom)

proc suspend*(sleepTime: float = 0) =
  ## Stops coroutine execution and resumes no sooner than after `sleeptime` seconds.
  ## Until then other coroutines are executed.
  var current = getCurrent()
  current.sleepTime = sleepTime
  nimGC_setStackBottom(ctx.ncbottom)
  switchTo(current, addr(ctx.loop))

proc runCurrentTask() =
  ## Starts execution of current coroutine and updates it's state through coroutine's life.
  var sp {.volatile.}: pointer
  sp = addr(sp)
  block:
    var current = getCurrent()
    current.stack.bottom = sp
    nimGC_setStackBottom(current.stack.bottom)
    # Execution of new fiber just started. Since it was entered not through `switchTo` we
    # have to set active stack here as well. GC_removeStack() has to be called in main loop
    # because we still need stack available in final suspend(0) call from which we will not
    # return.
    when not useOrcArc:
      GC_addStack(sp)
      # Activate current stack because we are executing in a new coroutine.
      GC_setActiveStack(sp)
    current.state = CORO_EXECUTING
    try:
      current.fn() # Start coroutine execution
    except:
      echo "Unhandled exception in coroutine."
      writeStackTrace()
    current.state = CORO_FINISHED
  nimGC_setStackBottom(ctx.ncbottom)
  suspend(0) # Exit coroutine without returning from coroExecWithStack()
  doAssert false

proc start*(c: proc(), stacksize: int = defaultStackSize): CoroutineRef {.discardable.} =
  ## Schedule coroutine for execution. It does not run immediately.
  if ctx == nil:
    initialize()

  var coro: CoroutinePtr
  when coroBackend == CORO_BACKEND_FIBERS:
    coro = cast[CoroutinePtr](alloc0(sizeof(Coroutine)))
    coro.execContext = CreateFiberEx(stacksize, stacksize,
      FIBER_FLAG_FLOAT_SWITCH,
      (proc(p: pointer) {.stdcall.} = runCurrentTask()), nil)
  else:
    coro = cast[CoroutinePtr](alloc0(sizeof(Coroutine) + stacksize))
    coro.stack.top = cast[pointer](cast[ByteAddress](coro) + sizeof(Coroutine))
    coro.stack.bottom = cast[pointer](cast[ByteAddress](coro.stack.top) + stacksize)
    when coroBackend == CORO_BACKEND_UCONTEXT:
      discard getcontext(coro.execContext)
      coro.execContext.uc_stack.ss_sp = coro.stack.top
      coro.execContext.uc_stack.ss_size = stacksize
      coro.execContext.uc_link = addr(ctx.loop.execContext)
      makecontext(coro.execContext, runCurrentTask, 0)
  coro.fn = c
  coro.stack.size = stacksize
  coro.state = CORO_CREATED
  coro.reference = CoroutineRef(coro: coro)
  ctx.coroutines.append(coro)
  return coro.reference

proc run*() =
  ## Starts main coroutine scheduler loop which exits when all coroutines exit.
  ## Calling this proc starts execution of first coroutine.
  initialize()
  ctx.current = ctx.coroutines.head
  var minDelay: float = 0
  while ctx.current != nil:
    var current = getCurrent()

    var remaining = current.sleepTime - (float(getTicks() - current.lastRun) / 1_000_000_000)
    if remaining <= 0:
      # Save main loop context. Suspending coroutine will resume after this statement with
      switchTo(addr(ctx.loop), current)
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
      current.reference.coro = nil
      ctx.coroutines.remove(ctx.current)
      when not useOrcArc:
        GC_removeStack(current.stack.bottom)
      when coroBackend == CORO_BACKEND_FIBERS:
        DeleteFiber(current.execContext)
      else:
        dealloc(current.stack.top)
      dealloc(current)
      ctx.current = next
    elif ctx.current == nil or ctx.current.next == nil:
      ctx.current = ctx.coroutines.head
      os.sleep(int(minDelay * 1000))
    else:
      ctx.current = ctx.current.next

proc alive*(c: CoroutineRef): bool = c.coro != nil and c.coro.state != CORO_FINISHED
  ## Returns `true` if coroutine has not returned, `false` otherwise.

proc wait*(c: CoroutineRef, interval = 0.01) =
  ## Returns only after coroutine `c` has returned. `interval` is time in seconds how often.
  while alive(c):
    suspend(interval)
