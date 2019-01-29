#
#
#            Nim's Runtime Library
#        (c) Copyright 2019 Nim contributors
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.

import allocators

type
  UniquePtr*[T] = object
    ## non copyable pointer to object T, exclusive ownership of the object is assumed
    val: ptr tuple[value: T, allocator: Allocator]

proc `=destroy`*[T](p: var UniquePtr[T]) =
  if p.val != nil:
    `=destroy`(p.val[])
    p.val.allocator.dealloc(p.val.allocator, p.val, sizeof(p.val[]))
    p.val = nil

proc `=`*[T](dest: var UniquePtr[T], src: UniquePtr[T]) {.error.}

proc `=sink`*[T](dest: var UniquePtr[T], src: UniquePtr[T]) {.inline.} =
  if dest.val != src.val:
    if dest.val != nil:
      dest.val = src.val

proc newUniquePtr*[T](val: sink T): UniquePtr[T] =
  let a = getSharedAllocator()
  result.val = cast[type(result.val)](a.alloc(a, sizeof(result.val[])))
  if AllocatorFlag.ZerosMem notin a.flags:
    reset(result.val[])
  result.val.value = val
  result.val.allocator = a

converter convertUniquePtrToObj*[T](p: UniquePtr[T]): var T {.inline.} =
  p.val.value

proc isNil*[T](p: UniquePtr[T]): bool {.inline.} =
  p.val == nil

proc get*[T](p: UniquePtr[T]): var T {.inline.} =
  when compileOption("boundChecks"):
    if p.val == nil:
      raise newException(ValueError, "deferencing nil unique pointer")
  p.val.value

proc `$`*[T](p: UniquePtr[T]): string {.inline.} =
  if p.val == nil: "UniquePtr[" & $T & "](nil)"
  else: "UniquePtr[" & $T & "](" & $p.val.value & ")"

#------------------------------------------------------------------------------

type
  SharedPtr*[T] = object
    ## shared ownership reference counting pointer
    val: ptr tuple[value: T, atomicCounter: int, allocator: Allocator]

proc `=destroy`*[T](p: var SharedPtr[T]) =
  if p.val != nil:
    let c = atomicDec(p.val[].atomicCounter)
    if c == 0:
      `=destroy`(p.val[])
      p.val.allocator.dealloc(p.val.allocator, p.val, sizeof(p.val[]))
    p.val = nil

proc `=sink`*[T](dest: var SharedPtr[T], src: SharedPtr[T]) {.inline.} =
  if dest.val != src.val:
    if dest.val != nil:
      `=destroy`(dest)
    dest.val = src.val

proc `=`*[T](dest: var SharedPtr[T], src: SharedPtr[T]) =
  if dest.val != src.val:
    if dest.val != nil:
      `=destroy`(dest)
    if src.val != nil:
      discard atomicInc(src.val[].atomicCounter)
      dest.val = src.val

proc newSharedPtr*[T](val: sink T): SharedPtr[T] =
  let a = getSharedAllocator()
  result.val = cast[type(result.val)](a.alloc(a, sizeof(result.val[])))
  if AllocatorFlag.ZerosMem notin a.flags:
    reset(result.val[])  
  result.val.value = val
  result.val.atomicCounter = 1
  result.val.allocator = a

converter convertSharedPtrToObj*[T](p: SharedPtr[T]): var T {.inline.} =
  p.val.value

proc isNil*[T](p: SharedPtr[T]): bool {.inline.} =
  p.val == nil

proc get*[T](p: SharedPtr[T]): var T {.inline.} =
  when compileOption("boundChecks"):
    if p.val == nil:
      raise newException(ValueError, "deferencing nil shared pointer")
  p.val.value

proc `$`*[T](p: SharedPtr[T]): string {.inline.} =
  if p.val == nil: "SharedPtr[" & $T & "](nil)"
  else: "SharedPtr[" & $T & "](" & $p.val.value & ")"

#------------------------------------------------------------------------------

type
  ConstPtr*[T] = distinct SharedPtr[T]
    ## distinct version of referencing counting smart pointer SharedPtr[T], 
    ## which doesn't allow mutating underlying object

proc newConstPtr*[T](val: sink T): ConstPtr[T] =
  ConstPtr[T](newSharedPtr(val))

converter convertConstPtrToObj*[T](p: ConstPtr[T]): lent T {.inline.} =
  p.val.value

proc isNil*[T](p: ConstPtr[T]): bool {.inline.} =
  p.val == nil

proc get*[T](p: ConstPtr[T]): lent T {.inline.} =
  when compileOption("boundChecks"):
    if p.val == nil:
      raise newException(ValueError, "deferencing nil const pointer")
  p.val.value

proc `$`*[T](p: ConstPtr[T]): string {.inline.} =
  if p.val == nil: "ConstPtr[" & $T & "](nil)"
  else: "ConstPtr[" & $T & "](" & $p.val.value & ")"

when isMainModule:
  import unittest

  test "UniquePtr[T] test":
    var a1: UniquePtr[float]
    let a2 = newUniquePtr(0)
    check: 
      $a1 == "ConstPtr[float](nil)"
      a1.isNil == true
      $a2 == "ConstPtr[int](0)"
      a2.isNil == false

  test "SharedPtr[T] test":      
    let a = newSharedPtr(0)

  test "ConstPtr[T] test":
    let a = newConstPtr(0)

