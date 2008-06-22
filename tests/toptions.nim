# Converted by Pas2mor v1.54
# Used command line arguments:
# -m -q -o bootstrap\options.mor options.pas
#
#
#            The Morpork Compiler
#        (c) Copyright 2004 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

type
  # please make sure we have under 32 options (improves code efficiency!)
  TOption = enum
    optNone, optForceFullMake, optBoehmGC, optRefcGC, optRangeCheck,
    optBoundsCheck, optOverflowCheck, optNilCheck, optAssert, optLineDir,
    optWarns, optHints, optDeadCodeElim, optListCmd, optCompileOnly,
    optSafeCode,             # only allow safe code
    optStyleCheck, optOptimizeSpeed, optOptimizeSize, optGenDynLib,
    optGenGuiApp, optStackTrace

  TOptionset = set[TOption]

var
  gOptions: TOptionset = {optRefcGC, optRangeCheck, optBoundsCheck,
    optOverflowCheck, optAssert, optWarns, optHints, optLineDir, optStackTrace}
  compilerArgs: int
  gExitcode: uint8
