discard """
  output: '''true
true
true
true
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
    {. emit: [result, " = (", obj.addr[], ".a == 11);"] .}
    {. emit: [result, " = ", result, " && (", obj.addr[], ".b == \"foo\");"] .}
    {. emit: [result, " = ", result, " && (", global, ".a == 11);"] .}
    {. emit: [result, " = ", result, " && (", global, ".b == \"foo\");"] .}
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

# Test reserved words:
block:
  type T = ref object
    `if`: int
    `for`: int
    `==`: cstring
    `&&`: cstring
  proc test(): bool =
    var
      obj1 = T(`if`: 11, `for`: 22, `==`: "foo", `&&`: "bar")
      obj2: T
    new obj2 # Test behaviour for createRecordVarAux.
    result = obj1.`if` == 11
    result = result and obj1.addr[].`for` == 22
    result = result and obj1.`==` == "foo".cstring
    result = result and obj1.`&&`.addr[] == "bar".cstring
    result = result and obj2.`if` == 0
    result = result and obj2.`for` == 0
    result = result and obj2.`==`.isNil
    result = result and obj2.`&&`.isNil
  echo test()

# Test codegen for fields with uppercase letters:
block:
  type MyObj = object
    mField: int
  proc test(): bool =
    var a: MyObj
    var b = a
    result = b.mField == 0
  echo test()

# Test tuples
block:
  type T = tuple
    a: int
    b: int
  proc test(): bool =
    var a: T = (a: 1, b: 1)
    result = a.a == 1
    result = result and a.b == 1
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
