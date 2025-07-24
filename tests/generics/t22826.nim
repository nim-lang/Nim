import std/tables

var a: Table[string, float]

type Value*[T] = object
  table: Table[string, Value[T]]

discard toTable({"a": Value[float]()})