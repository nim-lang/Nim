discard """
  targets: "c cpp js"
"""

import std/jsonutils
import std/json

proc testRoundtrip[T](t: T, expected: string) =
  let j = t.toJson
  doAssert $j == expected, $j
  doAssert j.jsonTo(T).toJson == j

import tables
import strtabs

type Foo = ref object
  id: int

proc `==`(a, b: Foo): bool =
  a.id == b.id

template fn() = 
  block: # toJson, jsonTo
    type Foo = distinct float
    testRoundtrip('x', """120""")
    when not defined(js):
      testRoundtrip(cast[pointer](12345)): """12345"""
      when nimvm:
        discard
        # bugs:
        # Error: unhandled exception: 'intVal' is not accessible using discriminant 'kind' of type 'TNode' [
        # Error: VM does not support 'cast' from tyNil to tyPointer
      else:
        testRoundtrip(pointer(nil)): """0"""
        testRoundtrip(cast[pointer](nil)): """0"""

    # causes workaround in `fromJson` potentially related to
    # https://github.com/nim-lang/Nim/issues/12282
    testRoundtrip(Foo(1.5)): """1.5"""

  block:
    testRoundtrip({"z": "Z", "y": "Y"}.toOrderedTable): """{"z":"Z","y":"Y"}"""
    when not defined(js): # pending https://github.com/nim-lang/Nim/issues/14574
      testRoundtrip({"z": (f1: 'f'), }.toTable): """{"z":{"f1":102}}"""

  block:
    testRoundtrip({"name": "John", "city": "Monaco"}.newStringTable): """{"mode":"modeCaseSensitive","table":{"city":"Monaco","name":"John"}}"""

  block: # complex example
    let t = {"z": "Z", "y": "Y"}.newStringTable
    type A = ref object
      a1: string
    let a = (1.1, "fo", 'x', @[10,11], [true, false], [t,newStringTable()], [0'i8,3'i8], -4'i16, (foo: 0.5'f32, bar: A(a1: "abc"), bar2: A.default))
    testRoundtrip(a):
      """[1.1,"fo",120,[10,11],[true,false],[{"mode":"modeCaseSensitive","table":{"y":"Y","z":"Z"}},{"mode":"modeCaseSensitive","table":{}}],[0,3],-4,{"foo":0.5,"bar":{"a1":"abc"},"bar2":null}]"""

  block:
    # edge case when user defined `==` doesn't handle `nil` well, eg:
    # https://github.com/nim-lang/nimble/blob/63695f490728e3935692c29f3d71944d83bb1e83/src/nimblepkg/version.nim#L105
    testRoundtrip(@[Foo(id: 10), nil]): """[{"id":10},null]"""

  block:
    type Foo = enum f1, f2, f3, f4, f5
    type Bar = enum b1, b2, b3, b4
    let a = [f2: b2, f3: b3, f4: b4]
    doAssert b2.ord == 1 # explains the `1`
    testRoundtrip(a): """[1,2,3]"""

static: fn()
fn()
