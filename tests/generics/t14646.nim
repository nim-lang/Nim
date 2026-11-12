discard """
  errormsg: "illegal recursion in type 'Test'"
  line: 14
"""

# bug #14646: a generic object that holds itself by value used to make the
# compiler run out of stack (it built the default fields, then the hooks,
# forever) instead of reporting the recursion.

type
  Test[T] = object
    f2: Test[T]

let t = Test[int]()
