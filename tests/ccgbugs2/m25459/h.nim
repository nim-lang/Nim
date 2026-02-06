import ./g
export g

proc a*(): W =
  var e = D[int64]()
  e.c.setLen(8)
  e.k[1] = 0
  result = W(j: e)
