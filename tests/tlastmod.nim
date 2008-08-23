# test the new LastModificationTime() proc

import
  os, times

proc main() =
  var
    a, b: TTime
  a = getLastModificationTime(ParamStr(1))
  b = getLastModificationTime(ParamStr(2))
  if a < b:
    Write(stdout, "b is newer than a\n")
  else:
    Write(stdout, "a is newer than b\n")

main()
