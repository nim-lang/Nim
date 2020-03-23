# This nimscript is used to test if the following modules can be imported
# http://nim-lang.org/docs/nims.html

{.push warning[UnusedImport]:off.}
import algorithm
import base64
import colors
import hashes
import lists
import math
# import marshal
import options
import os
# import parsecfg
# import parseopt
import parseutils
# import pegs
import deques
import sequtils
import strutils
import tables
import unicode
import uri
import macros
{.pop warning[UnusedImport]:off.}

block:
  doAssert "./foo//./bar/".normalizedPath == "foo/bar".unixToNativePath

block: # PR #13714 VM callbacks can now raise
  template fun() =
    doAssertRaises(IOError): writeFile("nonexistant/bar.txt".unixToNativePath, "foo")
    doAssertRaises(OSError): (for a in listFiles("nonexistant", checkDir = true): discard)
    doAssertRaises(OSError): cd("nonexistant")
  static: fun()
  fun()

echo "Nimscript imports are successful."
