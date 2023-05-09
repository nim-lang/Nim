discard """
  action: compile
"""

{.experimental: "strictFuncs".}

func sortedFake1[T](a: openArray[T]): seq[T] =
  for i in 0 .. a.high: result.add a[i]
func sortedFake2[T](a: openArray[T]): seq[T] =
  result = newSeq[T](a.len)
  for i in 0 .. a.high: result[i] = a[i]
type Foo1 = object
type Foo2 = ref object
block:
  let a1 = sortedFake1([Foo1()]) # ok
  let a2 = sortedFake1([Foo2()]) # ok
block:
  let a1 = sortedFake2([Foo1()]) # ok
  let a2 = sortedFake2([Foo2()]) # error: Error: 'sortedFake2' can have side effects


import std/sequtils
type Foob = ref object
  x: int
let a1 = zip(@[1,2], @[1,2]) # ok
let a2 = zip(@[Foob(x: 1)], @[Foob(x: 2)]) # error in 1.6.0 RC2, but not 1.4.x


# bug #20863
type
  Fooc = ref object

func twice(foo: Fooc) =
  var a = newSeq[Fooc](2)
  a[0] = foo # No error.
  a[1] = foo # Error: 'twice' can have side effects.

let foo = Fooc()
twice(foo)

# bug #17387
import json

func parseColumn(columnNode: JsonNode) =
  let columnName = columnNode["name"].str

parseColumn(%*{"a": "b"})

type
  MyTable = object
    data: seq[int]

  JsonNode3 = ref object
    fields: MyTable

proc `[]`(t: MyTable, key: string): int =
  result = t.data[0]

proc `[]`(x: JsonNode3, key: string): int =
  result = x.fields[key]

func parseColumn(columnNode: JsonNode3) =
  var columnName = columnNode["test"]

parseColumn(JsonNode3())
