discard """
  errormsg: "Cannot inherit from: 'Foo:ObjectType'"
  line: 7
"""
# bug #1691
type
  Foo = ref object of Foo
