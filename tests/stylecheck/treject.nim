discard """
  action: reject
  nimout: '''treject.nim(14, 13) Error: 'iD' should be: 'id' [field declared in treject.nim(9, 5)]'''
  matrix: "--styleCheck:error --styleCheck:usages"
"""

type
  Name = object
    id: int

template hello =
  var iD = "string"
  var name: Name
  echo name.iD
  echo iD

hello()