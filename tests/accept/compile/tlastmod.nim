# test the new LastModificationTime() proc

import
  os, times, strutils

proc main() =
  var
    a, b: TTime
  a = getLastModificationTime(ParamStr(1))
  b = getLastModificationTime(ParamStr(2))
  writeln(stdout, $a)
  writeln(stdout, $b)
  if a < b:
    Write(stdout, "$2 is newer than $1\n" % [ParamStr(1), ParamStr(2)])
  else:
    Write(stdout, "$1 is newer than $2\n" % [ParamStr(1), ParamStr(2)])

main()
