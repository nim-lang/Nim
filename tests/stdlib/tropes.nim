import ropes


block:
  let r: Rope = nil
  doAssert r[0] == '\0'

block:
  var
    r1 = rope("Hello")
    r2 = rope("Nim-Lang")

  let r = r1 & r2
  let s = $r
  for i in 0 ..< r.len:
    doAssert r[i] == s[i]

  doAssert r[66] == '\0'

block:
  let r = rope("Hello, Nim-Lang")

  let s = $r
  for i in 0 ..< r.len:
    doAssert r[i] == s[i]

  doAssert r[66] == '\0'

block:
  var r: Rope
  r.add rope("Nim ")
  r.add rope("is ")
  r.add rope("a ")
  r.add rope("great ")
  r.add rope("language")

  let s = $r
  for i in 0 ..< r.len:
    doAssert r[i] == s[i]

  doAssert r[66] == '\0'

block:
  var r: Rope
  r.add rope("My Conquest")
  r.add rope(" is ")
  r.add rope("the Sea of Stars")

  let s = $r
  for i in 0 ..< r.len:
    doAssert r[i] == s[i]

  doAssert r[66] == '\0'

block:
  var r: Rope
  r.add rope("My Conquest")
  r.add rope(" is ")
  r.add rope("the Sea of Stars")

  var i: int
  for item in r:
    doAssert r[i] == item
    inc i

  doAssert r[66] == '\0'

block:
  let r1 = "$1 $2 $3" % [rope("Nim"), rope("is"), rope("a great language")]
  doAssert $r1 == "Nim is a great language"

  let r2 = "$# $# $#" % [rope("Nim"), rope("is"), rope("a great language")]
  doAssert $r2 == "Nim is a great language"
