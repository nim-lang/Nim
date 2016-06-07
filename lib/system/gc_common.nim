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
  proc stackSize(stackBottom: pointer, pos: pointer=nil): int {.noinline.} =
    var sp: pointer
    if pos == nil:
      var stackTop {.volatile.}: pointer
      sp = addr(stackTop)
    else:
      sp = pos
    result = abs(cast[int](sp) - cast[int](stackBottom))

  proc GC_addStack*(starts: pointer) {.cdecl, exportc.} =
    var sp {.volatile.}: pointer
    var stack = cast[ptr GcStack](alloc0(sizeof(GcStack)))
    stack.starts = starts
    stack.pos = addr sp
    if gch.stack == nil:
      gch.stack = stack
    else:
      stack.next = gch.stack
      gch.stack.prev = stack
      gch.stack = stack
    # c_fprintf(c_stdout, "[GC] added stack 0x%016X\n", starts)

  proc GC_removeStack*(starts: pointer) {.cdecl, exportc.} =
    var stack = gch.stack
    while stack != nil:
      if stack.starts == starts:
        if stack.prev == nil:
          if stack.next != nil:
            stack.next.prev = nil
          gch.stack = stack.next
        else:
          stack.prev.next = stack.next
          if stack.next != nil:
              stack.next.prev = stack.prev
        dealloc(stack)
        # echo "[GC] removed stack ", starts.repr
        break
      else:
        stack = stack.next

  proc GC_setCurrentStack*(starts, pos: pointer) {.cdecl, exportc.} =
    var stack = gch.stack
    while stack != nil:
      if stack.starts == starts:
        stack.pos = pos
        stack.maxStackSize = max(stack.maxStackSize, stackSize(stack.starts, pos))
        return
      stack = stack.next
    gcAssert(false, "Current stack position does not belong to registered stack")
else:
  proc stackSize(): int {.noinline.} =
    var stackTop {.volatile.}: pointer
    result = abs(cast[int](addr(stackTop)) - cast[int](gch.stackBottom))

iterator items(stack: ptr GcStack): ptr GcStack =
  var s = stack
  while not isNil(s):
    yield s
    s = s.next

# There will be problems with GC in foreign threads if `threads` option is off or TLS emulation is enabled
const allowForeignThreadGc = compileOption("threads") and not compileOption("tlsEmulation")

when allowForeignThreadGc:
  var
    localGcInitialized {.rtlThreadVar.}: bool

  proc setupForeignThreadGc*() =
    ## Call this if you registered a callback that will be run from a thread not
    ## under your control. This has a cheap thread-local guard, so the GC for
    ## this thread will only be initialized once per thread, no matter how often
    ## it is called.
    ##
    ## This function is available only when ``--threads:on`` and ``--tlsEmulation:off``
    ## switches are used
    if not localGcInitialized:
      localGcInitialized = true
      var stackTop {.volatile.}: pointer
      setStackBottom(addr(stackTop))
      initGC()
else:
  template setupForeignThreadGc*(): stmt =
    {.error: "setupForeignThreadGc is available only when ``--threads:on`` and ``--tlsEmulation:off`` are used".}

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

when not defined(useNimRtl):
  {.push stack_trace: off.}
  proc setStackBottom(theStackBottom: pointer) =
    #c_fprintf(c_stdout, "stack bottom: %p;\n", theStackBottom)
    # the first init must be the one that defines the stack bottom:
    when defined(nimCoroutines):
      GC_addStack(theStackBottom)
    else:
      if gch.stackBottom == nil: gch.stackBottom = theStackBottom
      else:
        var a = cast[ByteAddress](theStackBottom) # and not PageMask - PageSize*2
        var b = cast[ByteAddress](gch.stackBottom)
        #c_fprintf(c_stdout, "old: %p new: %p;\n",gch.stackBottom,theStackBottom)
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

  template forEachStackSlot(gch, gcMark: expr) {.immediate, dirty.} =
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

  template forEachStackSlot(gch, gcMark: expr) {.immediate, dirty.} =
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
      for stack in items(gch.stack):
        var b = cast[ByteAddress](stack.starts)
        var a = cast[ByteAddress](stack.starts) - stack.maxStackSize
        var x = cast[ByteAddress](p)
        if a <=% x and x <=% b:
          return true

    template forEachStackSlot(gch, gcMark: expr) {.immediate, dirty.} =
      # We use a jmp_buf buffer that is in the C stack.
      # Used to traverse the stack and registers assuming
      # that 'setjmp' will save registers in the C stack.
      type PStackSlice = ptr array [0..7, pointer]
      var registers {.noinit.}: Registers
      getRegisters(registers)
      for i in registers.low .. registers.high:
        gcMark(gch, cast[PPointer](registers[i]))

      for stack in items(gch.stack):
        stack.maxStackSize = max(stack.maxStackSize, stackSize(stack.starts))
        var max = cast[ByteAddress](stack.starts)
        var sp = cast[ByteAddress](stack.pos)
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

    template forEachStackSlot(gch, gcMark: expr) {.immediate, dirty.} =
      # We use a jmp_buf buffer that is in the C stack.
      # Used to traverse the stack and registers assuming
      # that 'setjmp' will save registers in the C stack.
      type PStackSlice = ptr array [0..7, pointer]
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
