#
#
#            Nim's Runtime Library
#        (c) Copyright 2012 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## Nim的线程支持模块.
##
## **注意**: 这是system模块的一部分. 不需要直接import.
## 需要在编译的时候在命令行使用 ``--threads:on``
## 开关来开启线程的支持
##
## Nim语言线程的内存模型与常见的编程语言（C, Pascal）不同:
## 每一个线程都拥有自己（垃圾回收）的堆，共享内存是受限制的。
## 这个能避免竞争条件，并且能提高效率。
## 详情可查看 `手册中关于这种内存模型的描述 <manual.html#threads>`_.
##
## 示例
## ========
##
## .. code-block:: Nim
##
##  import locks
##
##  var
##    thr: array[0..4, Thread[tuple[a,b: int]]]
##    L: Lock
##
##  proc threadFunc(interval: tuple[a,b: int]) {.thread.} =
##    for i in interval.a..interval.b:
##      acquire(L) # lock stdout
##      echo i
##      release(L)
##
##  initLock(L)
##
##  for i in 0..high(thr):
##    createThread(thr[i], threadFunc, (i*10, i*10+5))
##  joinThreads(thr)

when not declared(ThisIsSystem):
  {.error: "You must not import this module explicitly".}

const
  StackGuardSize = 4096
  ThreadStackMask =
    when defined(genode):
      1024*64*sizeof(int)-1
    else:
      1024*256*sizeof(int)-1
  ThreadStackSize = ThreadStackMask+1 - StackGuardSize

#const globalsSlot = ThreadVarSlot(0)
#sysAssert checkSlot.int == globalsSlot.int

# create for the main thread. Note: do not insert this data into the list
# of all threads; it's not to be stopped etc.
when not defined(useNimRtl):
  #when not defined(createNimRtl): initStackBottom()
  when declared(initGC):
    initGC()
    when not emulatedThreadVars:
      type ThreadType {.pure.} = enum
        None = 0,
        NimThread = 1,
        ForeignThread = 2
      var
        threadType {.rtlThreadVar.}: ThreadType

      threadType = ThreadType.NimThread

# We jump through some hops here to ensure that Nim thread procs can have
# the Nim calling convention. This is needed because thread procs are
# ``stdcall`` on Windows and ``noconv`` on UNIX. Alternative would be to just
# use ``stdcall`` since it is mapped to ``noconv`` on UNIX anyway.

type
  Thread* {.pure, final.}[TArg] = object
    core: PGcThread
    sys: SysThread
    when TArg is void:
      dataFn: proc () {.nimcall, gcsafe.}
    else:
      dataFn: proc (m: TArg) {.nimcall, gcsafe.}
      data: TArg

var
  threadDestructionHandlers {.rtlThreadVar.}: seq[proc () {.closure, gcsafe.}]

proc onThreadDestruction*(handler: proc () {.closure, gcsafe.}) =
  ## 注册一个 *thread local* 的处理proc，在线程销毁之前调用。
  ##
  ## 当一个 ``.thread`` proc正常退出或者抛出异常，这个线程会销毁，
  ## 注意：线程抛出的异常如果未处理，将会导致整个进程退出。
  when not defined(nimNoNilSeqs):
    if threadDestructionHandlers.isNil:
      threadDestructionHandlers = @[]
  threadDestructionHandlers.add handler

template afterThreadRuns() =
  for i in countdown(threadDestructionHandlers.len-1, 0):
    threadDestructionHandlers[i]()

when not defined(boehmgc) and not hasSharedHeap and not defined(gogc) and not defined(gcRegions):
  proc deallocOsPages() {.rtl.}

when defined(boehmgc):
  type GCStackBaseProc = proc(sb: pointer, t: pointer) {.noconv.}
  proc boehmGC_call_with_stack_base(sbp: GCStackBaseProc, p: pointer)
    {.importc: "GC_call_with_stack_base", boehmGC.}
  proc boehmGC_register_my_thread(sb: pointer)
    {.importc: "GC_register_my_thread", boehmGC.}
  proc boehmGC_unregister_my_thread()
    {.importc: "GC_unregister_my_thread", boehmGC.}

  proc threadProcWrapDispatch[TArg](sb: pointer, thrd: pointer) {.noconv.} =
    boehmGC_register_my_thread(sb)
    try:
      let thrd = cast[ptr Thread[TArg]](thrd)
      when TArg is void:
        thrd.dataFn()
      else:
        thrd.dataFn(thrd.data)
    finally:
      afterThreadRuns()
    boehmGC_unregister_my_thread()
else:
  proc threadProcWrapDispatch[TArg](thrd: ptr Thread[TArg]) =
    try:
      when TArg is void:
        thrd.dataFn()
      else:
        when defined(nimV2):
          thrd.dataFn(thrd.data)
        else:
          var x: TArg
          deepCopy(x, thrd.data)
          thrd.dataFn(x)
    finally:
      afterThreadRuns()

proc threadProcWrapStackFrame[TArg](thrd: ptr Thread[TArg]) =
  when defined(boehmgc):
    boehmGC_call_with_stack_base(threadProcWrapDispatch[TArg], thrd)
  elif not defined(nogc) and not defined(gogc) and not defined(gcRegions) and not defined(gcDestructors):
    var p {.volatile.}: proc(a: ptr Thread[TArg]) {.nimcall, gcsafe.} =
      threadProcWrapDispatch[TArg]
    # init the GC for refc/markandsweep
    nimGC_setStackBottom(addr(p))
    initGC()
    when declared(threadType):
      threadType = ThreadType.NimThread
    p(thrd)
    when declared(deallocOsPages): deallocOsPages()
  else:
    threadProcWrapDispatch(thrd)

template threadProcWrapperBody(closure: untyped): untyped =
  var thrd = cast[ptr Thread[TArg]](closure)
  var core = thrd.core
  when declared(globalsSlot): threadVarSetValue(globalsSlot, thrd.core)
  threadProcWrapStackFrame(thrd)
  # Since an unhandled exception terminates the whole process (!), there is
  # no need for a ``try finally`` here, nor would it be correct: The current
  # exception is tried to be re-raised by the code-gen after the ``finally``!
  # However this is doomed to fail, because we already unmapped every heap
  # page!

  # mark as not running anymore:
  thrd.core = nil
  thrd.dataFn = nil
  deallocShared(cast[pointer](core))

{.push stack_trace:off.}
when defined(windows):
  proc threadProcWrapper[TArg](closure: pointer): int32 {.stdcall.} =
    threadProcWrapperBody(closure)
    # implicitly return 0
elif defined(genode):
   proc threadProcWrapper[TArg](closure: pointer) {.noconv.} =
    threadProcWrapperBody(closure)
else:
  proc threadProcWrapper[TArg](closure: pointer): pointer {.noconv.} =
    threadProcWrapperBody(closure)
{.pop.}

proc running*[TArg](t: Thread[TArg]): bool {.inline.} =
  ## 如果线程 `t` 正在运行，返回true。
  result = t.dataFn != nil

proc handle*[TArg](t: Thread[TArg]): SysThread {.inline.} =
  ## 返回线程 `t` 的句柄。
  result = t.sys

when hostOS == "windows":
  const MAXIMUM_WAIT_OBJECTS = 64

  proc joinThread*[TArg](t: Thread[TArg]) {.inline.} =
    ## 等待 `t` 中的每一个线程运行完成。
    discard waitForSingleObject(t.sys, -1'i32)

  proc joinThreads*[TArg](t: varargs[Thread[TArg]]) =
    ## 等待 `t` 中的每一个线程运行完成。
    var a: array[MAXIMUM_WAIT_OBJECTS, SysThread]
    var k = 0
    while k < len(t):
      var count = min(len(t) - k, MAXIMUM_WAIT_OBJECTS)
      for i in 0..(count - 1): a[i] = t[i + k].sys
      discard waitForMultipleObjects(int32(count),
                                     cast[ptr SysThread](addr(a)), 1, -1)
      inc(k, MAXIMUM_WAIT_OBJECTS)

elif defined(genode):
  proc joinThread*[TArg](t: Thread[TArg]) {.importcpp.}
    ## 等待 `t` 中的每一个线程运行完成。

  proc joinThreads*[TArg](t: varargs[Thread[TArg]]) =
    ## 等待 `t` 中的每一个线程运行完成。
    for i in 0..t.high: joinThread(t[i])

else:
  proc joinThread*[TArg](t: Thread[TArg]) {.inline.} =
    ## 等待 `t` 中的每一个线程运行完成。
    discard pthread_join(t.sys, nil)

  proc joinThreads*[TArg](t: varargs[Thread[TArg]]) =
    ## 等待 `t` 中的每一个线程运行完成。
    for i in 0..t.high: joinThread(t[i])

when false:
  # XXX a thread should really release its heap here somehow:
  proc destroyThread*[TArg](t: var Thread[TArg]) =
    ## 强制终止线程 `t` 。
    ## 如果你并不拥有 `t` 的全部控制权和他的资源，此操作存在潜在的危险。
    when hostOS == "windows":
      discard TerminateThread(t.sys, 1'i32)
    else:
      discard pthread_cancel(t.sys)
    when declared(registerThread): unregisterThread(addr(t))
    t.dataFn = nil
    ## 如果线程 `t` 已经退出， `t.core` 将会是 `null`。
    if not isNil(t.core):
      deallocShared(t.core)
      t.core = nil

when hostOS == "windows":
  proc createThread*[TArg](t: var Thread[TArg],
                           tp: proc (arg: TArg) {.thread, nimcall.},
                           param: TArg) =
    ## 创建一个新的线程 `t` 并且开始执行。
    ##
    ## 线程的入口函数是 `tp` 。 `param` 是传送给线程函数的参数 `tp` 。
    ## 如不需要传递任何数据给线程， `TArg` 可以传 ``void`` 
    t.core = cast[PGcThread](allocShared0(sizeof(GcThread)))

    when TArg isnot void: t.data = param
    t.dataFn = tp
    when hasSharedHeap: t.core.stackSize = ThreadStackSize
    var dummyThreadId: int32
    t.sys = createThread(nil, ThreadStackSize, threadProcWrapper[TArg],
                         addr(t), 0'i32, dummyThreadId)
    if t.sys <= 0:
      raise newException(ResourceExhaustedError, "cannot create thread")

  proc pinToCpu*[Arg](t: var Thread[Arg]; cpu: Natural) =
    ## 绑定一个线程到一个 `CPU`:idx: 。
    ##
    ## 换句话说：设置一个线程的 `亲和性`:idx: 。
    ## 如果你不清楚这个proc的功能，最好不要使用。
    setThreadAffinityMask(t.sys, uint(1 shl cpu))

elif defined(genode):
  var affinityOffset: cuint = 1
    ## 下一个线程的CPU亲核性偏移量，安全回滚。

  proc createThread*[TArg](t: var Thread[TArg],
                           tp: proc (arg: TArg) {.thread, nimcall.},
                           param: TArg) =
    t.core = cast[PGcThread](allocShared0(sizeof(GcThread)))

    when TArg isnot void: t.data = param
    t.dataFn = tp
    when hasSharedHeap: t.stackSize = ThreadStackSize
    t.sys.initThread(
      runtimeEnv,
      ThreadStackSize.culonglong,
      threadProcWrapper[TArg], addr(t), affinityOffset)
    inc affinityOffset

  proc pinToCpu*[Arg](t: var Thread[Arg]; cpu: Natural) =
    {.hint: "cannot change Genode thread CPU affinity after initialization".}
    discard

else:
  proc createThread*[TArg](t: var Thread[TArg],
                           tp: proc (arg: TArg) {.thread, nimcall.},
                           param: TArg) =
    ## 创建一个新的线程 `t` 并且开始执行。
    ##
    ## 线程的入口函数是 `tp` 。 `param` 是传送给线程函数的参数 `tp` 。
    ## 如不需要传递任何数据给线程， `TArg` 可以传 ``void`` 
    t.core = cast[PGcThread](allocShared0(sizeof(GcThread)))

    when TArg isnot void: t.data = param
    t.dataFn = tp
    when hasSharedHeap: t.core.stackSize = ThreadStackSize
    var a {.noinit.}: Pthread_attr
    pthread_attr_init(a)
    pthread_attr_setstacksize(a, ThreadStackSize)
    if pthread_create(t.sys, a, threadProcWrapper[TArg], addr(t)) != 0:
      raise newException(ResourceExhaustedError, "cannot create thread")

  proc pinToCpu*[Arg](t: var Thread[Arg]; cpu: Natural) =
    ## 绑定一个线程到一个 `CPU`:idx: 。
    ##
    ## 换句话说：设置一个线程的 `亲和性`:idx: 。
    ## 如果你不清楚这个proc的功能，最好不要使用。
    when not defined(macosx):
      var s {.noinit.}: CpuSet
      cpusetZero(s)
      cpusetIncl(cpu.cint, s)
      setAffinity(t.sys, sizeof(s), s)

proc createThread*(t: var Thread[void], tp: proc () {.thread, nimcall.}) =
  createThread[void](t, tp)

# we need to cache current threadId to not perform syscall all the time
var threadId {.threadvar.}: int

when defined(windows):
  proc getThreadId*(): int =
    ## 获取当前线程ID。
    if threadId == 0:
      threadId = int(getCurrentThreadId())
    result = threadId

elif defined(linux):
  proc syscall(arg: clong): clong {.varargs, importc: "syscall", header: "<unistd.h>".}
  when defined(amd64):
    const NR_gettid = clong(186)
  else:
    var NR_gettid {.importc: "__NR_gettid", header: "<sys/syscall.h>".}: clong

  proc getThreadId*(): int =
    ## 获取当前线程ID。
    if threadId == 0:
      threadId = int(syscall(NR_gettid))
    result = threadId

elif defined(dragonfly):
  proc lwp_gettid(): int32 {.importc, header: "unistd.h".}

  proc getThreadId*(): int =
    ## 获取当前线程ID。
    if threadId == 0:
      threadId = int(lwp_gettid())
    result = threadId

elif defined(openbsd):
  proc getthrid(): int32 {.importc: "getthrid", header: "<unistd.h>".}

  proc getThreadId*(): int =
    ## 获取当前线程ID。
    if threadId == 0:
      threadId = int(getthrid())
    result = threadId

elif defined(netbsd):
  proc lwp_self(): int32 {.importc: "_lwp_self", header: "<lwp.h>".}

  proc getThreadId*(): int =
    ## 获取当前线程ID。
    if threadId == 0:
      threadId = int(lwp_self())
    result = threadId

elif defined(freebsd):
  proc syscall(arg: cint, arg0: ptr cint): cint {.varargs, importc: "syscall", header: "<unistd.h>".}
  var SYS_thr_self {.importc:"SYS_thr_self", header:"<sys/syscall.h>"}: cint

  proc getThreadId*(): int =
    ## 获取当前线程ID。
    var tid = 0.cint
    if threadId == 0:
      discard syscall(SYS_thr_self, addr tid)
      threadId = tid
    result = threadId

elif defined(macosx):
  proc syscall(arg: cint): cint {.varargs, importc: "syscall", header: "<unistd.h>".}
  var SYS_thread_selfid {.importc:"SYS_thread_selfid", header:"<sys/syscall.h>".}: cint

  proc getThreadId*(): int =
    ## 获取当前线程ID。
    if threadId == 0:
      threadId = int(syscall(SYS_thread_selfid))
    result = threadId

elif defined(solaris):
  type thread_t {.importc: "thread_t", header: "<thread.h>".} = distinct int
  proc thr_self(): thread_t {.importc, header: "<thread.h>".}

  proc getThreadId*(): int =
    ## 获取当前线程ID。
    if threadId == 0:
      threadId = int(thr_self())
    result = threadId

elif defined(haiku):
  type thr_id {.importc: "thread_id", header: "<OS.h>".} = distinct int32
  proc find_thread(name: cstring): thr_id {.importc, header: "<OS.h>".}

  proc getThreadId*(): int =
    ## 获取当前线程ID。
    if threadId == 0:
      threadId = int(find_thread(nil))
    result = threadId
