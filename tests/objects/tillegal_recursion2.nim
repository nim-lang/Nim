discard """
  errormsg: "Cannot inherit from: 'Foo'"
  line: 6
"""
type
  Foo = object of Foo
