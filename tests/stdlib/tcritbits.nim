discard """
  output: '''abc
def
definition
prefix
xyz
def
definition'''
"""

import critbits

when isMainModule:
  var r: TCritBitTree[void]
  r.incl "abc"
  r.incl "xyz"
  r.incl "def"
  r.incl "definition"
  r.incl "prefix"
  doAssert r.contains"def"
  #r.del "def"

  for w in r.items:
    echo w
    
  for w in r.itemsWithPrefix("de"):
    echo w

