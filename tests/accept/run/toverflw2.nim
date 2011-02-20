discard """
  file: "toverflw2.nim"
  output: "Error: unhandled exception: over- or underflow [EOverflow]"
"""
var a : int32 = 2147483647
var b : int32 = 2147483647
var c = a + b




