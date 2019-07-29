import std/macros
import std/sugar

{.push experimental: "aliasSym".}

proc fun0(a: int): auto = $a
template fun3(a: int): untyped = $a
template fun3(a = 1.2): untyped = $a

proc main1() =
  proc fun0(a: float): auto = $a
  proc fun0(a: bool): auto = $a

  block: # works with macros, even with all optional parameters
    macro fun2(a = 10, b = 11): untyped = quote do: (`a`,`b`)
    alias: fun2a=fun2
    doAssert fun2a() == (10, 11)
    doAssert fun2a(12) == (12, 11)
    block:
      doAssert fun2a(12) == (12, 11)

  block: # ditto with templates
    template fun2(a = 10, b = 11): untyped = (a,b)
    alias:fun2a=fun2
    doAssert fun2a(12) == (12, 11)
    doAssert fun2a() == (10, 11)

  block: # works with types
    alias:int2=system.int
    doAssert int2 is int

  block: # ditto
    alias:int2=int
    doAssert int2 is int

  block: # works with modules
    alias:system2=system
    doAssert system2.int is int
    alias:int2=system2.int
    doAssert int2 is int

  block: # usage of alias is identical to usage of aliased symbol
    alias:currentSourcePath2=system.currentSourcePath
    doAssert currentSourcePath2 == currentSourcePath
    doAssert currentSourcePath2() == currentSourcePath()

  block: # works with overloaded symbols
    alias:toStr=`$`
    doAssert 12.toStr == "12"
    doAssert true.toStr == "true"

  block: # CT error if symbol does not exist in scope
    doAssert compiles(block: alias: echo2=echo)
    doAssert not compiles(block: alias: echo2=echoNonexistant)
    alias: echo2=echo
    doAssert compiles(echo2())
  doAssert not compiles(echo2()) # echo2 not in scope anymore

  block: # works with variables
    var x = @[1,2,3]
    alias: xa=x
    xa[1] = 10
    doAssert x == @[1,10,3]
    doAssert not compiles(block: alias: xa2=x[1])
    when false:
      alias: xa=x # correctly would give: Error: redefinition of 'xa'

  block: # works with const
    const L = 12
    alias: L2=L
    const L3 = L2
    doAssert L3 == L

  block: # works with overloaded symbols, including local overloads, including generics
    proc fun0[T](a: T, b: float): auto = $(a,b)
    alias: fun0a=fun0
    doAssert fun0a(true) == "true"
    doAssert fun0a(1.2) == "1.2"
    doAssert fun0a(1, 2.0) == "(1, 2.0)"

  block: # works with overloaded templates
    alias: fun3a=fun3
    doAssert fun3a(12.1) == "12.1"
    doAssert fun3a() == "1.2"

  block: # works with iterator
    iterator fun4(): auto =
      yield 10
      yield 3
    alias: fun4a = fun4
    var s: seq[int]
    for ai in fun4a(): s.add ai
    doAssert s == [10,3]

  block: # works with generics
    proc fun5[T](a: T): auto = a
    alias: fun5a = fun5
    doAssert fun5a(3.2) == 3.2

proc main2() = # using `alias` avoids the issues mentioned in #8935
  # const myPrint = echo # Error: invalid type for const: proc
  # let myPuts = system.echo # Error: invalid type: 'typed'
  alias: myPrint=echo # works
  # myPrint (1,2)
  doAssert compiles(myPrint (1,2))
  when false:
    const testForMe = assert
    testForMe(1 + 1 == 2)  # Error: VM problem: dest register is not set

  alias: testForMe=assert
  testForMe(1 + 1 == 2)
  doAssertRaises(AssertionError): testForMe(1 + 1 == 3)

block: # somewhat related to #11047
  proc foo(): int {.compileTime.} = 100
  # var f {.compileTime.} = foo # would give: Undefined symbols error
  # let f {.compileTime.} = foo # would give: Undefined symbols error
  # const f = foo # this would work
  alias: f=foo
  doAssert f() == 100
  static: doAssert f() == 100

block: # fix https://forum.nim-lang.org/t/5015
  proc getLength(i: int): int = sizeof(i)
  proc getLength(s: string): int = s.len
  # const length = getLength # Error: cannot generate VM code for getLength
  alias: length = getLength # works
  doAssert length("alias") == 5

block: # works with `result` variable too, as asked here:
       # https://forum.nim-lang.org/t/5015#31650
  proc foo(): string =
    alias: r=result
    r.add "ba"
    r.add "bo"
  doAssert foo() == "babo"

import ./malias2
doAssert fun6a() == 42

main1()
main2()
