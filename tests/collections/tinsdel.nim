import sequtils

# delete tests
var
  outcome = @[1,1,1,1,1,1,1,1]
  dest = @[1,1,1,2,2,2,2,2,2,1,1,1,1,1]
dest.delete(3, 8)
doAssert outcome == dest, """\
Deleting range 3-9 from [1,1,1,2,2,2,2,2,2,1,1,1,1,1]
is [1,1,1,1,1,1,1,1]"""

# insert tests
dest = @[1,1,1,1,1,1,1,1]
let
  src = @[2,2,2,2,2,2]
outcome = @[1,1,1,2,2,2,2,2,2,1,1,1,1,1]
dest.insert(src, 3)
doAssert dest == outcome, """\
Inserting [2,2,2,2,2,2] into [1,1,1,1,1,1,1,1]
at 3 is [1,1,1,2,2,2,2,2,2,1,1,1,1,1]"""
