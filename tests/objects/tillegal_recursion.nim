discard """
  errormsg: "illegal recursion in type 'object'"
  line: 7
"""
# bug #1691
type
  Foo = ref object of Foo
