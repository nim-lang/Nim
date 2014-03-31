discard """
  errmsg: "nested proc can have generic parameters only when"
  line: 6
"""

let x = proc (x, y): auto = x + y

