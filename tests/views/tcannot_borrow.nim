discard """
  errormsg: "cannot borrow"
  nimout: '''tcannot_borrow.nim(21, 7) Error: cannot borrow meh; what it borrows from is potentially mutated
tcannot_borrow.nim(22, 3) the mutation is here'''
  line: 21
"""


{.experimental: "views".}

type
  Foo = object
    field: string

proc valid(s: var seq[Foo]) =
  let v: lent Foo = s[0]  # begin of borrow
  echo v.field            # end of borrow
  s.setLen 0  # valid because 'v' isn't used afterwards

proc dangerous(s: var seq[Foo]) =
  let meh: lent Foo = s[0]
  s.setLen 0
  echo meh.field
