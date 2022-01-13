discard """
  errormsg: "invalid indentation"
  line: 10
  column: 11
"""

type
  A = (ref | ptr | pointer)
  B = pointer | ptr | ref
  C = ref | ptr | pointer
