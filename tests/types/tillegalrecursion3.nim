discard """
  errormsg: "illegal recursion in type 'Foo'"
"""

type
  Imported {.importc.} = object

  Foo = object
    b: Imported
    a: Foo

var myFoo: Foo
