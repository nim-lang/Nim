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

type
  TNimNode {.compilerProc.} = object # to keep the code generator simple
  DestructorProc = proc (p: pointer) {.nimcall, benign.}
  TNimType {.compilerProc.} = object
    destructor: pointer
    size: int
    name: cstring
  PNimType = ptr TNimType

  RefHeader = object
    rc: int # the object header is now a single RC field.
            # we could remove it in non-debug builds but this seems
            # unwise.

template `+!`(p: pointer, s: int): pointer =
  cast[pointer](cast[int](p) +% s)

template `-!`(p: pointer, s: int): pointer =
  cast[pointer](cast[int](p) -% s)

template head(p: pointer): ptr RefHeader =
  cast[ptr RefHeader](cast[int](p) -% sizeof(RefHeader))

var allocs*: int

proc nimNewObj(size: int): pointer {.compilerRtl.} =
  let s = size + sizeof(RefHeader)
  when defined(nimscript):
    discard
  elif defined(useMalloc):
    result = c_malloc(s) +! sizeof(RefHeader)
    nimZeroMem(result, s)
  else:
    result = alloc0(s) +! sizeof(RefHeader)
  inc allocs

proc nimDecWeakRef(p: pointer) {.compilerRtl.} =
  dec head(p).rc

proc nimIncWeakRef(p: pointer) {.compilerRtl.} =
  inc head(p).rc

proc nimRawDispose(p: pointer) {.compilerRtl.} =
  when not defined(nimscript):
    if head(p).rc != 0:
      cstderr.rawWrite "[FATAL] dangling references exist\n"
      quit 1
    when defined(useMalloc):
      c_free(p -! sizeof(RefHeader))
    else:
      dealloc(p -! sizeof(RefHeader))
    if allocs > 0:
      dec allocs
    else:
      cstderr.rawWrite "[FATAL] unpaired dealloc\n"
      quit 1

proc nimDestroyAndDispose(p: pointer) {.compilerRtl.} =
  let d = cast[ptr PNimType](p)[].destructor
  if d != nil: cast[DestructorProc](d)(p)
  nimRawDispose(p)

proc isObj(obj: PNimType, subclass: cstring): bool {.compilerproc.} =
  proc strstr(s, sub: cstring): cstring {.header: "<string.h>", importc.}

  result = strstr(obj.name, subclass) != nil

proc chckObj(obj: PNimType, subclass: cstring) {.compilerproc.} =
  # checks if obj is of type subclass:
  if not isObj(obj, subclass): sysFatal(ObjectConversionError, "invalid object conversion")
