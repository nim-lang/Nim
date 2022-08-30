discard """
  matrix: "--styleCheck:error --styleCheck:usages"
"""

import std/[asyncdispatch, nre]

type
  Name = object
    id: int

template hello =
  var iD = "string"
  var name: Name
  doAssert name.id == 0
  doAssert iD == "string"

hello()

# bug #12955
import os
import fileinfo
var xs: seq[fileinfo.FileInfo]
