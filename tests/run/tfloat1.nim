discard """
  file: "tfloat1.nim"
  outputsub: "Error: unhandled exception: FPU operation caused an overflow [EFloatOverflow]"
  exitcode: "1"
"""
# Test new floating point exceptions

{.floatChecks: on.}

var x = 0.8
var y = 0.0

echo x / y #OUT Error: unhandled exception: FPU operation caused an overflow [EFloatOverflow]


