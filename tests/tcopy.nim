# tests the copy proc

import
  strutils

proc main() =
  const
    example = r"TEMP=C:\Programs\xyz\bin"
  var
    a, b: string
    p: int
  p = findSubStr("=", example)
  a = copy(example, 0, p-1)
  b = copy(example, p+1)
  writeln(stdout, a & '=' & b)
  #writeln(stdout, b)

main()
#OUT TEMP=C:\Programs\xyz\bin
