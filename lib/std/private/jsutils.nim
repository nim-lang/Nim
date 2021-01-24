when defined(js):
  type
    ArrayBuffer* = ref object of JsRoot
    Float64Array* = ref object of JsRoot
    Uint32Array* = ref object of JsRoot
    Uint8Array* = ref object of JsRoot

  func newArrayBuffer*(n: int): ArrayBuffer {.importjs: "new ArrayBuffer(#)".}
  func newFloat64Array*(buffer: ArrayBuffer): Float64Array {.importjs: "new Float64Array(#)".}
  func newUint32Array*(buffer: ArrayBuffer): Uint32Array {.importjs: "new Uint32Array(#)".}


  func newUint8Array*(n: int): Uint8Array {.importjs: "new Uint8Array(#)".}

  func `[]`*(arr: Uint32Array, i: int): uint32 {.importjs: "#[#]".}
  func `[]`*(arr: Uint8Array, i: int): uint8 {.importjs: "#[#]".}
  func `[]=`*(arr: Float64Array, i: int, v: float) {.importjs: "#[#] = #".}
