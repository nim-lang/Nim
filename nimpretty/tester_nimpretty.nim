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

proc test(infile, ext: string) =
  if execShellCmd("$# -o:$# --backup:off $#" % [nimp, infile.changeFileExt(ext), infile]) != 0:
    echo "FAILURE: nimpretty cannot prettify ", infile
    failures += 1
    return
  let nimFile = splitFile(infile).name
  let expected = dir / "expected" / nimFile & ".nim"
  let produced = dir / nimFile.changeFileExt(ext)
  if readFile(expected) != readFile(produced):
    echo "FAILURE: files differ: ", nimFile
    discard execShellCmd("diff -uNdr " & expected & " " & produced)
    failures += 1
  else:
    echo "SUCCESS: files identical: ", nimFile

for t in walkFiles(dir / "*.nim"):
  test(t, "pretty")
  # also test that pretty(pretty(x)) == pretty(x)
  test(t.changeFileExt("pretty"), "pretty2")

  removeFile(t.changeFileExt("pretty"))
  removeFile(t.changeFileExt("pretty2"))


if failures > 0: quit($failures & " failures occurred.")
