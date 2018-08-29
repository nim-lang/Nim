discard """
  errormsg: "cannot have typedesc as const value, use 'type a = int' instead"
  line: 6
"""

const a: typedesc = typedesc[int]
echo a is typedesc[int]
