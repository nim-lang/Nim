# Small program that runs the test cases

import strutils, os

const
  dir = "nimpretty/tests/"

var
  failures = 0

when defined(develop):
  const nimp = "bin" / "nimpretty".addFileExt(ExeExt)
  if execShellCmd("nim c -o:$# nimpretty/nimpretty.nim" % [nimp]) != 0:
    quit("FAILURE: compilation of nimpretty failed")
else:
  const nimp = "nimpretty"

proc test(infile, outfile: string) =
  if execShellCmd("$# -o:$# --backup:off $#" % [nimp, outfile, infile]) != 0:
    quit("FAILURE")
  let nimFile = splitFile(infile).name
  let expected = dir / "expected" / nimFile & ".nim"
  let produced = dir / nimFile & ".pretty"
  if strip(readFile(expected)) != strip(readFile(produced)):
    echo "FAILURE: files differ: ", nimFile
    discard execShellCmd("diff -uNdr " & expected & " " & produced)
    failures += 1
  else:
    echo "SUCCESS: files identical: ", nimFile

for t in walkFiles(dir / "*.nim"):
  let res = t.changeFileExt("pretty")
  test(t, res)
  removeFile(res)

if failures > 0: quit($failures & " failures occurred.")
