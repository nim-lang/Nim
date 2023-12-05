import mambsym2 # import TExport

type
  TExport* = enum x, y, z
  TOtherEnum* = enum mDec, mInc, mAssign

proc ha() =
  var
    x: TExport # no error
  discard
