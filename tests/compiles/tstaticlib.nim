import std/[os, osproc, strformat]


const dir = "tests/compiles"
const fileName = dir / "staticlibtest.nim"

block: # bug #18578
  const libName = dir / "tstaticlib1.a"
  let (_, status) = execCmdEx(fmt"nim c -o:{libName} --app:staticlib {fileName}")
  doAssert status == 0
  doAssert fileExists(libName)
  removeFile(libName)

block: # bug #16947
  const libName = dir / "tstaticlib2.a"
  doAssert fileExists(libName)
  let (_, status) = execCmdEx(fmt"nim c -o:{libName} --app:staticlib {fileName}")
  doAssert status == 0
  doAssert fileExists(libName)
