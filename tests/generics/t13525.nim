# https://github.com/nim-lang/Nim/issues/13524
template fun(field): untyped = astToStr(field)
proc test1(): string = fun(nonexistent1)
proc test2[T](): string = fun(nonexistent2) # used to cause: Error: undeclared identifier: 'nonexistent2'
doAssert test1() == "nonexistent1"
doAssert test2[int]() == "nonexistent2"
