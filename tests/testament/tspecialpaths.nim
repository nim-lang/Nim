import stdtest/specialpaths
import std/os
block: # splitTestFile
  doAssert splitTestFile("tests/fakedir/tfakename.nim") == ("fakedir", "tests/fakedir/tfakename.nim".unixToNativePath)
  doAssert splitTestFile("/pathto/tests/fakedir/tfakename.nim") == ("fakedir", "/pathto/tests/fakedir/tfakename.nim".unixToNativePath)
  doAssert splitTestFile(getCurrentDir() / "tests/fakedir/tfakename.nim") == ("fakedir", "tests/fakedir/tfakename.nim".unixToNativePath)
  doAssert splitTestFile(getCurrentDir() / "sub/tests/fakedir/tfakename.nim") == ("fakedir", "sub/tests/fakedir/tfakename.nim".unixToNativePath)
  doAssertRaises(AssertionDefect): discard splitTestFile("testsbad/fakedir/tfakename.nim")
  doAssertRaises(AssertionDefect): discard splitTestFile("tests/tfakename.nim")
