discard """
  errormsg: "expression has no address"
"""
type
  MyObject = object
    x: seq[string]

proc mytest1(s: MyObject, i: int): lent string =
  ## works fine
  if i < s.x.len - 1 and s.x[i] != "":
    result = s.x[i]
  else: raise newException(KeyError, "err1")

proc mytest2(s: MyObject, i: int): lent string =
  ## reject due to if expr
  if i < s.x.len - 1 and s.x[i] != "": s.x[i]
  else: raise newException(KeyError, "err1")

for i in 1..5:
  var x = MyObject(x: @["1", "2", "3"])
  echo mytest1(x, 1)
  echo mytest2(x, 1)


