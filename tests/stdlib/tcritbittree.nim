discard """
  nimout: "1"
"""
import critbits

static:
  var strings: CritBitTree[int]
  discard strings.containsOrIncl("foo", 1)
  echo strings.staticGet("foo")
