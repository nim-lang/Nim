discard """
  file: "tfloat1.nim"
  output: "Error: unhandled exception: FPU operation caused an overflow [EFloatOverflow]"
"""
# Test new floating point exceptions

{.floatChecks: on.}

var x = 0.8
var y = 0.0

echo x / y #OUT Error: unhandled exception: FPU operation caused an overflow [EFloatOverflow]


