#
#
#            Nim's Runtime Library
#        (c) Copyright 2019 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

#[
In this new runtime we simplify the object layouts a bit: The runtime type
information is only accessed for the objects that have it and it's always
at offset 0 then. The ``ref`` object header is independent from the
runtime type and only contains a reference count.

Object subtyping is checked via the generated 'name'. This should have
comparable overhead to the old pointer chasing approach but has the benefit
that it works across DLL boundaries.

The generated name is a concatenation of the object names in the hierarchy
so that a subtype check becomes a substring check. For example::

  type
    ObjectA = object of RootObj
    ObjectB = object of ObjectA

ObjectA's ``name`` is "|ObjectA|RootObj|".
ObjectB's ``name`` is "|ObjectB|ObjectA|RootObj|".

Now to check for ``x of ObjectB`` we need to check
for ``x.typ.name.hasSubstring("|ObjectB|")``. In the actual implementation,
however, we could also use a
hash of ``package & "." & module & "." & name`` to save space.

]#

const
  rcIncrement = 0b1000 # so that lowest 3 bits are not touched
  colGreen = 0b000
  colYellow = 0b001
  colRed = 0b010
  jumpStackFlag = 0b100  # stored in jumpstack
  rcShift = 3      # shift by rcShift to get the reference counter
  colorMask = 0b011
  rcMask = 0b111

template color(c): untyped = c.rc and colorMask
template setColor(c, col) =
  when col == colGreen:
    c.rc = c.rc and not colorMask
  else:
    c.rc = c.rc and not colorMask or col

type
  RefHeader = object
    rc: int # the object header is now a single RC field.
            # we could remove it in non-debug builds for the 'owned ref'
            # design but this seems unwise.
  Cell = ptr RefHeader
  TraceProc = proc (p, env: pointer) {.nimcall, benign.}
  DisposeProc = proc (p: pointer) {.nimcall, benign.}

template `+!`(p: pointer, s: int): pointer =
  cast[pointer](cast[int](p) +% s)

template `-!`(p: pointer, s: int): pointer =
  cast[pointer](cast[int](p) -% s)

template head(p: pointer): Cell =
  cast[Cell](cast[int](p) -% sizeof(RefHeader))

var allocs*: int

const
  traceCollector = false

proc nimNewObj(size: int): pointer {.compilerRtl.} =
  let s = size + sizeof(RefHeader)
  when defined(nimscript):
    discard
  elif defined(useMalloc):
    var orig = c_malloc(cuint s)
    nimZeroMem(orig, s)
    result = orig +! sizeof(RefHeader)
  else:
    result = alloc0(s) +! sizeof(RefHeader)
  when hasThreadSupport:
    atomicInc allocs
  else:
    inc allocs
  when traceCollector:
    cprintf("[Allocated] %p\n", result -! sizeof(RefHeader))

proc nimDecWeakRef(p: pointer) {.compilerRtl, inl.} =
  dec head(p).rc, rcIncrement

proc nimIncRef(p: pointer) {.compilerRtl, inl.} =
  inc head(p).rc, rcIncrement
  #cprintf("[INCREF] %p\n", p)

proc nimIncRefCyclic(p: pointer) {.compilerRtl, inl.} =
  let h = head(p)
  inc h.rc, rcIncrement
  h.setColor colYellow # mark as potential cycle!

proc nimRawDispose(p: pointer) {.compilerRtl.} =
  when not defined(nimscript):
    when traceCollector:
      cprintf("[Freed] %p\n", p -! sizeof(RefHeader))
    when defined(nimOwnedEnabled):
      if head(p).rc >= rcIncrement:
        cstderr.rawWrite "[FATAL] dangling references exist\n"
        quit 1
    when defined(useMalloc):
      c_free(p -! sizeof(RefHeader))
    else:
      dealloc(p -! sizeof(RefHeader))
    if allocs > 0:
      when hasThreadSupport:
        discard atomicDec(allocs)
      else:
        dec allocs
    else:
      cstderr.rawWrite "[FATAL] unpaired dealloc\n"
      quit 1

template dispose*[T](x: owned(ref T)) = nimRawDispose(cast[pointer](x))
#proc dispose*(x: pointer) = nimRawDispose(x)

proc nimDestroyAndDispose(p: pointer) {.compilerRtl.} =
  let d = cast[ptr PNimType](p)[].destructor
  if d != nil: cast[DestructorProc](d)(p)
  when false:
    cstderr.rawWrite cast[ptr PNimType](p)[].name
    cstderr.rawWrite "\n"
    if d == nil:
      cstderr.rawWrite "bah, nil\n"
    else:
      cstderr.rawWrite "has destructor!\n"
  nimRawDispose(p)

# Cycle collector based on Lins' Jump Stack and other ideas,
# see for example:
# https://pdfs.semanticscholar.org/f2b2/0d168acf38ff86305809a55ef2c5d6ebc787.pdf
# Further refinement in 2008 by the notion of "critical links", see
# "Cyclic reference counting" by Rafael Dueire Lins
# R.D. Lins / Information Processing Letters 109 (2008) 71–78

type
  GcPhase = enum
    doMarkRed,
    doScanGreen,
    doCollect

  JumpStack = object
    phase: GcPhase
    L: int
    a: array[200, (Cell, PNimType)]

proc add(j: var JumpStack; c: Cell; t: PNimType) =
  # XXX overflow handling here
  j.a[j.L] = (c, t)
  inc j.L

proc pop(j: var JumpStack): (Cell, PNimType) =
  result = j.a[j.L-1]
  dec j.L

proc trace(s: Cell; desc: PNimType; j: var JumpStack) {.inline.} =
  if desc.traceImpl != nil:
    var p = s +! sizeof(RefHeader)
    cast[TraceProc](desc.traceImpl)(p, addr(j))

proc free(s: Cell; desc: PNimType) {.inline.} =
  var p = s +! sizeof(RefHeader)
  when traceCollector:
    cprintf("[From ] %p %ld color %ld\n", s, s.rc shr rcShift, s.color)
  if desc.disposeImpl != nil:
    cast[DisposeProc](desc.disposeImpl)(p)
  nimRawDispose(p)

proc collect(s: Cell; desc: PNimType; j: var JumpStack) =
  if s.color == colRed:
    s.setColor colGreen
    trace(s, desc, j)
    free(s, desc)
    #cprintf("[Cycle free] %p %ld\n", s, s.rc shr rcShift)

proc markRed(s: Cell; desc: PNimType; j: var JumpStack) =
  if s.color != colRed:
    s.setColor colRed
    trace(s, desc, j)

proc scanGreen(s: Cell; desc: PNimType; j: var JumpStack) =
  s.setColor colGreen
  trace(s, desc, j)

proc nimTraceRef(p: pointer; desc: PNimType; env: pointer) {.compilerRtl.} =
  if p != nil:
    var t = head(p)
    var j = cast[ptr JumpStack](env)
    case j.phase
    of doMarkRed:
      when traceCollector:
        cprintf("[Cycle dec] %p %ld color %ld in jumpstack %ld\n", t, t.rc shr rcShift, t.color, t.rc and jumpStackFlag)
      dec t.rc, rcIncrement
      if (t.rc and not rcMask) >= 0 and (t.rc and jumpStackFlag) == 0:
        t.rc = t.rc or jumpStackFlag
        when traceCollector:
          cprintf("[Now in jumpstack] %p %ld color %ld in jumpstack %ld\n", t, t.rc shr rcShift, t.color, t.rc and jumpStackFlag)
        j[].add(t, desc)
      markRed(t, desc, j[])
    of doScanGreen:
      if t.color != colGreen: scanGreen(t, desc, j[])
      inc t.rc, rcIncrement
      when traceCollector:
        cprintf("[Cycle inc] %p %ld color %ld\n", t, t.rc shr rcShift, t.color)
    of doCollect:
      collect(t, desc, j[])

proc nimTraceRefDyn(p: pointer; env: pointer) {.compilerRtl.} =
  if p != nil:
    let desc = cast[ptr PNimType](p)[]
    nimTraceRef(p, desc, env)

proc scan(s: Cell; desc: PNimType; j: var JumpStack) =
  j.phase = doScanGreen
  when traceCollector:
    cprintf("[doScanGreen] %p %ld\n", s, s.rc shr rcShift)
  if (s.rc and not rcMask) >= 0:
    scanGreen(s, desc, j)
    s.setColor colYellow
  else:
    while j.L > 0:
      let (t, desc) = j.pop
      # not in jump stack anymore!
      t.rc = t.rc and not jumpStackFlag
      if t.color == colRed and (t.rc and not rcMask) >= 0:
        scanGreen(t, desc, j)
        t.setColor colYellow
        when traceCollector:
          cprintf("[jump stack] %p %ld\n", t, t.rc shr rcShift)
    j.phase = doCollect
    collect(s, desc, j)

proc traceCycle(s: Cell; desc: PNimType) {.noinline.} =
  when traceCollector:
    cprintf("[traceCycle] %p %ld\n", s, s.rc shr rcShift)
  var j: JumpStack
  j.phase = doMarkRed
  markRed(s, desc, j)
  scan(s, desc, j)

proc nimDecRefIsLastCyclicDyn(p: pointer): bool {.compilerRtl, inl.} =
  if p != nil:
    var cell = head(p)
    if (cell.rc and not rcMask) == 0:
      result = true
      #cprintf("[DESTROY] %p\n", p)
    else:
      dec cell.rc, rcIncrement
      if cell.color == colYellow:
        let desc = cast[ptr PNimType](p)[]
        traceCycle(cell, desc)
      # According to Lins it's correct to do nothing else here.
      #cprintf("[DeCREF] %p\n", p)

proc nimDecRefIsLastCyclicStatic(p: pointer; desc: PNimType): bool {.compilerRtl, inl.} =
  if p != nil:
    var cell = head(p)
    if (cell.rc and not rcMask) == 0:
      result = true
      #cprintf("[DESTROY] %p %s\n", p, desc.name)
    else:
      dec cell.rc, rcIncrement
      if cell.color == colYellow: traceCycle(cell, desc)
      #cprintf("[DeCREF] %p %s %ld\n", p, desc.name, cell.rc)

proc nimDecRefIsLast(p: pointer): bool {.compilerRtl, inl.} =
  if p != nil:
    var cell = head(p)
    if (cell.rc and not rcMask) == 0:
      result = true
      #cprintf("[DESTROY] %p\n", p)
    else:
      dec cell.rc, rcIncrement
      # According to Lins it's correct to do nothing else here.
      #cprintf("[DeCREF] %p\n", p)

proc GC_unref*[T](x: ref T) =
  ## New runtime only supports this operation for 'ref T'.
  if nimDecRefIsLast(cast[pointer](x)):
    # XXX this does NOT work for virtual destructors!
    `=destroy`(x[])
    nimRawDispose(cast[pointer](x))

proc GC_ref*[T](x: ref T) =
  ## New runtime only supports this operation for 'ref T'.
  if x != nil: nimIncRef(cast[pointer](x))

template GC_fullCollect* =
  ## Forces a full garbage collection pass. With ``--gc:arc`` a nop.
  discard

template setupForeignThreadGc* =
  ## With ``--gc:arc`` a nop.
  discard

template tearDownForeignThreadGc* =
  ## With ``--gc:arc`` a nop.
  discard

proc isObj(obj: PNimType, subclass: cstring): bool {.compilerRtl, inl.} =
  proc strstr(s, sub: cstring): cstring {.header: "<string.h>", importc.}

  result = strstr(obj.name, subclass) != nil

proc chckObj(obj: PNimType, subclass: cstring) {.compilerRtl.} =
  # checks if obj is of type subclass:
  if not isObj(obj, subclass): sysFatal(ObjectConversionError, "invalid object conversion")
