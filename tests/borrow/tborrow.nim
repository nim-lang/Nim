discard """
  output: '''4887 true
60.0
altstring test 1, 2, 3
'''
"""

# test the new borrow feature that works with generics:

proc `++`*[T: int | float](a, b: T): T =
  result = a + b

type
  DI = distinct int
  DF = distinct float
  DS = distinct string

proc `++`(x, y: DI): DI {.borrow.}
proc `++`(x, y: DF): DF {.borrow.}

proc `$`(x: DI): string {.borrow.}
proc `$`(x: DF): string {.borrow.}

echo 4544.DI ++ 343.DI, " ", (4.5.DF ++ 0.5.DF).float == 5.0

# Test borrow works with static[T], issue #6026
type 
  Currency* {.pure.} = enum
    GBP, USD
  
  CurrencyAmount*[Ccy: static[Currency]] = distinct float
  USD = CurrencyAmount[Currency.USD]
  GBP = CurrencyAmount[Currency.GBP]

# multiple ways to do the same thing, checks that all are supported
proc `+`[T: CurrencyAmount](a,b: T): T {.borrow.}
proc `-`[T: static[Currency]](a,b: CurrencyAmount[T]): CurrencyAmount[T] {.borrow.}
proc `$`(a: CurrencyAmount): string {.borrow.}

echo 50.USD + 30.USD - 20.USD
doAssert compiles(30.USD + 30.GBP) == false


# Test borrow works with var arguments and no return type, issue #3082

type
  AltString = distinct string

proc add*(x: var AltString, y: string) {.borrow.}
proc `&=`*(x: var AltString, y: string) {.borrow.}
proc `$`(x: AltString): string {.borrow.}

var a = AltString("altstring test")
a &= " 1, 2"
a.add ", 3"

echo a