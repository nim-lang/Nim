discard """
  errormsg: "illegal recursion in type 'Test'"
  line: 10
"""




type
  Test[T14646] = object
    f2: Test[T14646]

let t = Test[int]()