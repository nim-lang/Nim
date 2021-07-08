#
#
#            Nim's Runtime Library
#        (c) Copyright 2021 Nim contributors
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.

## C++11 like smart pointers. They always use the shared allocator.
## Experimental API, subject to change.

when not compileOption("threads"):
  {.error: "Smartptrs requires --threads:on option.".}

import std/isolation

template checkNotNil(msg: typed) =
  when compileOption("boundChecks"):
    {.line.}:
      if p.isNil:
        raise newException(NilAccessDefect, msg)

type
  UniquePtr*[T] = object
    ## Non copyable pointer to a value of type `T` with exclusive ownership.
    val: ptr T

proc `=destroy`*[T](p: var UniquePtr[T]) =
  if p.val != nil:
    `=destroy`(p.val[])
    deallocShared(p.val)

proc `=copy`*[T](dest: var UniquePtr[T], src: UniquePtr[T]) {.error.}
  ## The copy operation is disallowed for `UniquePtr`, it
  ## can only be moved.

proc newUniquePtr[T](val: sink Isolated[T]): UniquePtr[T] {.nodestroy.} =
  ## Returns a unique pointer which has exclusive ownership of the value.
  result.val = cast[ptr T](allocShared(sizeof(T)))
  # thanks to '.nodestroy' we don't have to use allocShared0 here.
  # This is compiled into a copyMem operation, no need for a sink
  # here either.
  result.val[] = extract val
  # no destructor call for 'val: sink T' here either.

template newUniquePtr*[T](val: T): UniquePtr[T] =
  ## .. warning:: Using this template in a loop causes multiple evaluations of `val`.
  newUniquePtr(isolate(val))

proc newUniquePtrU*[T](t: typedesc[T]): UniquePtr[T] =
  ## Returns a unique pointer. It is not initialized,
  ## so reading from it before writing to it is undefined behaviour!
  result.val = cast[ptr T](allocShared(sizeof(T)))

proc isNil*[T](p: UniquePtr[T]): bool {.inline.} =
  p.val == nil

proc `[]`*[T](p: UniquePtr[T]): var T {.inline.} =
  ## Returns a mutable view of the internal value of `p`.
  checkNotNil("deferencing nil unique pointer")
  p.val[]

proc `[]=`*[T](p: UniquePtr[T], val: T) {.inline.} =
  checkNotNil("deferencing nil unique pointer")
  p.val[] = val

proc `$`*[T](p: UniquePtr[T]): string {.inline.} =
  if p.val == nil: "nil"
  else: "(val: " & $p.val[] & ")"

#------------------------------------------------------------------------------

type
  SharedPtr*[T] = object
    ## Shared ownership reference counting pointer.
    val: ptr tuple[value: T, atomicCounter: int]

proc `=destroy`*[T](p: var SharedPtr[T]) =
  if p.val != nil:
    if atomicLoadN(addr p.val[].atomicCounter, AtomicConsume) == 0:
      `=destroy`(p.val[])
      deallocShared(p.val)
    else:
      discard atomicDec(p.val[].atomicCounter)

proc `=copy`*[T](dest: var SharedPtr[T], src: SharedPtr[T]) =
  if src.val != nil:
    discard atomicInc(src.val[].atomicCounter)
  if dest.val != nil:
    `=destroy`(dest)
  dest.val = src.val

proc newSharedPtr[T](val: sink Isolated[T]): SharedPtr[T] {.nodestroy.} =
  ## Returns a shared pointer which shares
  ## ownership of the object by reference counting.
  result.val = cast[typeof(result.val)](allocShared(sizeof(result.val[])))
  result.val.atomicCounter = 0
  result.val.value = extract val

template newSharedPtr*[T](val: T): SharedPtr[T] =
  ## .. warning:: Using this template in a loop causes multiple evaluations of `val`.
  newSharedPtr(isolate(val))

proc newSharedPtrU*[T](t: typedesc[T]): SharedPtr[T] =
  ## Returns a shared pointer. It is not initialized,
  ## so reading from it before writing to it is undefined behaviour!
  result.val = cast[typeof(result.val)](allocShared(sizeof(result.val[])))
  result.val.atomicCounter = 0

proc isNil*[T](p: SharedPtr[T]): bool {.inline.} =
  p.val == nil

proc `[]`*[T](p: SharedPtr[T]): var T {.inline.} =
  checkNotNil("deferencing nil shared pointer")
  p.val.value

proc `[]=`*[T](p: SharedPtr[T], val: T) {.inline.} =
  checkNotNil("deferencing nil shared pointer")
  p.val.value = val

proc `$`*[T](p: SharedPtr[T]): string {.inline.} =
  if p.val == nil: "nil"
  else: "(val: " & $p.val.value & ")"

#------------------------------------------------------------------------------

type
  ConstPtr*[T] = distinct SharedPtr[T]
    ## Distinct version of `SharedPtr[T]`, which doesn't allow mutating the underlying value.

proc newConstPtr*[T](val: sink Isolated[T]): ConstPtr[T] =
  ## Similar to `newSharedPtr<#newSharedPtr,T>`_, but the underlying value can't be mutated.
  ConstPtr[T](newSharedPtr(val))

template newConstPtr*[T](val: T): ConstPtr[T] =
  ## .. warning:: Using this template in a loop causes multiple evaluations of `val`.
  newConstPtr(isolate(val))

proc isNil*[T](p: ConstPtr[T]): bool {.inline.} =
  SharedPtr[T](p).val == nil

proc `[]`*[T](p: ConstPtr[T]): lent T {.inline.} =
  ## Returns an immutable view of the internal value of `p`.
  checkNotNil("deferencing nil const pointer")
  SharedPtr[T](p).val.value

proc `[]=`*[T](p: ConstPtr[T], v: T) = {.error: "`ConstPtr` cannot be assigned.".}

proc `$`*[T](p: ConstPtr[T]): string {.inline.} =
  $SharedPtr[T](p)
