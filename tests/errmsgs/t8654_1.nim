discard """
  errormsg: "'typedesc' metatype is not valid here"
  line: 6
"""

var a: typedesc
a = typedesc[int]
echo a is typedesc[int]
