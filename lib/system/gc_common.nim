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
  proc dumpNumberOfInstances* =
    var it = nimTypeRoot
    while it != nil:
      if it.instances > 0:
        c_fprintf(stdout, "[Heap] %s: #%ld; bytes: %ld\n", it.name, it.instances, it.sizes)
      it = it.nextType

template decTypeSize(cell, t) =
  # XXX this needs to use atomics for multithreaded apps!
  when defined(nimTypeNames):
    if t.kind in {tyString, tySequence}:
      let len = cast[PGenericSeq](cellToUsr(cell)).len
      let base = if t.kind == tyString: 1 else: t.base.size
      let size = addInt(mulInt(len, base), GenericSeqSize)
      dec t.sizes, size+sizeof(Cell)
    else:
      dec t.sizes, t.size+sizeof(Cell)
    dec t.instances

template incTypeSize(typ, size) =
  when defined(nimTypeNames):
    inc typ.instances
    inc typ.sizes, size+sizeof(Cell)

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

proc len(stack: ptr GcStack): int =
  if stack == nil:
    return 0

  var s = stack
  result = 1
  while s.next != nil:
    inc(result)
    s = s.next

when defined(nimCoroutines):
  proc stackSize(stack: ptr GcStack): int {.noinline.} =
    if stack.pos != nil:
      when defined(stackIncreases):
        result = cast[ByteAddress](stack.pos) -% cast[ByteAddress](stack.bottom)
      else:
        result = cast[ByteAddress](stack.bottom) -% cast[ByteAddress](stack.pos)
    else:
      result = 0

  proc setPosition(stack: ptr GcStack, position: pointer) =
    stack.pos = position
    stack.maxStackSize = max(stack.maxStackSize, stack.stackSize())

  proc setPosition(stack: var GcStack, position: pointer) =
    setPosition(addr(stack), position)

  proc stackSize(): int {.noinline.} =
    for stack in gch.stack.items():
      result = result + stack.stackSize()
else:
  proc stackSize(): int {.noinline.} =
    var stackTop {.volatile.}: pointer
    result = abs(cast[int](addr(stackTop)) - cast[int](gch.stackBottom))

iterator items(stack: ptr GcStack): ptr GcStack =
  var s = stack
  while not isNil(s):
    yield s
    s = s.next

when declared(threadType):
  proc setupForeignThreadGc*() {.gcsafe.} =
    ## Call this if you registered a callback that will be run from a thread not
    ## under your control. This has a cheap thread-local guard, so the GC for
    ## this thread will only be initialized once per thread, no matter how often
    ## it is called.
    ##
    ## This function is available only when ``--threads:on`` and ``--tlsEmulation:off``
    ## switches are used
    if threadType == ThreadType.None:
      initAllocator()
      var stackTop {.volatile.}: pointer
      setStackBottom(addr(stackTop))
      initGC()
      threadType = ThreadType.ForeignThread

  proc tearDownForeignThreadGc*() {.gcsafe.} =
    ## Call this to tear down the GC, previously initialized by ``setupForeignThreadGc``.
    ## If GC has not been previously initialized, or has already been torn down, the
    ## call does nothing.
    ##
    ## This function is available only when ``--threads:on`` and ``--tlsEmulation:off``
    ## switches are used
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

when defined(emscripten):
  const stackIncreases = true
elif defined(sparc):
  const stackIncreases = false
elif defined(hppa) or defined(hp9000) or defined(hp9000s300) or
     defined(hp9000s700) or defined(hp9000s800) or defined(hp9000s820):
  const stackIncreases = true
else:
  const stackIncreases = false

{.push stack_trace: off.}
when defined(nimCoroutines):
  proc GC_addStack(bottom: pointer) {.cdecl, exportc.} =
    # c_fprintf(stdout, "GC_addStack: %p;\n", bottom)
    var stack = gch.stack.append()
    stack.bottom = bottom
    stack.setPosition(bottom)

  proc GC_removeStack(bottom: pointer) {.cdecl, exportc.} =
    # c_fprintf(stdout, "GC_removeStack: %p;\n", bottom)
    gch.stack.find(bottom).remove()

  proc GC_setActiveStack(bottom: pointer) {.cdecl, exportc.} =
    ## Sets active stack and updates current stack position.
    # c_fprintf(stdout, "GC_setActiveStack: %p;\n", bottom)
    var sp {.volatile.}: pointer
    gch.activeStack = gch.stack.find(bottom)
    gch.activeStack.setPosition(addr(sp))

when not defined(useNimRtl):
  when defined(nimCoroutines):
    proc setStackBottom(theStackBottom: pointer) =
      # Initializes main stack of the thread.
      if gch.stack.next == nil:
        # Main stack was not initialized yet
        gch.stack.next = addr(gch.stack)
        gch.stack.prev = addr(gch.stack)
        gch.stack.bottom = theStackBottom
        gch.stack.maxStackSize = 0
        gch.activeStack = addr(gch.stack)
      else:
        var a = cast[ByteAddress](theStackBottom) # and not PageMask - PageSize*2
        var b = cast[ByteAddress](gch.stack.bottom)
        #c_fprintf(stdout, "old: %p new: %p;\n",gch.stackBottom,theStackBottom)
        when stackIncreases:
          gch.stack.bottom = cast[pointer](min(a, b))
        else:
          gch.stack.bottom = cast[pointer](max(a, b))
      gch.stack.setPosition(theStackBottom)

  else:
    proc setStackBottom(theStackBottom: pointer) =
      #c_fprintf(stdout, "stack bottom: %p;\n", theStackBottom)
      # the first init must be the one that defines the stack bottom:
      if gch.stackBottom == nil: gch.stackBottom = theStackBottom
      else:
        var a = cast[ByteAddress](theStackBottom) # and not PageMask - PageSize*2
        var b = cast[ByteAddress](gch.stackBottom)
        #c_fprintf(stdout, "old: %p new: %p;\n",gch.stackBottom,theStackBottom)
        when stackIncreases:
          gch.stackBottom = cast[pointer](min(a, b))
        else:
          gch.stackBottom = cast[pointer](max(a, b))
{.pop.}

when defined(sparc): # For SPARC architecture.
  when defined(nimCoroutines):
    {.error: "Nim coroutines are not supported on this platform."}

  proc isOnStack(p: pointer): bool =
    var stackTop {.volatile.}: pointer
    stackTop = addr(stackTop)
    var b = cast[ByteAddress](gch.stackBottom)
    var a = cast[ByteAddress](stackTop)
    var x = cast[ByteAddress](p)
    result = a <=% x and x <=% b

  template forEachStackSlot(gch, gcMark: untyped) {.dirty.} =
    when defined(sparcv9):
      asm  """"flushw \n" """
    else:
      asm  """"ta      0x3   ! ST_FLUSH_WINDOWS\n" """

    var
      max = gch.stackBottom
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
  when defined(nimCoroutines):
    {.error: "Nim coroutines are not supported on this platform."}
  proc isOnStack(p: pointer): bool =
    var stackTop {.volatile.}: pointer
    stackTop = addr(stackTop)
    var a = cast[ByteAddress](gch.stackBottom)
    var b = cast[ByteAddress](stackTop)
    var x = cast[ByteAddress](p)
    result = a <=% x and x <=% b

  var
    jmpbufSize {.importc: "sizeof(jmp_buf)", nodecl.}: int
      # a little hack to get the size of a JmpBuf in the generated C code
      # in a platform independent way

  template forEachStackSlot(gch, gcMark: untyped) {.dirty.} =
    var registers {.noinit.}: C_JmpBuf
    if c_setjmp(registers) == 0'i32: # To fill the C stack with registers.
      var max = cast[ByteAddress](gch.stackBottom)
      var sp = cast[ByteAddress](addr(registers)) +% jmpbufSize -% sizeof(pointer)
      # sp will traverse the JMP_BUF as well (jmp_buf size is added,
      # otherwise sp would be below the registers structure).
      while sp >=% max:
        gcMark(gch, cast[PPointer](sp)[])
        sp = sp -% sizeof(pointer)

else:
  # ---------------------------------------------------------------------------
  # Generic code for architectures where addresses decrease as the stack grows.
  # ---------------------------------------------------------------------------
  when defined(nimCoroutines):
    proc isOnStack(p: pointer): bool =
      var stackTop {.volatile.}: pointer
      stackTop = addr(stackTop)
      var b = cast[ByteAddress](gch.activeStack.bottom)
      var a = cast[ByteAddress](stackTop)
      var x = cast[ByteAddress](p)
      result = a <=% x and x <=% b

    template forEachStackSlot(gch, gcMark: untyped) {.dirty.} =
      # We use a jmp_buf buffer that is in the C stack.
      # Used to traverse the stack and registers assuming
      # that 'setjmp' will save registers in the C stack.
      type PStackSlice = ptr array[0..7, pointer]
      var registers {.noinit.}: C_JmpBuf
      # Update position of stack gc is executing in.
      gch.activeStack.setPosition(addr(registers))
      if c_setjmp(registers) == 0'i32: # To fill the C stack with registers.
        for stack in gch.stack.items():
          var max = cast[ByteAddress](stack.bottom)
          var sp = cast[ByteAddress](addr(registers))
          when defined(amd64):
            if stack == gch.activeStack:
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

  else:
    proc isOnStack(p: pointer): bool =
      var stackTop {.volatile.}: pointer
      stackTop = addr(stackTop)
      var b = cast[ByteAddress](gch.stackBottom)
      var a = cast[ByteAddress](stackTop)
      var x = cast[ByteAddress](p)
      result = a <=% x and x <=% b

    template forEachStackSlot(gch, gcMark: untyped) {.dirty.} =
      # We use a jmp_buf buffer that is in the C stack.
      # Used to traverse the stack and registers assuming
      # that 'setjmp' will save registers in the C stack.
      type PStackSlice = ptr array[0..7, pointer]
      var registers {.noinit.}: C_JmpBuf
      if c_setjmp(registers) == 0'i32: # To fill the C stack with registers.
        var max = cast[ByteAddress](gch.stackBottom)
        var sp = cast[ByteAddress](addr(registers))
        when defined(amd64):
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
