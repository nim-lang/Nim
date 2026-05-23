discard """
  errormsg: '''
The fields 'x' and 'y' cannot be initialized together, because they are from conflicting branches in the case object.
'''
"""

type
  Foo = object
    case kind: bool
    of true:
      x: int
    of false:
      y: int


var f = Foo(x: 1, y: 1)