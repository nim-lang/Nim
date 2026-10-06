discard """
  nimout: '''
2
2
'''
"""

# a `result` of an inheritable object type that is only assigned field by
# field still has a type header (json_serialization)

type
  BaseType = object of RootObj
    a: string
    b: int

proc readObj(T: type): T =
  result.a = "x"
  result.b = 2

static:
  block:
    let o = readObj(BaseType)
    echo o.b
    var d = new(BaseType)
    d[] = o
    echo d.b
