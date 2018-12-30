discard """
  errormsg: "annotation to deprecated not supported here"
  line: 7
"""

var foo* {.deprecated.} = 42
var foo1* {.deprecated: "no".} = 42
