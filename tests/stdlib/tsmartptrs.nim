discard """
  targets: "c cpp"
  matrix: "--gc:refc; --gc:orc; --gc:orc --threads:on"
"""


import std/[unittest, smartptrs, isolation]

block: # UniquePtr[T] test
  var a1: UniquePtr[float]
  var a2 = newUniquePtr(isolate(0))

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
  let a2 = newSharedPtr(isolate(0))
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
  let a2 = newConstPtr(isolate(0))
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
