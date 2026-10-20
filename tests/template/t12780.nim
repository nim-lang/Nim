# bug #12780: range checks for the literal arguments of templates
template testTemplate1(i: range[0..5]): int = i

type Range = range[0..5]

template testTemplate2(i: Range): int = i
template testTemplate3(i: Natural): int = i

doAssert not compiles(testTemplate1(100))
doAssert not compiles(testTemplate2(100))
doAssert not compiles(testTemplate3(-1))
doAssert testTemplate1(5) == 5
doAssert testTemplate2(0) == 0
doAssert testTemplate3(7) == 7

template overloaded(i: range[0..5]): string = "small"
template overloaded(i: int): string = "int"
doAssert overloaded(100) == "int"
