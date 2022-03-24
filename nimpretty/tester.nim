# Small program that runs the test cases

import strutils, os, sequtils
from std/private/gitutils import diffFiles

const
  dir = "nimpretty/tests"
  outputdir = dir / "outputdir"

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
    echo diffFiles(expected, produced).output
    failures += 1
  else:
    echo "SUCCESS: files identical: ", nimFile

proc testTogether(infiles: seq[string]) =
  if execShellCmd("$# --outDir:$# --backup:off $#" % [nimp, outputdir, infiles.join(" ")]) != 0:
    echo "FAILURE: nimpretty cannot prettify files: ", $infiles
    failures += 1
    return

  for infile in infiles:
    let nimFile = splitFile(infile).name
    let expected = dir / "expected" / nimFile & ".nim"
    let produced = dir / "outputdir" / infile
    if readFile(expected) != readFile(produced):
      echo "FAILURE: files differ: ", nimFile
      echo diffFiles(expected, produced).output
      failures += 1
    else:
      echo "SUCCESS: files identical: ", nimFile

let allFiles = toSeq(walkFiles(dir / "*.nim"))
for t in allFiles:
  test(t, "pretty")
  # also test that pretty(pretty(x)) == pretty(x)
  test(t.changeFileExt("pretty"), "pretty2")

  removeFile(t.changeFileExt("pretty"))
  removeFile(t.changeFileExt("pretty2"))

testTogether(allFiles)
removeDir(outputdir)

if failures > 0: quit($failures & " failures occurred.")
