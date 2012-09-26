import unittest, typetraits

type 
  TFoo[T, U] = object
    x: T
    y: U

proc getTypeName(t: typedesc): string = t.name

proc foo(T: typedesc[float], a: expr): string =
  result = "float " & $(a.len > 5)

proc foo(T: typedesc[TFoo], a: int): string =
  result = "TFoo "  & $(a)

proc foo(T: typedesc[int or bool]): string =
  var a: T
  a = 10
  result = "int or bool " & ($a)

template foo(T: typedesc[seq]): expr = "seq"

test "types can be used as proc params":
  # XXX: `check` needs to know that TFoo[int, float] is a type and 
  # cannot be assigned for a local variable for later inspection
  check ((string.getTypeName == "string"))
  check ((getTypeName(int) == "int"))
  
  check ((foo(TFoo[int, float], 1000) == "TFoo 1000"))
  
  var f = 10.0
  check ((foo(float, "long string") == "float true"))
  check ((foo(type(f), [1, 2, 3]) == "float false"))
  
  check ((foo(int) == "int or bool 10"))

  check ((foo(seq[int]) == "seq"))
  check ((foo(seq[TFoo[bool, string]]) == "seq"))

when false:
  proc foo(T: typedesc[seq], s: T) = nil

