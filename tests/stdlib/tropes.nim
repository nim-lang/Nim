discard """
  targets: "c js"
"""

import std/ropes

template main() =
  block:
    let r: Rope = nil
    doAssert r[0] == '\0'
    doAssert $r == ""

  block:
    var
      r1 = rope("Hello, ")
      r2 = rope("Nim-Lang")

    let r = r1 & r2
    let s = $r
    doAssert s == "Hello, Nim-Lang"
    for i in 0 ..< r.len:
      doAssert r[i] == s[i]

    doAssert r[66] == '\0'

  block:
    let r = rope("Hello, Nim-Lang")

    let s = $r
    doAssert s == "Hello, Nim-Lang"
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
    doAssert s == "Nim is a great language"
    for i in 0 ..< r.len:
      doAssert r[i] == s[i]

    doAssert r[66] == '\0'

  block:
    var r: Rope
    r.add rope("My Conquest")
    r.add rope(" is ")
    r.add rope("the Sea of Stars")

    let s = $r
    doAssert s == "My Conquest is the Sea of Stars"
    for i in 0 ..< r.len:
      doAssert r[i] == s[i]

    doAssert r[66] == '\0'

  block:
    var r: Rope
    r.add rope("My Conquest")
    r.add rope(" is ")
    r.add rope("the Sea of Stars")

    doAssert $r == "My Conquest is the Sea of Stars"

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

  block: # `[]`
    let r1 = rope("Hello, Nim!")

    doAssert r1[-2] == '\0'
    doAssert r1[0] == 'H'
    doAssert r1[7] == 'N'
    doAssert r1[22] == '\0'

    let r2 = rope("Hello") & rope(", Nim!")

    doAssert r2[-2] == '\0'
    doAssert r2[0] == 'H'
    doAssert r2[7] == 'N'
    doAssert r2[22] == '\0'

static: main()
main()
