discard """
  errormsg: "'owned' is only valid for 'ref' and closure types, but got 'seq[int]'"
  line: 7
"""
{.experimental: "ownedRefs".}
type
  S = owned seq[int]
