discard """
  errormsg: "inline iterators are not first-class / cannot be assigned to variables"
  line: 8
"""

iterator foo: int =
  yield 2
let x = foo
