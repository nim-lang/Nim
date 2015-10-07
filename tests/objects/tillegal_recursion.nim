discard """
  errormsg: "inheritance only works with non-final objects"
  line: 7
"""
# bug #1691
type
  Foo = ref object of Foo
