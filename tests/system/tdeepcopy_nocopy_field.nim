discard """
  matrix: "--mm:refc; --mm:orc --deepcopy:on"
  errormsg: "'deepCopy' is not available for type <Container>"
  file: "system.nim"
"""

type
  NoCopy = object
  Container = object
    value: NoCopy

proc `=copy`(a: var NoCopy; b: NoCopy) {.error.}

var a = new Container
var b = deepCopy(a)
