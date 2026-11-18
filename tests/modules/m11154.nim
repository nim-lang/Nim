proc convert(arg: HSlice): string = $arg.a & ".." & $arg.b

proc implicitConvert*(args: varargs[string, convert]): string =
  for a in args: result.add a

proc test*(range: HSlice): string = implicitConvert range
