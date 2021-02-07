import std/private/hti

export PNimType

when defined(nimV2):
  type
    TNimTypeV2 {.compilerproc.} = object
      destructor: pointer
      size*: int
      align: int
      name*: cstring
      traceImpl: pointer
      disposeImpl: pointer
      typeInfoV1*: pointer # for backwards compat, usually nil (is really a `PNimType`)
    PNimTypeV2 = ptr TNimTypeV2
    PNimTypeAlt = PNimTypeV2
else:
  PNimTypeAlt = PNimType

proc getDynamicTypeInfoImpl[T](x: T): PNimTypeAlt {.magic: "GetDynamicTypeInfo", noSideEffect, locks: 0.}

proc getDynamicTypeInfo*[T](x: T): PNimTypeAlt =
  when T is ref:
    if x != nil: 
      result = getDynamicTypeInfoImpl(x[])
  else:
    result = getDynamicTypeInfoImpl(x)
