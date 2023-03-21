# bug #3770
import m3770

doAssert $jjj() == "(hidden: 15)"  # works

proc someGeneric(_: type) =
  doAssert $jjj() == "(hidden: 15)" # fails: "Error: the field 'hidden' is not accessible."

someGeneric(int)
