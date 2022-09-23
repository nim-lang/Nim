#
#
#            Nim's Runtime Library
#        (c) Copyright 2015 Rokas Kupstys
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

type
  ForeignCell* = object
    data*: pointer
    owner: ptr GcHeap

proc protect*(x: pointer): ForeignCell =
  nimGCref(x)
  result.data = x
  result.owner = addr(gch)

when defined(nimTypeNames):
  type InstancesInfo = array[400, (cstring, int, int)]
  proc sortInstances(a: var InstancesInfo; n: int) =
    # we use shellsort here; fast and simple
    var h = 1
    while true:
      h = 3 * h + 1
      if h > n: break
    while true:
      h = h div 3
      for i in countup(h, n - 1):
        var v = a[i]
        var j = i
        while a[j - h][2] < v[2]:
          a[j] = a[j - h]
          j = j - h
          if j < h: break
        a[j] = v
      if h == 1: break

  iterator dumpHeapInstances*(): tuple[name: cstring; count: int; sizes: int] =
    ## Iterate over summaries of types on heaps.
    ## This data may be inaccurate if allocations
    ## are made by the iterator body.
    if strDesc.nextType == nil:
      strDesc.nextType = nimTypeRoot
      strDesc.name = "string"
      nimTypeRoot = addr strDesc
    var it = nimTypeRoot
    while it != nil:
      if (it.instances > 0 or it.sizes != 0):
        yield (it.name, it.instances, it.sizes)
      it = it.nextType

  proc dumpNumberOfInstances* =
    var a: InstancesInfo
    var n = 0
    var totalAllocated = 0
    for it in dumpHeapInstances():
      a[n] = it
      inc n
      inc totalAllocated, it.sizes
    sortInstances(a, n)
    for i in 0 .. n-1:
      c_fprintf(cstdout, "[Heap] %s: #%ld; bytes: %ld\n", a[i][0], a[i][1], a[i][2])
    c_fprintf(cstdout, "[Heap] total number of bytes: %ld\n", totalAllocated)
    when defined(nimTypeNames):
      let (allocs, deallocs) = getMemCounters()
      c_fprintf(cstdout, "[Heap] allocs/deallocs: %ld/%ld\n", allocs, deallocs)

  when defined(nimGcRefLeak):
    proc oomhandler() =
      c_fprintf(cstdout, "[Heap] ROOTS: #%ld\n", gch.additionalRoots.len)
      writeLeaks()

    outOfMemHook = oomhandler

template decTypeSize(cell, t) =
  when defined(nimTypeNames):
    if t.kind in {tyString, tySequence}:
      let cap = cast[PGenericSeq](cellToUsr(cell)).space
      let size =
        if t.kind == tyString:
          cap + 1 + GenericSeqSize
        else:
          align(GenericSeqSize, t.base.align) + cap * t.base.size
      atomicDec t.sizes, size+sizeof(Cell)
    else:
      atomicDec t.sizes, t.base.size+sizeof(Cell)
    atomicDec t.instances

template incTypeSize(typ, size) =
  when defined(nimTypeNames):
    atomicInc typ.instances
    atomicInc typ.sizes, size+sizeof(Cell)

proc dispose*(x: ForeignCell) =
  when hasThreadSupport:
    # if we own it we can free it directly:
    if x.owner == addr(gch):
      nimGCunref(x.data)
    else:
      x.owner.toDispose.add(x.data)
  else:
    nimGCunref(x.data)

proc isNotForeign*(x: ForeignCell): bool =
  ## returns true if 'x' belongs to the calling thread.
  ## No deep copy has to be performed then.
  x.owner == addr(gch)

when nimCoroutines:
  iterator items(first: var GcStack): ptr GcStack =
    var item = addr(first)
    while true:
      yield item
      item = item.next
      if item == addr(first):
        break

  proc append(first: var GcStack, stack: ptr GcStack) =
    ## Append stack to the ring of stacks.
    first.prev.next = stack
    stack.prev = first.prev
    first.prev = stack
    stack.next = addr(first)

  proc append(first: var GcStack): ptr GcStack =
    ## Allocate new GcStack object, append it to the ring of stacks and return it.
    result = cast[ptr GcStack](alloc0(sizeof(GcStack)))
    first.append(result)

  proc remove(first: var GcStack, stack: ptr GcStack) =
    ## Remove stack from ring of stacks.
    gcAssert(addr(first) != stack, "Main application stack can not be removed")
    if addr(first) == stack or stack == nil:
      return
    stack.prev.next = stack.next
    stack.next.prev = stack.prev
    dealloc(stack)

  proc remove(stack: ptr GcStack) =
    gch.stack.remove(stack)

  proc find(first: var GcStack, bottom: pointer): ptr GcStack =
    ## Find stack struct based on bottom pointer. If `bottom` is nil then main
    ## thread stack is is returned.
    if bottom == nil:
      return addr(gch.stack)

    for stack in first.items():
      if stack.bottom == bottom:
        return stack

  proc len(stack: var GcStack): int =
    for _ in stack.items():
      result = result + 1
else:
  # This iterator gets optimized out in forEachStackSlot().
  iterator items(first: var GcStack): ptr GcStack = yield addr(first)
  proc len(stack: var GcStack): int = 1

when defined(nimdoc):
  proc setupForeignThreadGc*() {.gcsafe.} =
    ## Call this if you registered a callback that will be run from a thread not
    ## under your control. This has a cheap thread-local guard, so the GC for
    ## this thread will only be initialized once per thread, no matter how often
    ## it is called.
    ##
    ## This function is available only when `--threads:on` and `--tlsEmulation:off`
    ## switches are used
    discard

  proc tearDownForeignThreadGc*() {.gcsafe.} =
    ## Call this to tear down the GC, previously initialized by `setupForeignThreadGc`.
    ## If GC has not been previously initialized, or has already been torn down, the
    ## call does nothing.
    ##
    ## This function is available only when `--threads:on` and `--tlsEmulation:off`
    ## switches are used
    discard
elif declared(threadType):
  proc setupForeignThreadGc*() {.gcsafe.} =
    if threadType == ThreadType.None:
      var stackTop {.volatile.}: pointer
      nimGC_setStackBottom(addr(stackTop))
      initGC()
      threadType = ThreadType.ForeignThread

  proc tearDownForeignThreadGc*() {.gcsafe.} =
    if threadType != ThreadType.ForeignThread:
      return
    when declared(deallocOsPages): deallocOsPages()
    threadType = ThreadType.None
    when declared(gch): zeroMem(addr gch, sizeof(gch))

else:
  template setupForeignThreadGc*() =
    {.error: "setupForeignThreadGc is available only when ``--threads:on`` and ``--tlsEmulation:off`` are used".}

  template tearDownForeignThreadGc*() =
    {.error: "tearDownForeignThreadGc is available only when ``--threads:on`` and ``--tlsEmulation:off`` are used".}

# ----------------- stack management --------------------------------------
#  inspired from Smart Eiffel

when defined(emscripten) or defined(wasm):
  const stackIncreases = true
elif defined(sparc):
  const stackIncreases = false
elif defined(hppa) or defined(hp9000) or defined(hp9000s300) or
     defined(hp9000s700) or defined(hp9000s800) or defined(hp9000s820):
  const stackIncreases = true
else:
  const stackIncreases = false

proc stackSize(stack: ptr GcStack): int {.noinline.} =
  when nimCoroutines:
    var pos = stack.pos
  else:
    var pos {.volatile, noinit.}: pointer
    pos = addr(pos)

  if pos != nil:
    when stackIncreases:
      result = cast[ByteAddress](pos) -% cast[ByteAddress](stack.bottom)
    else:
      result = cast[ByteAddress](stack.bottom) -% cast[ByteAddress](pos)
  else:
    result = 0

proc stackSize(): int {.noinline.} =
  result = 0
  for stack in gch.stack.items():
    result = result + stack.stackSize()

when nimCoroutines:
  proc setPosition(stack: ptr GcStack, position: pointer) =
    stack.pos = position
    stack.maxStackSize = max(stack.maxStackSize, stack.stackSize())

  proc setPosition(stack: var GcStack, position: pointer) =
    setPosition(addr(stack), position)

  proc getActiveStack(gch: var GcHeap): ptr GcStack =
    return gch.activeStack

  proc isActiveStack(stack: ptr GcStack): bool =
    return gch.activeStack == stack
else:
  # Stack positions do not need to be tracked if coroutines are not used.
  proc setPosition(stack: ptr GcStack, position: pointer) = discard
  proc setPosition(stack: var GcStack, position: pointer) = discard
  # There is just one stack - main stack of the thread. It is active always.
  proc getActiveStack(gch: var GcHeap): ptr GcStack = addr(gch.stack)
  proc isActiveStack(stack: ptr GcStack): bool = true

{.push stack_trace: off.}
when nimCoroutines:
  proc GC_addStack(bottom: pointer) {.cdecl, dynlib, exportc.} =
    # c_fprintf(stdout, "GC_addStack: %p;\n", bottom)
    var stack = gch.stack.append()
    stack.bottom = bottom
    stack.setPosition(bottom)

  proc GC_removeStack(bottom: pointer) {.cdecl, dynlib, exportc.} =
    # c_fprintf(stdout, "GC_removeStack: %p;\n", bottom)
    gch.stack.find(bottom).remove()

  proc GC_setActiveStack(bottom: pointer) {.cdecl, dynlib, exportc.} =
    ## Sets active stack and updates current stack position.
    # c_fprintf(stdout, "GC_setActiveStack: %p;\n", bottom)
    var sp {.volatile.}: pointer
    gch.activeStack = gch.stack.find(bottom)
    gch.activeStack.setPosition(addr(sp))

  proc GC_getActiveStack() : pointer {.cdecl, exportc.} =
    return gch.activeStack.bottom

when not defined(useNimRtl):
  proc nimGC_setStackBottom(theStackBottom: pointer) =
    # Initializes main stack of the thread.
    when nimCoroutines:
      if gch.stack.next == nil:
        # Main stack was not initialized yet
        gch.stack.next = addr(gch.stack)
        gch.stack.prev = addr(gch.stack)
        gch.stack.bottom = theStackBottom
        gch.stack.maxStackSize = 0
        gch.activeStack = addr(gch.stack)

    if gch.stack.bottom == nil:
      # This branch will not be called when -d:nimCoroutines - it is fine,
      # because same thing is done just above.
      #c_fprintf(stdout, "stack bottom: %p;\n", theStackBottom)
      # the first init must be the one that defines the stack bottom:
      gch.stack.bottom = theStackBottom
    elif theStackBottom != gch.stack.bottom:
      var a = cast[ByteAddress](theStackBottom) # and not PageMask - PageSize*2
      var b = cast[ByteAddress](gch.stack.bottom)
      #c_fprintf(stdout, "old: %p new: %p;\n",gch.stack.bottom,theStackBottom)
      when stackIncreases:
        gch.stack.bottom = cast[pointer](min(a, b))
      else:
        gch.stack.bottom = cast[pointer](max(a, b))

    when nimCoroutines:
      if theStackBottom != nil: gch.stack.bottom = theStackBottom

    gch.stack.setPosition(theStackBottom)
{.pop.}

proc isOnStack(p: pointer): bool =
  var stackTop {.volatile, noinit.}: pointer
  stackTop = addr(stackTop)
  var a = cast[ByteAddress](gch.getActiveStack().bottom)
  var b = cast[ByteAddress](stackTop)
  when not stackIncreases:
    swap(a, b)
  var x = cast[ByteAddress](p)
  result = a <=% x and x <=% b

when defined(sparc): # For SPARC architecture.
  when nimCoroutines:
    {.error: "Nim coroutines are not supported on this platform."}

  template forEachStackSlot(gch, gcMark: untyped) {.dirty.} =
    when defined(sparcv9):
      asm  """"flushw \n" """
    else:
      asm  """"ta      0x3   ! ST_FLUSH_WINDOWS\n" """

    var
      max = gch.stack.bottom
      sp: PPointer
      stackTop: array[0..1, pointer]
    sp = addr(stackTop[0])
    # Addresses decrease as the stack grows.
    while sp <= max:
      gcMark(gch, sp[])
      sp = cast[PPointer](cast[ByteAddress](sp) +% sizeof(pointer))

elif defined(ELATE):
  {.error: "stack marking code is to be written for this architecture".}

elif stackIncreases:
  # ---------------------------------------------------------------------------
  # Generic code for architectures where addresses increase as the stack grows.
  # ---------------------------------------------------------------------------
  when defined(emscripten) or defined(wasm):
    var
      jmpbufSize {.importc: "sizeof(jmp_buf)", nodecl.}: int
        # a little hack to get the size of a JmpBuf in the generated C code
        # in a platform independent way

  template forEachStackSlotAux(gch, gcMark: untyped) {.dirty.} =
    for stack in gch.stack.items():
      var max = cast[ByteAddress](gch.stack.bottom)
      var sp = cast[ByteAddress](addr(registers)) -% sizeof(pointer)
      while sp >=% max:
        gcMark(gch, cast[PPointer](sp)[])
        sp = sp -% sizeof(pointer)

  template forEachStackSlot(gch, gcMark: untyped) {.dirty.} =
    when defined(emscripten) or defined(wasm):
      var registers: cint
      forEachStackSlotAux(gch, gcMark)
    else:
      var registers {.noinit.}: C_JmpBuf
      if c_setjmp(registers) == 0'i32: # To fill the C stack with registers.
        forEachStackSlotAux(gch, gcMark)

else:
  # ---------------------------------------------------------------------------
  # Generic code for architectures where addresses decrease as the stack grows.
  # ---------------------------------------------------------------------------
  template forEachStackSlot(gch, gcMark: untyped) {.dirty.} =
    # We use a jmp_buf buffer that is in the C stack.
    # Used to traverse the stack and registers assuming
    # that 'setjmp' will save registers in the C stack.
    type PStackSlice = ptr array[0..7, pointer]
    var registers {.noinit.}: C_JmpBuf
    # Update position of stack gc is executing in.
    gch.getActiveStack().setPosition(addr(registers))
    if c_setjmp(registers) == 0'i32: # To fill the C stack with registers.
      for stack in gch.stack.items():
        var max = cast[ByteAddress](stack.bottom)
        var sp = cast[ByteAddress](addr(registers))
        when defined(amd64):
          if stack.isActiveStack():
            # words within the jmp_buf structure may not be properly aligned.
            let regEnd = sp +% sizeof(registers)
            while sp <% regEnd:
              gcMark(gch, cast[PPointer](sp)[])
              gcMark(gch, cast[PPointer](sp +% sizeof(pointer) div 2)[])
              sp = sp +% sizeof(pointer)
        # Make sure sp is word-aligned
        sp = sp and not (sizeof(pointer) - 1)
        # loop unrolled:
        while sp <% max - 8*sizeof(pointer):
          gcMark(gch, cast[PStackSlice](sp)[0])
          gcMark(gch, cast[PStackSlice](sp)[1])
          gcMark(gch, cast[PStackSlice](sp)[2])
          gcMark(gch, cast[PStackSlice](sp)[3])
          gcMark(gch, cast[PStackSlice](sp)[4])
          gcMark(gch, cast[PStackSlice](sp)[5])
          gcMark(gch, cast[PStackSlice](sp)[6])
          gcMark(gch, cast[PStackSlice](sp)[7])
          sp = sp +% sizeof(pointer)*8
        # last few entries:
        while sp <=% max:
          gcMark(gch, cast[PPointer](sp)[])
          sp = sp +% sizeof(pointer)

# ----------------------------------------------------------------------------
# end of non-portable code
# ----------------------------------------------------------------------------

proc prepareDealloc(cell: PCell) {.raises: [].} =
  when declared(useMarkForDebug):
    when useMarkForDebug:
      gcAssert(cell notin gch.marked, "Cell still alive!")
  let t = cell.typ
  if t.finalizer != nil:
    # the finalizer could invoke something that
    # allocates memory; this could trigger a garbage
    # collection. Since we are already collecting we
    # prevent recursive entering here by a lock.
    # XXX: we should set the cell's children to nil!
    inc(gch.recGcLock)
    (cast[Finalizer](t.finalizer))(cellToUsr(cell))
    dec(gch.recGcLock)
  decTypeSize(cell, t)

proc deallocHeap*(runFinalizers = true; allowGcAfterwards = true) =
  ## Frees the thread local heap. Runs every finalizer if `runFinalizers`
  ## is true. If `allowGcAfterwards` is true, a minimal amount of allocation
  ## happens to ensure the GC can continue to work after the call
  ## to `deallocHeap`.
  template deallocCell(x) =
    if isCell(x):
      # cast to PCell is correct here:
      prepareDealloc(cast[PCell](x))

  if runFinalizers:
    when not declared(allObjectsAsProc):
      for x in allObjects(gch.region):
        deallocCell(x)
    else:
      var spaceIter: ObjectSpaceIter
      while true:
        let x = allObjectsAsProc(gch.region, addr spaceIter)
        if spaceIter.state < 0: break
        deallocCell(x)

  deallocOsPages(gch.region)
  zeroMem(addr gch.region, sizeof(gch.region))
  if allowGcAfterwards:
    initGC()

type
  GlobalMarkerProc = proc () {.nimcall, benign, raises: [].}
var
  globalMarkersLen {.exportc.}: int
  globalMarkers {.exportc.}: array[0..3499, GlobalMarkerProc]
  threadLocalMarkersLen {.exportc.}: int
  threadLocalMarkers {.exportc.}: array[0..3499, GlobalMarkerProc]
  gHeapidGenerator: int

proc nimRegisterGlobalMarker(markerProc: GlobalMarkerProc) {.compilerproc.} =
  if globalMarkersLen <= high(globalMarkers):
    globalMarkers[globalMarkersLen] = markerProc
    inc globalMarkersLen
  else:
    cstderr.rawWrite("[GC] cannot register global variable; too many global variables")
    quit 1

proc nimRegisterThreadLocalMarker(markerProc: GlobalMarkerProc) {.compilerproc.} =
  if threadLocalMarkersLen <= high(threadLocalMarkers):
    threadLocalMarkers[threadLocalMarkersLen] = markerProc
    inc threadLocalMarkersLen
  else:
    cstderr.rawWrite("[GC] cannot register thread local variable; too many thread local variables")
    quit 1
