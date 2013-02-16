discard """
  line: 22
  errormsg: "type mismatch"
"""

type
  PObj = ref TObj not nil
  TObj = object
    x: int
  
  MyString = string not nil

#var x: PObj = nil

proc p(x: string not nil): int =
  result = 45

proc q(x: MyString) = nil
proc q2(x: string) = nil

q2(nil)
q(nil)

