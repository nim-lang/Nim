discard """
action: compile
"""

type
  Byte* = uint8
  Bytes* = seq[Byte]

  BytesRange* = object
    bytes: Bytes
    ibegin, iend: int

proc initBytesRange*(s: var Bytes, ibegin = 0, iend = -1): BytesRange =
  let e = if iend < 0: s.len + iend + 1
          else: iend
  assert ibegin >= 0 and e <= s.len

  shallow(s)
  result.bytes = s
  result.ibegin = ibegin
  result.iend = e

converter fromSeq*(s: Bytes): BytesRange =
  var seqCopy = s
  return initBytesRange(seqCopy)

type
  Reader* = object
    data: BytesRange
    position: int

proc readerFromBytes*(input: BytesRange): Reader =
  discard

let r = readerFromBytes(@[])
