discard """
  targets: "c cpp"
  disabled: "freebsd"
  matrix: "--gc:refc -d:nimExperimentalSmartptrs; --gc:orc -d:nimExperimentalSmartptrs"
"""


import std/[unittest, smartptrs, isolation]

block: # UniquePtr[T] test
  var a1: UniquePtr[float]
  var a2 = newUniquePtr(0)

  check:
    $a1 == "(nil)"
    a1.isNil
    $a2 == "(0)"
    not a2.isNil
    a2[] == 0

  let a3 = move a2

  check:
    $a2 == "(nil)"
    a2.isNil

    $a3 == "(0)"
    not a3.isNil
    a3[] == 0

block: # SharedPtr[T] test
  var a1: SharedPtr[float]
  let a2 = newSharedPtr(0)
  let a3 = a2
  check:
    $a1 == "(nil)"
    a1.isNil
    $a2 == "(0)"
    not a2.isNil
    a2[] == 0
    $a3 == "(0)"
    not a3.isNil
    a3[] == 0

block: # ConstPtr[T] test
  var a1: ConstPtr[float]
  let a2 = newConstPtr(0)
  let a3 = a2

  check:
    $a1 == "(nil)"
    a1.isNil
    $a2 == "(0)"
    not a2.isNil
    a2[] == 0
    $a3 == "(0)"
    not a3.isNil
    a3[] == 0

block: # UniquePtr[T] test
  var a1 = newUniquePtr("1234")

  proc hello(x: string) =
    doAssert x == "1234"

  hello(a1.get)

block: # SharedPtr[T] test
  let x = 5.0
  let a1 = newSharedPtr(x)
  let a2 = a1

  proc hello(x: float) =
    doAssert x == 5.0

  hello(a2.get)

block: # SharedPtr[T] test
  let x = 5.0
  let a1 = newConstPtr(x)
  let a2 = a1

  proc hello(x: float) =
    doAssert x == 5.0

  hello(a2.get)
