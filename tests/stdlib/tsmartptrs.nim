import std/[unittest, smartptrs, isolation]

block: # UniquePtr[T] test
  var a1: UniquePtr[float]
  var a2 = newUniquePtr(isolate(0))

  check:
    $a1 == "UniquePtr[float](nil)"
    a1.isNil == true
    $a2 == "UniquePtr[int](0)"
    a2.isNil == false
    a2[] == 0

  let a3 = move a2

  check:
    $a2 == "UniquePtr[int](nil)"
    a2.isNil == true

    $a3 == "UniquePtr[int](0)"
    a3.isNil == false
    a3[] == 0

block: # SharedPtr[T] test
  var a1: SharedPtr[float]
  let a2 = newSharedPtr(isolate(0))
  let a3 = a2
  check:
    $a1 == "SharedPtr[float](nil)"
    a1.isNil == true
    $a2 == "SharedPtr[int](0)"
    a2.isNil == false
    a2[] == 0
    $a3 == "SharedPtr[int](0)"
    a3.isNil == false
    a3[] == 0

block: # ConstPtr[T] test
  var a1: ConstPtr[float]
  let a2 = newConstPtr(isolate(0))
  let a3 = a2

  check:
    $a1 == "ConstPtr[float](nil)"
    a1.isNil == true
    $a2 == "ConstPtr[int](0)"
    a2.isNil == false
    a2[] == 0
    $a3 == "ConstPtr[int](0)"
    a3.isNil == false
    a3[] == 0
