#
#
#            Nim's Runtime Library
#        (c) Copyright 2015 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

import macros, cpuinfo

when not compileOption("threads"):
  {.error: "ThreadPool requires --threads:on compiler option".}

type
  ThreadPool* = ref object
    chanTo: ChannelTo # Tasks are added to this channel
    chanFrom: ChannelFrom # Results are read from this channel
    threads: seq[ThreadType]
    maxThreads: int

  FlowVarBase = ref object {.inheritable, pure.}
    tp: ThreadPool
    idx: int # -1 if was never awaited

  FlowVar*[T] = ref object of FlowVarBase
    when T isnot void:
      v: T

  MsgTo = ref object {.inheritable, pure.}
    action: proc(m: MsgTo, chanFrom: ChannelFromPtr) {.nimcall.}
    flowVar: pointer
    complete: bool

  MsgFrom = ref object {.inheritable, pure.}
    writeResult: proc(m: MsgFrom) {.nimcall.}
    flowVar: pointer

  ConcreteMsgFrom[T] = ref object of MsgFrom
    when T isnot void:
      v: T

  ChannelTo = Channel[MsgTo]
  ChannelFrom = Channel[MsgFrom]

  ChannelToPtr = ptr ChannelTo
  ChannelFromPtr = ptr ChannelFrom

  ThreadProcArgs = object
    chanTo: ChannelToPtr
    chanFrom: ChannelFromPtr

  ThreadType = Thread[ThreadProcArgs]

template isReadyAux(v: FlowVarBase): bool = v.tp.isNil

proc cleanupAux(tp: ThreadPool) =
  var msg: MsgTo
  msg.new()
  msg.complete = true
  for i in 0 ..< tp.threads.len:
    tp.chanTo.send(msg)
  joinThreads(tp.threads)

proc sync*(tp: ThreadPool) =
  if not tp.threads.isNil:
    tp.cleanupAux()
    tp.threads.setLen(0)

proc finalize(tp: ThreadPool) =
  if not tp.threads.isNil:
    tp.cleanupAux()
    GC_unref(tp.threads)
  tp.chanTo.close()
  tp.chanFrom.close()

proc threadProc(args: ThreadProcArgs) {.thread.} =
  while true:
    let m = args.chanTo[].recv()
    if m.complete:
      break
    m.action(m, args.chanFrom)
  deallocHeap(true, false)

proc startThreads(tp: ThreadPool) =
  assert(tp.threads.len == 0)
  if tp.threads.isNil:
    tp.threads = newSeq[ThreadType](tp.maxThreads)
    GC_ref(tp.threads)
  else:
    tp.threads.setLen(tp.maxThreads)

  var args = ThreadProcArgs(chanTo: addr tp.chanTo, chanFrom: addr tp.chanFrom)
  for i in 0 ..< tp.maxThreads:
    createThread(tp.threads[i], threadProc, args)

proc newThreadPool*(maxThreads: int, maxMessages: int): ThreadPool =
  result.new(finalize)
  result.maxThreads = maxThreads
  result.chanTo.open()#maxMessages)
  result.chanFrom.open()

proc newThreadPool*(maxThreads: int): ThreadPool {.inline.} =
  newThreadPool(maxThreads, maxThreads * 4)

proc newThreadPool*(): ThreadPool {.inline.} =
  newThreadPool(countProcessors())

proc newSerialThreadPool*(): ThreadPool {.inline.} =
  newThreadPool(1)

proc dispatchMessage(tp: ThreadPool, m: MsgTo) =
  if tp.threads.len == 0:
    tp.startThreads()
  tp.chanTo.send(m)

proc tryDispatchMessage(tp: ThreadPool, m: MsgTo): bool =
  if tp.threads.len == 0:
    tp.startThreads()
  tp.chanTo.trySend(m)

proc dispatchMessageWithFlowVar[T](tp: ThreadPool, m: MsgTo): FlowVar[T] =
  result.new()
  result.tp = tp
  result.idx = -1
  GC_ref(result)
  m.flowVar = cast[pointer](result)
  tp.dispatchMessage(m)

proc sendBack[T](v: T, c: ChannelFromPtr, flowVar: pointer) {.gcsafe.} =
  if not flowVar.isNil:
    var msg: ConcreteMsgFrom[T]
    msg.new()
    when T isnot void:
      msg.v = v
    msg.writeResult = proc(m: MsgFrom) {.nimcall.} =
      let m = cast[ConcreteMsgFrom[T]](m)
      let fv = cast[FlowVar[T]](m.flowVar)
      fv.tp = nil
      when T isnot void:
        fv.v = m.v
      GC_unref(fv)
    msg.flowVar = flowVar
    c[].send(msg)

var i {.compileTime.} = 0

proc spawnAux(tp: NimNode, e: NimNode, withFlowVar: bool, doTry: bool = false): NimNode =
  let msgTypeName = genSym(nskType, "MsgSub" & $i)
  inc i
  let dispatchProcName = genSym(nskProc, "dispatchProc")
  let msgParamIdent = newIdentNode("m")

  let origProcName = e[0]
  let procTypParams = origProcName.getTypeInst()[0]

  let msgFields = newNimNode(nnkRecList)

  let theCall = newCall(origProcName)

  let msgObjConstr = newNimNode(nnkObjConstr).add(
    msgTypeName,
    newNimNode(nnkExprColonExpr).add(
      newIdentNode("action"),
      dispatchProcName
    )
  )

  var iParam = 0
  for i in 1 ..< procTypParams.len:
    for j in 0 .. procTypParams[i].len - 3:
      let fieldIdent = newIdentNode($procTypParams[i][j])
      var fieldType = procTypParams[i][^2]
      if fieldType.typeKind == ntyOpenArray: # convert openarray to seq
        fieldType = copyNimTree(fieldType)
        fieldType[0] = bindSym"seq"

      msgFields.add(newNimNode(nnkIdentDefs).add(fieldIdent, fieldType, newEmptyNode()))
      theCall.add(newNimNode(nnkDotExpr).add(
        newNimNode(nnkCast).add(msgTypeName, msgParamIdent),
        fieldIdent))

      var par = e[iParam + 1]
      if par.typeKind == ntyOpenArray: # convert openarray to seq
        par = newCall(bindSym"@", par)

      msgObjConstr.add(newNimNode(nnkExprColonExpr).add(fieldIdent, par))
      inc iParam

  let msgTypDef = newNimNode(nnkTypeSection).add(newNimNode(nnkTypeDef).add(
    msgTypeName,
    newEmptyNode(),
    newNimNode(nnkRefTy).add(
      newNimNode(nnkObjectTy).add(
        newEmptyNode(),
        newNimNode(nnkOfInherit).add(bindSym"MsgTo"),
        msgFields
      )
    )
  ))

  let chanFromIdent = newIdentNode("chanFrom")

  let dispatchProc = newProc(dispatchProcName, params = [
      newEmptyNode(),
      newNimNode(nnkIdentDefs).add(
        msgParamIdent,
        bindSym"MsgTo",
        newEmptyNode()
      ),
      newNimNode(nnkIdentDefs).add(
        chanFromIdent,
        bindSym"ChannelFromPtr",
        newEmptyNode()
      )
    ],
    body = newCall(bindSym"sendBack", theCall, chanFromIdent, newNimNode(nnkDotExpr).add(
        msgParamIdent, newIdentNode("flowVar")))
  )

  dispatchProc.addPragma(newIdentNode("gcsafe"))

  var dispatchCall: NimNode
  if withFlowVar:
    dispatchCall = newCall(newNimNode(nnkBracketExpr).add(bindSym"dispatchMessageWithFlowVar", procTypParams[0]), tp, msgObjConstr)
  elif doTry:
    dispatchCall = newCall(bindSym"tryDispatchMessage", tp, msgObjConstr)
  else:
    dispatchCall = newCall(bindSym"dispatchMessage", tp, msgObjConstr)

  result = newNimNode(nnkStmtList).add(
    msgTypDef,
    dispatchProc,
    dispatchCall
  )

macro spawn*(tp: ThreadPool, e: typed{nkCall}): untyped =
  spawnAux(tp, e, getTypeInst(e).typeKind != ntyVoid)

macro spawnFV*(tp: ThreadPool, e: typed{nkCall}): untyped =
  spawnAux(tp, e, true)

macro trySpawn*(tp: ThreadPool, e: typed{nkCall}): untyped =
  spawnAux(tp, e, false, true)

template spawnX*(tp: ThreadPool, call: typed) =
  if not tp.trySpawn(call):
    call

proc nextMessage(tp: ThreadPool): int =
  let msg = tp.chanFrom.recv()
  msg.writeResult(msg)
  result = cast[FlowVarBase](msg.flowVar).idx

proc tryNextMessage(tp: ThreadPool): bool {.inline.} =
  let m = tp.chanFrom.tryRecv()
  result = m.dataAvailable
  if result:
    m.msg.writeResult(m.msg)

proc await*(v: FlowVarBase) =
  while not v.isReadyAux:
    discard v.tp.nextMessage()
  v.idx = 0

proc awaitAny*[T](vv: openarray[FlowVar[T]]): int =
  var foundIncomplete = false
  var tp: ThreadPool
  for i, v in vv:
    if v.isReadyAux:
      if v.idx == -1:
        v.idx = 0
        return i
    else:
      v.idx = i
      foundIncomplete = true
      tp = v.tp

  if foundIncomplete:
    tp.nextMessage()
  else:
    -1

proc isReady*(v: FlowVarBase): bool =
  while not v.isReadyAux:
    if not v.tp.tryNextMessage():
      return
  result = true

proc read*[T](v: FlowVar[T]): T =
  await(v)
  result = v.v

proc `^`*[T](fv: FlowVar[T]): T {.inline.} = fv.read()

################################################################################
# Deprecated spawn
const
  MaxThreadPoolSize* = 256 ## maximal size of the thread pool. 256 threads
                           ## should be good enough for anybody ;-)
  MaxDistinguishedThread* = 32 ## maximal number of "distinguished" threads.

type
  ThreadId* = range[0..MaxDistinguishedThread-1]

var gThreadPool {.threadvar.}: ThreadPool
var gPinnedPools {.threadvar.}: seq[ThreadPool]

proc sharedThreadPool(): ThreadPool =
  if gThreadPool.isNil:
    gThreadPool = newThreadPool()
  result = gThreadPool

proc pinnedPool(id: ThreadId): ThreadPool =
  if gPinnedPools.len <= id:
    if gPinnedPools.isNil:
      gPinnedPools = newSeq[ThreadPool](id + 1)
    else:
      gPinnedPools.setLen(id + 1)
  if gPinnedPools[id].isNil:
    gPinnedPools[id] = newSerialThreadPool()
  result = gPinnedPools[id]

proc preferSpawn*(): bool {.deprecated.} = true

template spawn*(call: typed): untyped {.deprecated.} =
  sharedThreadPool().spawn(call)

template pinnedSpawn*(id: ThreadId; call: typed): untyped {.deprecated.} =
  pinnedPool(id).spawn(call)
  ## always spawns a new task on the worker thread with ``id``, so that
  ## the 'call' is **always** executed on
  ## the thread. 'call' has to be proc call 'p(...)' where 'p'
  ## is gcsafe and has a return type that is either 'void' or compatible
  ## with ``FlowVar[T]``.

template spawnX*(call: typed) {.deprecated.} =
  sharedThreadPool().spawnX(call)
  ## spawns a new task if a CPU core is ready, otherwise executes the
  ## call in the calling thread. Usually it is advised to
  ## use 'spawn' in order to not block the producer for an unknown
  ## amount of time. 'call' has to be proc call 'p(...)' where 'p'
  ## is gcsafe and has a return type that is either 'void' or compatible
  ## with ``FlowVar[T]``.

# proc parallel*(body: untyped) {.magic: "Parallel".}
#   ## a parallel section can be used to execute a block in parallel. ``body``
#   ## has to be in a DSL that is a particular subset of the language. Please
#   ## refer to the manual for further information.

proc sync*() {.deprecated, inline.} =
  sharedThreadPool().sync()
