import std/macros

proc fun0(a: int): auto = $a
template fun3(a: int): untyped = $a
template fun3(a = 1.2): untyped = $a

proc main() =
  proc fun0(a: float): auto = $a
  proc fun0(a: bool): auto = $a

  block: # works with macros, even with all optional parameters
    macro fun2(a = 10, b = 11): untyped = quote do: (`a`,`b`)
    fun2a:=fun2
    doAssert fun2a() == (10, 11)
    doAssert fun2a(12) == (12, 11)
    block:
      doAssert fun2a(12) == (12, 11)

  block: # ditto with templates
    template fun2(a = 10, b = 11): untyped = (a,b)
    fun2a:=fun2
    doAssert fun2a(12) == (12, 11)
    doAssert fun2a() == (10, 11)

  block: # works with types
    int2:=system.int
    doAssert int2 is int

  block: # ditto
    int2:=int
    doAssert int2 is int

  block: # works with modules
    system2:=system
    doAssert system2.int is int
    int2:=system2.int
    doAssert int2 is int

  block: # usage of alias is identical to usage of aliased symbol
    currentSourcePath2:=system.currentSourcePath
    doAssert currentSourcePath2 == currentSourcePath
    doAssert currentSourcePath2() == currentSourcePath()

  block: # works with overloaded symbols
    toStr:=`$`
    doAssert 12.toStr == "12"
    doAssert true.toStr == "true"

  block: # CT error if symbol does not exist in scope
    doAssert compiles(echo2:=echo)
    doAssert not compiles(echo2:=echo_nonexistant)
    echo2:=echo
    doAssert compiles(echo2())
  doAssert not compiles(echo2()) # echo2 not in scope anymore

  block: # works with variables
    var x = @[1,2,3]
    xa:=x
    xa[1] = 10
    doAssert x == @[1,10,3]
    doAssert not compiles(xa2:=x[1])
    when false:
      xa:=x # correctly would give: Error: redefinition of 'xa'
      # doAssert not compiles(xa:=x) # we can't test that using `compiles` though

  block: # works with const
    const L = 12
    L2:=L
    const L3 = L2
    doAssert L3 == L

  block: # works with overloaded symbols, including local overloads, including generics
    proc fun0[T](a: T, b: float): auto = $(a,b)
    fun0a:=fun0
    doAssert fun0a(true) == "true"
    doAssert fun0a(1.2) == "1.2"
    doAssert fun0a(1, 2.0) == "(1, 2.0)"

  block: # works with overloaded templates
    fun3a:=fun3
    doAssert fun3a(12.1) == "12.1"
    doAssert fun3a() == "1.2"

  block: # works with iterator
    iterator fun4(): auto =
      yield 10
      yield 3
    fun4a := fun4
    var s: seq[int]
    for ai in fun4a(): s.add ai
    doAssert s == [10,3]

main()
