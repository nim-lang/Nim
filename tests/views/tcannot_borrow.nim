discard """
  errormsg: "cannot borrow"
  nimout: '''tcannot_borrow.nim(16, 7) Error: cannot borrow meh; what it borrows from is potentially mutated
tcannot_borrow.nim(17, 3) the mutation is here
tcannot_borrow.nim(16, 7) is the statement that connected the mutation to the parameter'''
  line: 16
"""

{.experimental: "views".}

type
  Foo = object
    field: string

proc dangerous(s: var seq[Foo]) =
  let meh: lent Foo = s[0]
  s.setLen 0
  echo meh.field
