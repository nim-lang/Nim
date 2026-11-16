discard """
  errormsg: "type mismatch"
  line: 9
"""

# bug #10363: used to crash the compiler; `1` is not a type (#13906)
type Foo[A, B] = array[A, B]
proc initFoo[A, B]: Foo[A, B] = discard
discard initFoo[1, bool]()
