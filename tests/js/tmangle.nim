discard """
  output: '''true
true
true
true'''
"""

# Test not mangled:
block:
  type T = object
    a: int
    b: cstring
  proc test(): bool =
    let obj = T(a: 11, b: "foo")
    {. emit: [result, " = (", obj, ".a == 11);"] .}
    {. emit: [result, " = ", result, " && (", obj, ".b == \"foo\");"] .}
  echo test()

# Test indirect (fields in genAddr):
block:
  type T = object
    a: int
    b: cstring
  var global = T(a: 11, b: "foo")
  proc test(): bool =
    var obj = T(a: 11, b: "foo")
    {. emit: [result, " = (", obj.addr[], "[0].a == 11);"] .}
    {. emit: [result, " = ", result, " && (", obj.addr[], "[0].b == \"foo\");"] .}
    {. emit: [result, " = ", result, " && (", global, "[0].a == 11);"] .}
    {. emit: [result, " = ", result, " && (", global, "[0].b == \"foo\");"] .}
  echo test()

# Test addr of field:
block:
  type T = object
    a: int
    b: cstring
  proc test(): bool =
    var obj = T(a: 11, b: "foo")
    result = obj.a.addr[] == 11
    result = result and obj.b.addr[] == "foo".cstring
  echo test()

# Test importc / exportc fields:
block:
  type T = object
    a: int
    b {. importc: "notB" .}: cstring
  type U = object
    a: int
    b {. exportc: "notB" .}: cstring
  proc test(): bool =
    var
      obj1 = T(a: 11, b: "foo")
      obj2 = U(a: 11, b: "foo")
    {. emit: [result, " = (", obj1, ".a == 11);"] .}
    {. emit: [result, " = ", result, " && (", obj1, ".notB == \"foo\");"] .}
    {. emit: [result, " = (", obj2, ".a == 11);"] .}
    {. emit: [result, " = ", result, " && (", obj2, ".notB == \"foo\");"] .}
  echo test()
