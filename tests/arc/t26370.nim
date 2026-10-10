discard """
  output: '''
new "aaaaaaaaaaaaaaaa"
new aaaaaaaaaaaaaaaa
'''
  matrix: "--mm:orc --deepcopy:on -d:useMalloc; --mm:arc --deepcopy:on -d:useMalloc"
  valgrind: "true"
"""

# bug #26370: after `reset`, the case object's branch fields must be nil,
# otherwise `marshal.load`/`deepCopy` assign through the freed string.

import std/[marshal, streams]

type
  S = object
    case kind: bool
    of false: discard
    of true: s: string

proc viaLoad() =
  var x = S(kind: true, s: newString(16))
  reset(x)
  var other = newString(16)
  for c in other.mitems: c = 'a'
  load(newStringStream($$S(kind: true, s: "new")), x)
  echo x.s, " ", repr(other)

proc viaDeepCopy() =
  var x = S(kind: true, s: newString(16))
  reset(x)
  var other = newString(16)
  for c in other.mitems: c = 'a'
  deepCopy(x, S(kind: true, s: "new"))
  echo x.s, " ", other

viaLoad()
viaDeepCopy()
