discard """
  matrix: "--mm:refc; --mm:orc"
  targets: "c cpp js"
"""

import std/strtabs
import std/assertions

macro m =
  var t = {"name": "John"}.newStringTable
  doAssert t["name"] == "John"

block:
  var t = {"name": "John"}.newStringTable
  doAssert t["name"] == "John"

m()

proc fun()=
  let ret = newStringTable(modeCaseSensitive)
  ret["foo"] = "bar"

  doAssert $ret == "{foo: bar}"

  let b = ret["foo"]
  doAssert b == "bar"

proc main()=
  static: fun()
  fun()

main()
