when defined(js):
  import std/jsbigints

  type
    ArrayBuffer* = ref object of JsRoot
    Float64Array* = ref object of JsRoot
    Uint32Array* = ref object of JsRoot
    BigUint64Array* = ref object of JsRoot

  func newArrayBuffer*(n: int): ArrayBuffer {.importjs: "new ArrayBuffer(#)".}
  func newFloat64Array*(buffer: ArrayBuffer): Float64Array {.importjs: "new Float64Array(#)".}
  func newUint32Array*(buffer: ArrayBuffer): Uint32Array {.importjs: "new Uint32Array(#)".}
  func newBigUint64Array*(buffer: ArrayBuffer): BigUint64Array {.importjs: "new BigUint64Array(#)".}

  func `[]`*(arr: Uint32Array, i: int): uint32 {.importjs: "#[#]".}
  func `[]`*(arr: BigUint64Array, i: int): JsBigInt {.importjs: "#[#]".}
  func `[]=`*(arr: Float64Array, i: int, v: float) {.importjs: "#[#] = #".}


  proc hasJsBigInt*(): bool =
    asm """`result` = typeof BigInt != 'undefined'"""

  proc hasBigUint64Array*(): bool =
    asm """`result` = typeof BigUint64Array != 'undefined'"""
