# issue #8199

const rangesGCHoldEnabled = not defined(rangesDisableGCHold)

type
  # A view into immutable array
  Range* {.shallow.} [T] = object
    when rangesGCHoldEnabled:
      gcHold: seq[T]
    start: ptr T
    mLen: int32

type
  BytesRange* = Range[byte]
  NibblesRange* = object
    bytes: BytesRange

const
  zeroBytesRange* = BytesRange()

proc initNibbleRange*(bytes: BytesRange): NibblesRange =
  result.bytes = bytes

const
  zeroNibblesRange* = initNibbleRange(zeroBytesRange)
