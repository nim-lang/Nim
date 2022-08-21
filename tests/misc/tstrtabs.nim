discard """
  targets: "c cpp js"
"""

import std/strtabs

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
