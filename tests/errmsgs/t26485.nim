discard """
  errormsg: "'continue' not supported in a 'fields' loop"
  line: 15
"""

# bug #26485: a `continue` coming from a template ended up in the
# fields loop body and crashed the compiler

type O = object
  a, b: int

template skip() = continue
for name, v in fieldPairs(O()):
  echo name
  skip()
