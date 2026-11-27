discard """
  output: '''
None()
None()
Other(x: 1)
'''
"""

# a branch name that belongs to several sum types, bound by a template
type
  O1 = object
    case
    of None: discard
    of Some: val: int
  O2 = object
    case
    of None: discard
    of Other: x: int

template conv(): untyped = O1(None())
echo conv()
template mkNone(): untyped = None()
let a: O2 = mkNone()
echo a
template mkOther(): untyped = Other(x: 1)
echo mkOther()
