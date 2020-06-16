# This nimscript is used to test if the following modules can be imported
# http://nim-lang.org/docs/nims.html

{.warning[UnusedImport]: off.}

import std/private/nims_imports
import std/os

block:
  doAssert "./foo//./bar/".normalizedPath == "foo/bar".unixToNativePath

when false: # #14142
  discard existsDir("/usr")
  discard dirExists("/usr")
  discard existsFile("/usr/foo")
  discard fileExists("/usr/foo")
  discard findExe("nim")

echo "Nimscript imports are successful."

block: # #14142
  discard existsDir("/usr")
  discard dirExists("/usr")
  discard existsFile("/usr/foo")
  discard fileExists("/usr/foo")
  discard findExe("nim")
