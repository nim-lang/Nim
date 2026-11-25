#
#
#            Nim's Runtime Library
#        (c) Copyright 2020 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

# Integer arithmetic with overflow checking. Uses
# intrinsics or inline assembler.

proc raiseOverflow {.compilerproc, noinline.} =
  # a single proc to reduce code size to a minimum
  sysFatal(OverflowDefect, "over- or underflow")

proc raiseDivByZero {.compilerproc, noinline.} =
  sysFatal(DivByZeroDefect, "division by zero")

proc raiseFloatInvalidOp {.compilerproc, noinline.} =
  sysFatal(FloatInvalidOpDefect, "FPU operation caused a NaN result")

proc raiseFloatOverflow(x: float64) {.compilerproc, noinline.} =
  if x > 0.0:
    sysFatal(FloatOverflowDefect, "FPU operation caused an overflow")
  else:
    sysFatal(FloatUnderflowDefect, "FPU operations caused an underflow")
