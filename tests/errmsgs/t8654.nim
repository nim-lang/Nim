discard """
  errormsg: "invalid type: 'typedesc' for var"
  line: 7
"""

# bug #8654: used to crash the compiler
var a: typedesc
a = typedesc[int]
echo a is typedesc[int]
