when defined(js):
  import std/jsbigints

  type
    ArrayBuffer* = ref object of JsRoot
    Float64Array* = ref object of JsRoot
    Uint32Array* = ref object of JsRoot
    Uint8Array* = ref object of JsRoot
    BigUint64Array* = ref object of JsRoot


  func newArrayBuffer*(n: int): ArrayBuffer {.importjs: "new ArrayBuffer(#)".}
  func newFloat64Array*(buffer: ArrayBuffer): Float64Array {.importjs: "new Float64Array(#)".}
  func newUint32Array*(buffer: ArrayBuffer): Uint32Array {.importjs: "new Uint32Array(#)".}
  func newBigUint64Array*(buffer: ArrayBuffer): BigUint64Array {.importjs: "new BigUint64Array(#)".}


  func newUint8Array*(n: int): Uint8Array {.importjs: "new Uint8Array(#)".}

  func `[]`*(arr: Uint32Array, i: int): uint32 {.importjs: "#[#]".}
  func `[]`*(arr: Uint8Array, i: int): uint8 {.importjs: "#[#]".}
  func `[]`*(arr: BigUint64Array, i: int): JsBigInt {.importjs: "#[#]".}
  func `[]=`*(arr: Float64Array, i: int, v: float) {.importjs: "#[#] = #".}


  proc jsTypeOf*[T](x: T): cstring {.importjs: "typeof(#)".}
  ## Returns the name of the JsObject's JavaScript type as a cstring.
  # xxx replace jsffi.jsTypeOf with this definition and add tests

  proc jsConstructorName*[T](a: T): cstring =
    asm """`result` = `a`.constructor.name"""

  proc hasJsBigInt*(): bool =
    asm """`result` = typeof BigInt != 'undefined'"""

  proc hasBigUint64Array*(): bool =
    asm """`result` = typeof BigUint64Array != 'undefined'"""

