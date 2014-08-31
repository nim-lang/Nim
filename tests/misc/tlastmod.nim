# test the new LastModificationTime() proc

import
  os, times, strutils

proc main() =
  var
    a, b: TTime
  a = getLastModificationTime(paramStr(1))
  b = getLastModificationTime(paramStr(2))
  writeln(stdout, $a)
  writeln(stdout, $b)
  if a < b:
    write(stdout, "$2 is newer than $1\n" % [paramStr(1), paramStr(2)])
  else:
    write(stdout, "$1 is newer than $2\n" % [paramStr(1), paramStr(2)])

main()
