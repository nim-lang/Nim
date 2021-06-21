include compiler/[nimblecmd]

proc v(s: string): Version = s.newVersion
# #head is special in the sense that it's assumed to always be newest.
doAssert v"1.0" < v"#head"
doAssert v"1.0" < v"1.1"
doAssert v"1.0.1" < v"1.1"
doAssert v"1" < v"1.1"
doAssert v"#aaaqwe" < v"1.1" # We cannot assume that a branch is newer.
doAssert v"#a111" < v"#head"

let conf = newConfigRef()
var rr = newStringTable()
addPackage conf, rr, "irc-#a111", unknownLineInfo
addPackage conf, rr, "irc-#head", unknownLineInfo
addPackage conf, rr, "irc-0.1.0", unknownLineInfo
#addPackage conf, rr, "irc", unknownLineInfo
#addPackage conf, rr, "another", unknownLineInfo
addPackage conf, rr, "another-0.1", unknownLineInfo

addPackage conf, rr, "ab-0.1.3", unknownLineInfo
addPackage conf, rr, "ab-0.1", unknownLineInfo
addPackage conf, rr, "justone-1.0", unknownLineInfo

doAssert toSeq(rr.chosen) ==
  @["irc-#head", "ab-0.1.3", "justone-1.0", "another-0.1"]
