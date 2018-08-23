discard """
  line: 7
  errormsg: "annotation to deprecated not supported here"
"""

var foo* {.deprecated.} = 42
var foo1* {.deprecated: "no".} = 42
