# https://github.com/nim-lang/Nim/issues/13524
template fun(field): untyped = astToStr(field)
proc test1(): string = fun(nonexistant1)
proc test2[T](): string = fun(nonexistant2) # used to cause: Error: undeclared identifier: 'nonexistant2'
doAssert test1() == "nonexistant1"
doAssert test2[int]() == "nonexistant2"
