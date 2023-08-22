discard """
"""

# issue #8199

const rangesGCHoldEnabled = true # not defined(rangesDisableGCHold)

type
  # A view into immutable array
  Range*[T] {.shallow.} = object
    when rangesGCHoldEnabled:
      gcHold: seq[T] # 0
    start: ptr T # 1
    mLen: int32 # 2

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
