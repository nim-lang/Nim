discard """
outputsub: "is newer than"
"""
# test the new LastModificationTime() proc

let
  file1 = "tests/testdata/data.csv"
  file2 = "tests/testdata/doc1.xml"

import
  os, times, strutils

proc main() =
  var
    a, b: Time
  a = getLastModificationTime(file1)
  b = getLastModificationTime(file2)
  writeLine(stdout, $a)
  writeLine(stdout, $b)
  if a < b:
    write(stdout, "$2 is newer than $1\n" % [file1, file2])
  else:
    write(stdout, "$1 is newer than $2\n" % [file1, file2])

main()
