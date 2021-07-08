discard """
  matrix: "--threads"
  targets: "c cpp"
  exitcode: 0
  disabled: false
"""
import std/smartptrs

block:
  var a1: UniquePtr[float]
  var a2 = newUniquePtr(0)

  assert $a1 == "nil"
  assert a1.isNil
  assert $a2 == "(val: 0)"
  assert not a2.isNil
  assert a2[] == 0

  # UniquePtr can't be copied but can be moved
  let a3 = move a2

  assert $a2 == "nil"
  assert a2.isNil

  assert $a3 == "(val: 0)"
  assert not a3.isNil
  assert a3[] == 0

block:
  var a1: SharedPtr[float]
  let a2 = newSharedPtr(0)
  let a3 = a2

  assert $a1 == "nil"
  assert a1.isNil
  assert $a2 == "(val: 0)"
  assert not a2.isNil
  assert a2[] == 0
  assert $a3 == "(val: 0)"
  assert not a3.isNil
  assert a3[] == 0

block:
  var a1: ConstPtr[float]
  let a2 = newConstPtr(0)
  let a3 = a2

  assert $a1 == "nil"
  assert a1.isNil
  assert $a2 == "(val: 0)"
  assert not a2.isNil
  assert a2[] == 0
  assert $a3 == "(val: 0)"
  assert not a3.isNil
  assert a3[] == 0

