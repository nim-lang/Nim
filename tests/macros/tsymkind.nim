
# Test `NimSymKind` and related procs.

import std/macros

# A package symbol can't be directly referenced, so this macro will return it.
macro getPackageSym(sym: typed): NimNode =
  getPackage(sym)

# these are used in tests below
method someMethod(n: NimNode) = discard
converter someConverter(a: char): byte = discard
type Obj = object
  field: int

block test_symKind:
  macro kind(sym: typed): NimSymKind =
     newLit(symKind(sym))
  template checkKind(sym) {.dirty.} =
    doAssert kind(sym) == member, $kind(sym)
  for member in NimSymKind:
    case member
    of nskUnknown: discard # how to test?
    of nskConditional: discard # how to test?
    of nskDynLib: discard # how to test?
    of nskParam:
      proc aProc(aParam = 0) =
        checkKind aParam
      aProc()
    of nskGenericParam: discard # how to test?
      # proc aGenericProc[T](aParam: T) =
      #   checkKind T
      # aGenericProc(0)
    of nskTemp: discard # how to test?
    of nskModule: checkKind macros
    of nskType: checkKind NimNode
    of nskVar:
      var someVar = 0
      checkKind someVar
    of nskLet:
      let someLet = 0
      checkKind someLet
    of nskConst: discard # how to test?
      # const someConst = 0
      # checkKind someConst
    of nskResult:
      proc aProc: int =
        checkKind result
      discard aProc()
    of nskProc: checkKind symKind
    of nskFunc: checkKind getModule
    of nskMethod: checkKind someMethod
    of nskIterator: checkKind items
    of nskConverter: checkKind someConverter
    of nskMacro: checkKind getPackageSym
    of nskTemplate: checkKind checkKind
    of nskField: discard # how to test?
    of nskEnumField: discard # how to test?
    of nskForVar: discard # how to test?
    of nskLabel: checkKind test_symKind
    of nskStub: discard # how to test?
    of nskPackage: discard # checkKind getPackageSym(macros)
    of nskAlias: discard # how to test?

block test_getModule:
  macro moduleName(sym: typed): string =
     getModule(sym).toStrLit
  doAssert moduleName(macros) == "macros"
  # doAssert moduleName(getPackageSym(macros)) == "macros"
  doAssert moduleName(getModule) == "macros", moduleName(getModule)

block test_getPackage:
  macro packageName(sym: typed): string =
     getPackage(sym).toStrLit
  # doAssert packageName(getPackageSym(macros)) == "stdlib"
  doAssert packageName(macros) == "stdlib"
  doAssert packageName(getModule) == "stdlib"
