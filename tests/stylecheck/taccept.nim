discard """
  matrix: "--styleCheck:error --styleCheck:usages"
"""

import asyncdispatch

type
  Name = object
    id: int

template hello =
  var iD = "string"
  var name: Name
  echo name.id
  echo iD

hello()
