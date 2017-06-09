## View is a type representing a range of elements in an array. In can be thought as a pointer plus a size.
## View can be created to an arbitrary memory segment and can additionally keep a single ``ref`` object alive.
##
## This module defines views and several helper operations on them. All functions in this module (except for unsafe version of ``initView``) are designed to be memory safe (e.g. they raise exception on out-of-bounds accesses).
import strutils

const
  needGcKeep = not (compileOption("gc", "boehm") or compileOption("gc", "none"))

type
  View*[T] = object
    data: ptr T
    length: int
    when needGcKeep:
      gcKeep: RootRef

  ByteView* = View[byte]

proc initView*[T; R: ref](data: ptr T, len: int, gcKeep: R): View[T] =
  ## Creates a new view pointing, starting at ``data`` with length ``len``.
  ##
  ## ``gcKeep`` should be a pointer to the underlying GC objects that contains these items.
  when needGcKeep:
    return View[T](data: data, length: len, gcKeep: cast[RootRef](gcKeep))
  else:
    return View[T](data: data, length: len)

proc initView*[T](data: ptr T, len: int): View[T] =
  ## Creates a new view, starting at ``data`` with length ``len``.
  ##
  ## You need to ensure that data pointed by this view is not garbage collected while using the view.
  when needGcKeep:
    return View[T](data: data, length: len, gcKeep: nil)
  else:
    return View[T](data: data, length: len)

proc initEmptyView*[T](typ: typedesc[T]): View[T] =
  ## Creates a view of length zero.
  return initView[T](nil, 0)

proc initView[T](s: ref seq[T]): View[T] =
  ## Returns a view into a sequence.
  if s[].len == 0:
    initEmptyView(T)
  else:
    initView(addr s[0], s[].len, gcKeep=s)

proc newView*[T](s: seq[T]): View[T] =
  ## Copies a sequence and returns a new view pointing into the copy.
  let copied = new(seq[T])
  copied[] = s
  result = initView(copied)

proc newView*[T](typ: typedesc[T], len: int): View[T] =
  ## Create uninitialized view of length ``len``.
  let s = new(seq[T])
  s[] = newSeq[T](len)
  result = initView(s)

proc isNil*(v: View): bool =
  return v.len == 0

proc len*(v: View): int =
  return v.length

proc data*[T](v: View[T]): ptr T =
  return v.data

proc ptrAdd[T](p: pointer, i: int): ptr T =
  return cast[ptr T](cast[int](p) +% (i * sizeof(T)))

proc `[]`*[T](v: View[T], i: int): var T =
  doAssert(i >= 0 and i < v.len)
  return ptrAdd[T](v.data, i)[]

proc `[]=`*[T](v: View[T], i: int, val: T) =
  doAssert(i >= 0 and i < v.len)
  ptrAdd[T](v.data, i)[] = val

proc slice*[T](v: View[T], start: int, len: int): View[T] =
  ## Returns a subview starting at ``v[start]`` with length ``len``.
  if len != 0:
    doAssert(start < v.len and start >= 0)
    doAssert(len <= v.len)
    doAssert(start + len <= v.len)
    doAssert(len >= 0)
    result.data = ptrAdd[T](v.data, start)
    result.length = len
    when needGcKeep:
      result.gcKeep = v.gcKeep
  else:
    result.data = nil
    result.length = 0

proc slice*[T](v: View[T], start: int): View[T] =
  ## Returns a subview starting at ``v[start]`` with length ``v.len - start``.
  assert start <= v.len and start >= 0
  return v.slice(start, v.len - start)

# Types that may be safely copied using ``copyMem``.
type ScalarType = uint8 | uint16 | uint32 | uint64 | int8 | int16 | int32 | int64 | float32 | float64 | byte | char | enum

proc copyFrom*[T](dst: View[T], src: View[T]) =
  ## Copies content of ``src`` into ``dst``. ``dst.len`` needs to be larger than ``src.len``.
  doAssert(dst.len >= src.len)
  when T is ScalarType:
    copyMem(dst.data, src.data, src.len * sizeof(T))
  else:
    for i in 0..<src.len:
      ptrAdd[T](dst.data, i)[] = ptrAdd[T](src.data, i)[]

proc copyTo*[T](src: View[T], dst: View[T]) =
  ## Copies content of ``src`` into ``dst``. ``dst.len`` needs to be larger than ``src.len``.
  dst.copyFrom(src)

proc copyAsSeq*[T](src: View[T]): seq[T] =
  ## Copies content of ``src`` into a new sequence and returns it.
  result = newSeq[T](src.len)
  src.copyTo(initView(addr result[0], result.len))

iterator items*[T](src: View[T]): T =
  ## Iterate over the content of ``src``.
  for i in 0..<src.len:
    yield src[i]

proc `$`*[T](v: View[T]): string =
  return "View[$1, $2]" % [$v.len, $v.copyAsSeq]

# ByteView

converter toByteView*(s: View[char]): ByteView =
  # View[char] and View[byte] are mostly the same thing
  return initView(cast[ptr byte](s.data), s.len, when needGcKeep: s.gcKeep else: nil)

proc initView(s: ref string): ByteView =
  ## Returns a view into a string.
  if s[].len == 0:
    initEmptyView(byte)
  else:
    initView(addr s[0], s[].len, gcKeep=s)

proc newView*(s: string): ByteView =
  ## Copies a string and returns a new view pointing into the copy.
  let copied = new(string)
  copied[] = s
  result = initView(copied)

proc copyAsString*(src: ByteView): string =
  ## Copies content of ``src`` into a new string and returns it.
  result = newString(src.len)
  src.copyTo(initView(addr result[0], result.len))
