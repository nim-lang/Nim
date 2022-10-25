type
  F = proc():int
  T = tuple[c: F]

const
  f: F = proc():int = 1
  myTuple: T = (c: f)
  myLiteralArray: array[1, T] = [myTuple]

doAssert myLiteralArray[0].c() == 1
