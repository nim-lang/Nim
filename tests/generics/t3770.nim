# bug #3770
import m3770

doAssert $jjj() == "(hidden: 15)"  # works

doAssert $said() == "(hidden1: 22, hidden2: 1)"

proc someGeneric(_: type) =
  doAssert $jjj() == "(hidden: 15)" # fails: "Error: the field 'hidden' is not accessible."
  when false: # todo somehow make it work?
    doAssert $said() == "(hidden1: 22, hidden2: 1)"

someGeneric(int)

doAssert $(foo()[]) == "(hidden1: 1, field: 2, hidden2: 3, field2: 4)"

proc bar() =
  var s = Gull(13, 14)
  doAssert $(s[]) == "(hidden1: 0, field: 13, hidden2: 0, field2: 14)"

bar()
