proc foo() = discard
proc bar(x: int): int = x
proc baz(x, y: int): string = $(x + y)

proc baz(a: bool; b: string; c: int): float =
  if a and b == "" and c == 0:
    result = 0.0
  else:
    result = 1.0

proc forwardDecl()
proc forwardDecl() =
  foo()

forwardDecl()

proc forwardDecl2*(): int
proc forwardDecl2*(): int = bar(1)

discard forwardDecl2()

proc forwardDecl3(x, y: int): int
proc forwardDecl3(x, y: int): int = x - y

discard forwardDecl3(3, 2)

func func1(): int = 123
discard func1()
func func2(x: int): int = x
func func3*(x, y: bool): bool = x and y

proc withDefaultValue(x = 1) = echo x
withDefaultValue()
withDefaultValue(2)
withDefaultValue(x = 3)

proc withDefaultValue2(x = "foo"; y = true) = echo x, y
withDefaultValue2()
withDefaultValue2("bar")
withDefaultValue2(x = "baz", y = false)

proc varParam(x: var int) = x = 10
var x = 0
varParam(x)

proc varRet(x: var int): var int = x
varRet(x) = 100
