import std/typetraits

type Foo* = distinct string

converter toBase*(headers: var Foo): var string =
  headers.distinctBase

proc bar*(headers: var Foo) =
  for x in headers: discard
    
