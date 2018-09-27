discard """
  output: '''
25.0
210.0
'''
"""

type
  Dollars = distinct float

proc `$`(d: Dollars): string {.borrow.}
proc `*` *(a, b: Dollars): Dollars {.borrow.}
proc `+` *(a, b: Dollars): Dollars {.borrow.}

var a = Dollars(20)
a = Dollars(25.0)
echo a
a = 10.Dollars * (20.Dollars + 1.Dollars)
echo a
