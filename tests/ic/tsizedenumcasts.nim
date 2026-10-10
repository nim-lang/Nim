discard
  """
  description: '''IC preserves explicitly sized enum constants from imported modules'''
"""

#? metamorphic

#!FILE masks.nim
type EventMask* {.size: 8.} = enum
  mouseEvent = 1 shl 27

const allEvents* = cast[EventMask](uint64.high)

#!FILE main.nim
import masks
doAssert cast[uint64](allEvents) == uint64.high
echo cast[uint64](allEvents)
#!STEP expect: 18446744073709551615

#!FILE main.nim
import masks
static:
  doAssert cast[uint64](allEvents) == uint64.high
doAssert cast[uint64](allEvents) == uint64.high
echo cast[uint64](allEvents)
#!STEP expect: 18446744073709551615
