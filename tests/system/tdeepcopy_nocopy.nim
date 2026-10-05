discard """
  matrix: "--mm:refc; --mm:orc --deepcopy:on"
  errormsg: "'deepCopy' is not available for type <NoCopy>"
  file: "system.nim"
"""

type NoCopy = object

proc `=copy`(a: var NoCopy; b: NoCopy) {.error.}

var a = new NoCopy
var b = deepCopy(a)
