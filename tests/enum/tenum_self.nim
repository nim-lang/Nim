discard """
  errormsg: "1 can't be converted to ErrorFoo"
"""


type
  Foo = enum
    Bar = 0.Foo

  ErrorFoo = enum
    eBar = 1.ErrorFoo
