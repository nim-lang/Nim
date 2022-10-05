import std/pegs
from stdtest/specialpaths import buildDir, testsDir
import std/os

const secondFile = buildDir / "grammar.txt"

if not dirExists(buildDir):
  createDir(buildDir)

var outp = open(secondFile, fmWrite)
for line in lines("compiler/parser.nim"):
  if line =~ peg" \s* '#| ' {.*}":
    outp.write matches[0], "\L"
outp.close

doAssert sameFileContent(secondFile, "doc/grammar.txt"),
        "execute 'nim r compiler.nim' to keep grammar.txt up-to-date"
