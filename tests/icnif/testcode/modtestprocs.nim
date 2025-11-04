proc foo() = discard
foo()

proc bar(x: int): int = x
discard bar(1)

proc baz(x, y: int): int =
  bar(x)

proc baz(a: bool; b: string; c: int): float = 0.0

proc forwardDecl()
proc forwardDecl() =
  foo()

forwardDecl()

proc forwardDecl2*(): int
proc forwardDecl2*(): int = bar(1)

discard forwardDecl2()

proc forwardDecl3(x, y: int): int
proc forwardDecl3(x, y: int): int = x

discard forwardDecl3(3, 2)

func func1(): int = 123
discard func1()
func func2(x: int): int = x
func func3*(x, y: bool): bool = x

proc withDefaultValue(x = 1) = discard
withDefaultValue()
withDefaultValue(2)
withDefaultValue(x = 3)

proc withDefaultValue2(x = "foo"; y = true) = discard
withDefaultValue2()
withDefaultValue2("bar")
withDefaultValue2(x = "baz", y = false)

proc varParam(x: var int) = x = 10
var x = 0
varParam(x)

proc varRet(x: var int): var int = x
varRet(x) = 100
