discard """
  nimout: '''
foo
foo
foo
true
'''
"""

# the deprecated `NimIdent` is an AST node in the VM, also as an object field
# (nimfp via classy)

import std/macros

{.push warnings: off.}
type Pattern = object
  ident: NimIdent
  arity: Natural

macro m(x: untyped): untyped =
  let p = Pattern(ident: x.ident, arity: 0)
  echo $p.ident
  var s: seq[Pattern] = @[]
  s.add p
  echo $s[0].ident
  let q = s[0]
  echo $q.ident
  echo x.eqIdent($q.ident)
  result = newEmptyNode()
{.pop.}

m(foo)
