import mambsym2 # import TExport

type
  TExport* = enum x, y, z

proc ha() =
  var
    x: TExport # no error
  nil
