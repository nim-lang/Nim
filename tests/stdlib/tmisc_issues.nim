discard """
  matrix: "--mm:refc; --mm:orc"
  targets: "c cpp js"
"""

import std/assertions

# bug #20227
type
  Data = object
    id: int

  Test = distinct Data

  Object = object
    data: Test


var x: Object = Object(data: Test(Data(id: 12)))
doAssert Data(x.data).id == 12
