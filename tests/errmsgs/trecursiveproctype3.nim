discard """
  errormsg: "illegal recursion in type 'MyFunc'"
  line: 9
"""

# issue #19271

type
  MyFunc = proc(f: ptr MyFunc)
