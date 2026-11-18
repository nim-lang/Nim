discard """
  errormsg: "index type 'int' for array is too large"
  line: 9
"""

# bug #10363: used to crash the compiler
type Foo[A, B] = array[A, B]
proc initFoo[A, B]: Foo[A, B] = discard
discard initFoo[1, bool]()
