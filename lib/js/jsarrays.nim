##[
This module provides a wrapper for ArrayBuffer, DataView and related API's such
as `getInt8`, `setInt16`.
]##

#[
`BigInt` could be homed here.
]#

static: doAssert defined(js)

type
  ArrayBuffer* = ref object {.importjs.}
  DataView* = ref object {.importjs.}
    ## https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/DataView

proc newArrayBuffer*(n: int): ArrayBuffer {.importjs: "new ArrayBuffer(#)".}
proc newDataView*(a: ArrayBuffer, offset: int): DataView {.importjs: "new DataView(#, #)".}
proc toArrayBuffer*(a: string): ArrayBuffer =
  let n = a.len
  result = newArrayBuffer(n)
  {.emit:"""
  const view = new Uint8Array(`result`);
  for(i=0;i<`n`;i++){
    view[i] = `a`[i];
  }
  """.}

template genGetSet(T, funGet, funSet): untyped =
  proc funGet(a: DataView, byteOffset: int, littleEndian: bool): T {.importcpp.}
  proc funSet(a: DataView, byteOffset: int, value: T, littleEndian: bool): T {.importcpp.}

genGetSet int8, getInt8, setInt8
genGetSet int16, getInt16, setInt16
genGetSet int32, getInt32, setInt32

proc getTyped*(a: DataView, T: typedesc, offset: int, littleEndian: bool): T =
  when false: discard
  elif T is int8: getInt8(a, offset, littleEndian)
  elif T is int16: getInt16(a, offset, littleEndian)
  elif T is int32: getInt32(a, offset, littleEndian)
  else: static doAssert false, $T # add as needed

when false: ## scratch below
  # view[i] = str.charCodeAt(i); // check whether would be needed for cstring

  # proc `[]=`(a: ArrayBuffer, index: int, val: char) =
  #   {.emit: """`a`[`index`] = `val`;""".}

  # DataView.prototype.getBigInt64()
  # DataView.prototype.getBigUint64()
  # DataView.prototype.getFloat32()
  # DataView.prototype.getFloat64()
  # DataView.prototype.getInt16()
  # DataView.prototype.getInt32()
  # DataView.prototype.getInt8()
  # DataView.prototype.getUint16()
  # DataView.prototype.getUint32()
  # DataView.prototype.getUint8()
  # DataView.prototype.setBigInt64()
  # DataView.prototype.setBigUint64()
  # DataView.prototype.setFloat32()
  # DataView.prototype.setFloat64()
  # DataView.prototype.setInt16()
  # DataView.prototype.setInt32()
  # DataView.prototype.setInt8()
  # DataView.prototype.setUint16()
  # DataView.prototype.setUint32()
  # DataView.prototype.setUint8()

  proc decode() =
    case bufLen
    of int32.sizeof:
      cast[ptr int](buffer)[] = s2.getInt32(0, true)
    of int16.sizeof:
      cast[ptr int16](buffer)[] = s2.getInt16(0, true)
    else:
      doAssert false
