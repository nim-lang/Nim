discard """
  cmd: "nim cpp $file"
  output:'''
cppNZ.x = 123
cppNZInit.x = 123
hascpp.cppnz.x = 123
hasCppInit.cppnz.x = 123
hasCppCtor.cppnz.x = 123
'''
"""
{.emit:"""/*TYPESECTION*/
struct CppNonZero {
  int x = 123;
};
""".}

import sugar
type
  CppNonZero {.importcpp, inheritable.} = object
    x: cint

  HasCpp = object
    cppnz: CppNonZero

proc initCppNonZero: CppNonZero =
  CppNonZero()

proc initHasCpp: HasCpp =
  HasCpp()

proc ctorHasCpp: HasCpp {.constructor.} =
  discard

proc main =
  var cppNZ: CppNonZero
  dump cppNZ.x

  var cppNZInit = initCppNonZero()
  dump cppNZInit.x

  var hascpp: HasCpp
  dump hascpp.cppnz.x

  var hasCppInit = initHasCpp()
  dump hasCppInit.cppnz.x

  var hasCppCtor = ctorHasCpp()
  dump hasCppCtor.cppnz.x

main()