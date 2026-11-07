discard """
  nimout: '''
IdentDefs
  Sym "a"
  Empty
  Sym "thing"
IdentDefs
  Sym "b"
  Sym "float"
  FloatLit 1.0
'''
"""

# bug #12942: `getImpl` shows the checked default values of the parameters
import std/macros
var thing = 2
proc example(a = thing; b: float = 1) =
  discard (a, b, thing)
macro echoParams(x: typed) =
  for p in x.getImpl.params[1..^1]: echo p.treeRepr
echoParams(example)
