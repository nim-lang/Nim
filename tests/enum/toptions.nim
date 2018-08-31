
type
  # please make sure we have under 32 options (improves code efficiency!)
  TOption = enum
    optNone, optForceFullMake, optBoehmGC, optRefcGC, optRangeCheck,
    optBoundsCheck, optOverflowCheck, optNilCheck, optAssert, optLineDir,
    optWarns, optHints, optListCmd, optCompileOnly,
    optSafeCode,             # only allow safe code
    optStyleCheck, optOptimizeSpeed, optOptimizeSize, optGenDynLib,
    optGenGuiApp, optStackTrace

  TOptionset = set[TOption]

var
  gOptions: TOptionset = {optRefcGC, optRangeCheck, optBoundsCheck,
    optOverflowCheck, optAssert, optWarns, optHints, optLineDir, optStackTrace}
  compilerArgs: int
  gExitcode: int8
