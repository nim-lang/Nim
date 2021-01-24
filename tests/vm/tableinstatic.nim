discard """
  nimout: '''0
0
0
'''
"""

import tables

# bug #5327

type
  MyType* = object
    counter: int

proc foo(t: var MyType) =
  echo t.counter

proc bar(t: MyType) =
  echo t.counter

static:
  var myValue: MyType
  myValue.foo # works nicely

  var refValue: ref MyType
  refValue.new

  refValue[].foo # fails to compile
  refValue[].bar # works again nicely

static:
  var otherTable = newTable[string, string]()

  otherTable["hallo"] = "123"
  otherTable["welt"]  = "456"

  doAssert otherTable == {"hallo": "123", "welt": "456"}.newTable
