discard """
  file: "toverflw2.nim"
  outputsub: "Error: unhandled exception: over- or underflow [OverflowError]"
  exitcode: "1"
"""
var a : int32 = 2147483647
var b : int32 = 2147483647
var c = a + b


