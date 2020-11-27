discard """
  outputsub: "Error: unhandled exception: over- or underflow [OverflowDefect]"
  exitcode: "1"
"""
var a : int32 = 2147483647
var b : int32 = 2147483647
var c = a + b
