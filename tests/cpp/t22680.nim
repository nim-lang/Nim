discard """
  cmd: "nim cpp $file"
  output:'''
cppNZ.x = 123
cppNZInit.x = 123
inheritCpp.x = 123
inheritCppInit.x = 123
inheritCppCtor.x = 123
'''
"""
import std/sugar

{.emit:"""/*TYPESECTION*/
struct CppNonZero {
  int x = 123;
};
""".}

type
  CppNonZero {.importcpp, inheritable.} = object
    x: cint

  InheritCpp = object of CppNonZero

proc initCppNonZero: CppNonZero =
  CppNonZero()

proc initInheritCpp: InheritCpp =
  InheritCpp()

proc ctorInheritCpp: InheritCpp {.constructor.} =
  discard

proc main =
  var cppNZ: CppNonZero
  dump cppNZ.x

  var cppNZInit = initCppNonZero()
  dump cppNZInit.x

  var inheritCpp: InheritCpp
  dump inheritCpp.x

  var inheritCppInit = initInheritCpp()
  dump inheritCppInit.x

  var inheritCppCtor = ctorInheritCpp()
  dump inheritCppCtor.x

main()