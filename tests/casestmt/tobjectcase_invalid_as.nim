discard """
  errormsg: "object case branches using 'as' must contain exactly one type"
"""

type
  Base = ref object of RootObj
  Sub1 = ref object of Base
  Sub2 = ref object of Base

proc invalid(x: Base) =
  case x
  of Sub1 as s1, Sub2:
    discard s1
