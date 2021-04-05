#
#
#            Nim's Runtime Library
#        (c) Copyright 2021 Nim contributors
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.

## C++11 like smart pointers. They always use the shared allocator.


when defined(nimExperimentalSmartptrs):
  import std/isolation


  type
    Deleter*[T] = proc (val: var T)
    UniquePtr*[T] = object
      ## Non copyable pointer to a value of type `T` with exclusive ownership.
      val: ptr T
      deleter: Deleter[T]

  proc `=destroy`*[T](p: var UniquePtr[T]) =
    if p.val != nil:
      if p.deleter != nil:
        p.deleter(p.val[])
      else:
        `=destroy`(p.val[])
      when compileOption("threads"):
        deallocShared(p.val)
      else:
        dealloc(p.val)

  proc `=copy`*[T](dest: var UniquePtr[T], src: UniquePtr[T]) {.error.}
    ## The copy operation is disallowed for `UniquePtr`, it
    ## can only be moved.

  proc newUniquePtr[T](val: sink Isolated[T], deleter: Deleter[T] = nil): UniquePtr[T] {.nodestroy.} =
    ## Returns a unique pointer which has exclusive ownership of the value.
    when compileOption("threads"):
      result.val = cast[ptr T](allocShared(sizeof(T)))
    else:
      result.val = cast[ptr T](alloc(sizeof(T)))
    # thanks to '.nodestroy' we don't have to use allocShared0 here.
    # This is compiled into a copyMem operation, no need for a sink
    # here either.
    result.val[] = val.extract
    result.deleter = deleter
    # no destructor call for 'val: sink T' here either.

  template newUniquePtr*[T](val: T, deleter: Deleter[T] = nil): UniquePtr[T] =
    ## Returns a unique pointer which has exclusive ownership of the value.
    newUniquePtr(isolate(val), deleter)

  proc get*[T](p: UniquePtr[T]): var T {.inline.} =
    ## Returns a mutable view of the internal value of `p`.
    when compileOption("boundChecks"):
      doAssert(p.val != nil, "deferencing nil unique pointer")
    p.val[]

  proc isNil*[T](p: UniquePtr[T]): bool {.inline.} =
    p.val == nil

  proc `[]`*[T](p: UniquePtr[T]): var T {.inline.} =
    p.get

  proc `$`*[T](p: UniquePtr[T]): string {.inline.} =
    if p.val == nil: "(nil)"
    else: "(" & $p.val[] & ")"

  #------------------------------------------------------------------------------

  type
    SharedPtr*[T] = object
      ## Shared ownership reference counting pointer.
      val: ptr tuple[value: T, atomicCounter: int]
      deleter: Deleter[T]

  proc `=destroy`*[T](p: var SharedPtr[T]) =
    if p.val != nil:
      if (when compileOption("threads"):
            atomicLoadN(addr p.val[].atomicCounter, ATOMIC_CONSUME) == 0 else:
            p.val[].atomicCounter == 0):
        if p.deleter != nil:
          p.deleter(p.val[])
        else:
          `=destroy`(p.val[])
        when compileOption("threads"):
          deallocShared(p.val)
        else:
          dealloc(p.val)
      else:
        when compileOption("threads"):
          discard atomicDec(p.val[].atomicCounter)
        else:
          dec(p.val[].atomicCounter)

  proc `=copy`*[T](dest: var SharedPtr[T], src: SharedPtr[T]) =
    if src.val != nil:
      when compileOption("threads"):
        discard atomicInc(src.val[].atomicCounter)
      else:
        inc(src.val[].atomicCounter)
    if dest.val != nil:
      `=destroy`(dest)
    dest.val = src.val

  proc newSharedPtr[T](val: sink Isolated[T], deleter: Deleter[T] = nil): SharedPtr[T] {.nodestroy.} =
    ## Returns a shared pointer which shares
    ## ownership of the object by reference counting.
    when compileOption("threads"):
      result.val = cast[typeof(result.val)](allocShared(sizeof(result.val[])))
    else:
      result.val = cast[typeof(result.val)](alloc(sizeof(result.val[])))
    result.val.atomicCounter = 0
    result.val.value = val.extract
    result.deleter = deleter

  template newSharedPtr*[T](val: T, deleter: Deleter[T] = nil): SharedPtr[T] =
    ## Overload of `newSharedPtr<#newSharedPtr,sinkIsolated[T]>`_.
    newSharedPtr(isolate(val), deleter)

  proc get*[T](p: SharedPtr[T]): var T {.inline.} =
    ## Returns a mutable view of the internal value of `p`.
    when compileOption("boundChecks"):
      doAssert(p.val != nil, "deferencing nil shared pointer")
    p.val.value

  proc isNil*[T](p: SharedPtr[T]): bool {.inline.} =
    p.val == nil

  proc `[]`*[T](p: SharedPtr[T]): var T {.inline.} =
    p.get

  proc `$`*[T](p: SharedPtr[T]): string {.inline.} =
    if p.val == nil: "(nil)"
    else: "(" & $p.val.value & ")"

  #------------------------------------------------------------------------------

  type
    ConstPtr*[T] = distinct SharedPtr[T]
      ## Distinct version of `SharedPtr[T]`, which doesn't allow mutating the underlying value.

  template newConstPtr*[T](val: T, deleter: Deleter[T] = nil): ConstPtr[T] =
    ## Similar to `newSharedPtr<#newSharedPtr,sinkIsolated[T]>`_, but the underlying value can't be mutated.
    newConstPtr(isolate(val), deleter)

  proc get*[T](p: ConstPtr[T]): lent T {.inline.} =
    ## Returns a immutable view of the internal value of `p`.
    when compileOption("boundChecks"):
      doAssert(SharedPtr[T](p).val != nil, "deferencing nil const pointer")
    SharedPtr[T](p).val.value

  proc isNil*[T](p: ConstPtr[T]): bool {.inline.} =
    SharedPtr[T](p).val == nil

  proc `[]`*[T](p: ConstPtr[T]): lent T {.inline.} =
    p.get

  proc `$`*[T](p: ConstPtr[T]): string {.inline.} =
    if SharedPtr[T](p).val == nil: "(nil)"
    else: "(" & $SharedPtr[T](p).val.value & ")"


  runnableExamples:
    import std/isolation

    block:
      var a1: UniquePtr[float]
      var a2 = newUniquePtr(0)

      assert $a1 == "(nil)"
      assert a1.isNil
      assert $a2 == "(0)"
      assert not a2.isNil
      assert a2[] == 0
      assert a2.get == 0

      # UniquePtr can't be copied but can be moved
      let a3 = move a2 # a2 will be destroyed

      assert $a2 == "(nil)"
      assert a2.isNil

      assert $a3 == "(0)"
      assert not a3.isNil
      assert a3[] == 0
      assert a3.get == 0

    block:
      var a1: SharedPtr[float]
      let a2 = newSharedPtr(0)
      let a3 = a2

      assert $a1 == "(nil)"
      assert a1.isNil
      assert $a2 == "(0)"
      assert not a2.isNil
      assert a2[] == 0
      assert a2.get == 0
      assert $a3 == "(0)"
      assert not a3.isNil
      assert a3[] == 0
      assert a3.get == 0

    block:
      var a1: ConstPtr[float]
      let a2 = newConstPtr(0)
      let a3 = a2

      assert $a1 == "(nil)"
      assert a1.isNil
      assert $a2 == "(0)"
      assert not a2.isNil
      assert a2[] == 0
      assert a2.get == 0
      assert $a3 == "(0)"
      assert not a3.isNil
      assert a3[] == 0
      assert a3.get == 0
