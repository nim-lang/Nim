discard """
  errormsg: "illegal recursion in type 'Test'"
  line: 13
"""




type
  Test[T14646] = object
    f2: Test[T14646]

let t = Test[int]()
