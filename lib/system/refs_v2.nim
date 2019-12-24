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
  rcMask = 0b111

type
  RefHeader = object
    rc: int # the object header is now a single RC field.
            # we could remove it in non-debug builds for the 'owned ref'
            # design but this seems unwise.
  Cell = ptr RefHeader

template `+!`(p: pointer, s: int): pointer =
  cast[pointer](cast[int](p) +% s)

template `-!`(p: pointer, s: int): pointer =
  cast[pointer](cast[int](p) -% s)

template head(p: pointer): Cell =
  cast[Cell](cast[int](p) -% sizeof(RefHeader))

const
  traceCollector = defined(traceArc)

var allocs*: int

proc nimNewObj(size: int): pointer {.compilerRtl.} =
  let s = size + sizeof(RefHeader)
  when defined(nimscript):
    discard
  elif defined(useMalloc):
    var orig = c_malloc(cuint s)
    nimZeroMem(orig, s)
    result = orig +! sizeof(RefHeader)
  elif compileOption("threads"):
    result = allocShared0(s) +! sizeof(RefHeader)
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
    elif compileOption("threads"):
      deallocShared(p -! sizeof(RefHeader))
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

when defined(gcOrc):
  include cyclicrefs_v2

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
