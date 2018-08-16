discard """
  errormsg: "invalid type for const: typedesc"
  line: 6
"""

const a: typedesc = typedesc[int]
echo a is typedesc[int]
