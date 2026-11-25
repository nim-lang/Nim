discard """
  errormsg: "the fields 'w' belong to a branch of a sum type; construct it with the branch name 'R'"
  line: 13
"""

type
  Sh = object
    x: int
    case
    of C: r: int
    of R: w, h: int

echo Sh(w: 1)
