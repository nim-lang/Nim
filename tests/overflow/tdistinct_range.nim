discard """
  outputsub: "Error: unhandled exception: over- or underflow [OverflowDefect]"
  exitcode: "1"
"""
var x: distinct range[0..5]
dec(x)