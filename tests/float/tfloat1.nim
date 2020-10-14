discard """
  outputsub: "Error: unhandled exception: FPU operation caused an overflow [FloatOverflowDefect]"
  exitcode: "1"
"""
# Test new floating point exceptions

{.floatChecks: on.}

var x = 0.8
var y = 0.0

echo x / y #OUT Error: unhandled exception: FPU operation caused an overflow
