# Test if the new table constructor syntax works:

template ignoreExpr(e: expr): stmt {.immediate.} =
  discard

# test first class '..' syntactical citizen:
ignoreExpr x <> 2..4
# test table constructor:
ignoreExpr({:})
ignoreExpr({2: 3, "key": "value"})

# NEW:
doAssert 56 in 50..100

doAssert 56 in ..60
