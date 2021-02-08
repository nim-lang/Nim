discard """
  matrix: "-d:nimExperimentalTypeInfoCore -d:nimTypeNames; -d:nimExperimentalTypeInfoCore -d:nimTypeNames --gc:arc"
"""

import std/[rtti,unittest,strutils]

proc main =
  block: # getDynamicTypeInfo
    type
      Base = object of RootObj
      PBase = ref Base
      Sub1 = ref object of Base
        x1: array[10, float]
    var a: PBase = Sub1()
    block:
      let t = a.getDynamicTypeInfo
      check t.size == 88
      when defined(nimV2):
        # "|compiler.trtti.Sub1:ObjectType|compiler.trtti.Base:ObjectType|RootObj|"
        check "Sub1:ObjectType" in $t.name
      else: check t.name == "Sub1:ObjectType"
      let t2 = a[].getDynamicTypeInfo
      check t2 == t
    block:
      a = PBase()
      let t = a.getDynamicTypeInfo
      check t.size == 8
      when defined(nimV2):
        check "Base" in $t.name
      else: check t.name == "Base"
main()
