discard """
  file: "tcopy.nim"
  output: "TEMP=C:\\Programs\\xyz\\bin"
"""
# tests the substr proc

import
  strutils

proc main() =
  const
    example = r"TEMP=C:\Programs\xyz\bin"
  var
    a, b: string
    p: int
  p = find(example, "=")
  a = substr(example, 0, p-1)
  b = substr(example, p+1)
  writeln(stdout, a & '=' & b)
  #writeln(stdout, b)

main()
#OUT TEMP=C:\Programs\xyz\bin


