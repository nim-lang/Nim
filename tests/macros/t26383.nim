discard """
  output: '''
fieldname true
'''
"""

# bug #26383: eqIdent for multi-part accent-quoted identifiers
import std/macros

static:
  let name = parseExpr("`field name`")
  doAssert $name == "fieldname"
  doAssert name.eqIdent($name)
  doAssert name.eqIdent("field_name")
  doAssert eqIdent("fieldName", name)
  doAssert name.eqIdent(ident"fieldname")
  doAssert name.eqIdent(parseExpr("`fi eld na me`"))
  doAssert not name.eqIdent("field")
  doAssert parseExpr("`foo 1`").eqIdent("foo1")
  doAssert parseExpr("`a b`").eqIdent(nnkPostfix.newTree(ident"*", parseExpr("`a b`")))

macro check(n: untyped): untyped =
  result = newLit($n & " " & $n.eqIdent($n))

echo check(`field name`)
