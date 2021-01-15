when defined(js):
  type
    ArrayBuffer* = ref object of JsRoot
    Float64Array* = ref object of JsRoot
    Uint32Array* = ref object of JsRoot

  func newArrayBuffer*(n: int): ArrayBuffer {.importjs: "new ArrayBuffer(#)".}
  func newFloat64Array*(buffer: ArrayBuffer): Float64Array {.importjs: "new Float64Array(#)".}
  func newUint32Array*(buffer: ArrayBuffer): Uint32Array {.importjs: "new Uint32Array(#)".}

  func `[]`*(arr: Uint32Array, i: int): uint32 {.importjs: "#[#]".}
  func `[]=`*(arr: Float64Array, i: int, v: float) {.importjs: "#[#] = #".}
