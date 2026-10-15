block: # bug #13618
  proc test(x: Natural or BackwardsIndex): int =
    int(x)

  doAssert test(^1) == 1
  doAssert test(1) == 1

block: # #25174
  type Foo = object
  type Bar = object
  type Quz = object

  proc bar[T: Foo | Bar](x: T): string =
    return $typeof(T)
  proc bar[T: object](x: T): string =
    return $typeof(T)
  doAssert bar(Foo()) == "Foo"
  doAssert bar(Bar()) == "Bar"
  doAssert bar(Quz()) == "Quz"
