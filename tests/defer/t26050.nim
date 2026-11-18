proc issue26050() =
  when nimvm:
    discard
  else:
    var completed = false
    defer: doAssert completed
  completed = true

proc branchOrder(): seq[int] =
  when nimvm:
    result.add 1
    defer: result.add 5
    result.add 2
    defer: result.add 4
    result.add 3
  else:
    result.add 11
    defer: result.add 15
    result.add 12
    defer: result.add 14
    result.add 13
  result.add 0

proc nestedBranch(): seq[int] =
  when nimvm:
    when nimvm:
      result.add 1
      defer: result.add 3
      result.add 2
    else:
      discard
  else:
    result.add 11
  result.add 0

issue26050() # bug #26050
doAssert branchOrder() == @[11, 12, 13, 0, 14, 15]
doAssert nestedBranch() == @[11, 0]
static:
  doAssert branchOrder() == @[1, 2, 3, 0, 4, 5]
  doAssert nestedBranch() == @[1, 2, 0, 3]
