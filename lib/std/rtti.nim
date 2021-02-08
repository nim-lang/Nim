when defined nimExperimentalTypeInfoCore:
  import std/private/hti

  export PNimType

  when defined(nimV2):
    type
      TNimTypeV2 {.compilerproc.} = object
        destructor*: pointer
        size*: int
        align*: int
        name*: cstring
        traceImpl*: pointer
        disposeImpl*: pointer
        typeInfoV1*: pointer # for backwards compat, usually nil (is really a `PNimType`)
      PNimTypeV2* = ptr TNimTypeV2
      PNimTypeAlt* = PNimTypeV2
  else:
    type
      PNimTypeAlt* = PNimType

  proc getDynamicTypeInfoImpl[T](x: T): PNimTypeAlt {.magic: "GetDynamicTypeInfo", noSideEffect, locks: 0.}

  proc getDynamicTypeInfo*[T](x: T): PNimTypeAlt =
    ## Returns the dynamic type of `x`, which is an implementation defined runtime
    ## representation of the type of `x`. If `T` is `ref|ptr`, x will first be dereferenced
    ## unless `x == nil`.
    runnableExamples("-d:nimExperimentalTypeInfoCore"):
      type
        Base = ref object of RootObj
        Sub = ref object of Base
      var a: Base = Sub()
      assert a.getDynamicTypeInfo == Sub().getDynamicTypeInfo
      assert a[].getDynamicTypeInfo == Sub().getDynamicTypeInfo
      assert 0.getDynamicTypeInfo.size == int.sizeof
      assert Base(nil).getDynamicTypeInfo == nil
    runnableExamples("-d:nimTypeNames -d:nimExperimentalTypeInfoCore"):
      type
        Base = ref object of RootObj
        Sub = object of Base
        PSub = ref Sub
      var a: Base = PSub()
      # `name` is only available for `-d:nimTypeNames` for `gc:refc`
      # `name` is implementation defined for `gc:arc|orc`.
      assert a.getDynamicTypeInfo.name == "Sub"
      assert Base().getDynamicTypeInfo.name == "Base:ObjectType" # implementation defined
    when T is ref|ptr:
      if x != nil: 
        result = getDynamicTypeInfoImpl(x[])
    else:
      result = getDynamicTypeInfoImpl(x)
