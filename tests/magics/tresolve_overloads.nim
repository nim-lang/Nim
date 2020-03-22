#[
use -d:nimTestsResolvesDebug to make the `inspect` macro print debug info showing
resolved symbol locations, for example:

`inspect resolveSymbol(`$`)` would print:

Nim/tests/magics/tresolve_overloads.nim:133:28: $ = closedSymChoice:
  Nim/lib/system/dollars.nim:124:1 proc `$`[T](x: set[T]): string
  Nim/lib/system/dollars.nim:140:1 proc `$`[T; U](x: HSlice[T, U]): string
  Nim/lib/system/dollars.nim:14:1 proc `$`(x: bool): string {.magic: "BoolToStr", noSideEffect.}
]#

import ./mresolves
import ./mresolve_overloads

template bail() = static: doAssert false

proc funDecl1(a: int) {.importc.}
proc funDecl2(a: int)

proc fun(a: int) = discard

template fun2(a = 0) = bail()
template fun3() = bail()

proc fun4(a: float) = discard

proc fun4[T](a: T) =
  static: echo "in fun4"
  bail()

macro fun5(a: typed): untyped = discard
macro fun6(a: untyped): untyped = discard
iterator fun7(a: int): auto = yield 1

proc fun8(a: int): auto = (a, "int")
proc fun8(a: float): tuple = (a,"float")
template fun8(a: string) = discard
template fun8(a: char = 'x') = discard
template fun8() = discard
macro fun8(b = 1'u8): untyped = discard
macro fun8(c: static bool): untyped = discard

proc fun8(d: var int) = d.inc

proc fun10[T: seq](a: T): auto = (a,)
proc fun10[T: int|float](a: T): auto = (a,)
template fun11(a: untyped): auto = (a,)

proc main()=
  block: # overloadExists with nkCall
    doAssert overloadExists(fun4(1))
    doAssert not compiles(fun4(1))
    doAssert overloadExists(fun4(1))
    doAssert overloadExists(fun4(1.2))
    doAssert not overloadExists(fun4())
    doAssert not overloadExists(1 @@@ 2)
    doAssert overloadExists(1 + 2)
    doAssert not overloadExists('a' + 2.0)

    doAssert overloadExists(funDecl1(1))
    doAssert not overloadExists(funDecl1(1.0))
    doAssert overloadExists(funDecl2(1))

    doAssert overloadExists(fun(1))
    doAssert overloadExists(1+1)
    doAssert not overloadExists('a'+1.2)

    doAssert not overloadExists(fun(1.1))
    doAssert not overloadExists(fun(1, 2))
    doAssert overloadExists(fun2())
    doAssert overloadExists(fun2(1))
    doAssert overloadExists(fun3())
    doAssert not overloadExists(fun3(1))

    # subtlety: if arguments for a `typed` formal param are not well typed,
    # we error instead of return false
    doAssert not compiles overloadExists(fun5(1 + 'a'))

    doAssert overloadExists(fun5(1 + 1))
    doAssert not overloadExists(fun5(1 + 1, 2))
    doAssert overloadExists(fun6(1 + 'a'))
    doAssert not overloadExists(fun6(1 + 'a', 2))
    doAssert overloadExists(fun7(1))
    doAssert not overloadExists(fun7())

    # generics
    doAssert overloadExists(fun10(@[1]))
    doAssert overloadExists(fun10(1.2))
    doAssert not overloadExists(fun10("foo"))
    doAssert not overloadExists(fun10('a'))
    template fun10(a: char): auto = (a,)
    doAssert overloadExists(fun10('a'))
    doAssert not overloadExists(fun11())
    doAssert overloadExists(fun11(1 + 'a'))

    # $
    doAssert overloadExists($12)
    doAssert not overloadExists($main)
    # echo
    doAssert overloadExists(echo 12)
    doAssert overloadExists(echo ())
    doAssert overloadExists(echo())
    doAssert not overloadExists(echo main)
    doAssert not overloadExists(echo(main))

  block: # overloadExists with nkCall dot accesors
    type Foo = object
      bar1: int
    var foo: Foo

    template bar2(a: Foo) = discard
    template bar3[T](a: T): int = 0

    proc bar4(a: int) = discard

    template bar5(a: int) = discard
    template bar5(a: Foo) = discard

    doAssert not declared(mresolve_overloads.nonexistant)
    doAssert declared(mresolve_overloads.mfoo3)
    doAssert not declared(foo.bar1)
    doAssert not overloadExists(mresolve_overloads.nonexistant)
    doAssert overloadExists(mresolve_overloads.mfoo3)

    doAssert not overloadExists(nonexistant(foo))
    doAssert not overloadExists(nonexistant())

    doAssert not overloadExists(foo.nonexistant)
    doAssert compiles(Foo().bar1)
    doAssert compiles(Foo().bar1)
    doAssert overloadExists(foo.bar2)
    doAssert overloadExists(foo.bar3)

    doAssert not overloadExists(bar4(foo))
    doAssert not overloadExists(foo.bar4)

    proc bar4(a: Foo) = discard

    doAssert overloadExists(foo.bar4)
    doAssert overloadExists(foo.bar5)

    doAssert overloadExists(foo.bar1)
    doAssert overloadExists(Foo().bar1)

    doAssert not compiles(nonexistant.bar1)
    doAssert not compiles overloadExists(nonexistant.bar1)
    doAssert not compiles overloadExists(nonexistant().mfoo1)
    doAssert not compiles overloadExists(nonexistant1().nonexistant2)
    doAssert not compiles overloadExists(nonexistant().bar2)
    doAssert not compiles overloadExists(nonexistant().bar1)

    doAssert declared(mresolve_overloads)
    doAssert declared(fun7)
    doAssert declared(foo)
    doAssert declared(`bar5`)
    doAssert declared(bar5)
    doAssert declared(`system`)
    doAssert not declared(nonexistant)
    doAssert not overloadExists(nonexistant)
    doAssert not overloadExists(`nonexistant`)
    doAssert overloadExists(system)
    doAssert overloadExists(`system`)
    doAssert overloadExists(`bar5`)
    doAssert overloadExists(bar5)

  block: # resolveSymbol
    doAssert resolveSymbol(fun8(1))(3) == fun8(3)
    inspect resolveSymbol(fun8)

    inspect resolveSymbol(fun7)
    inspect resolveSymbol(fun8(1))
    inspect resolveSymbol(fun8(1.2))
    inspect resolveSymbol(fun8("asdf"))
    inspect resolveSymbol(fun8('a'))
    doAssert compiles(resolveSymbol(fun8('a')))
    doAssert not compiles(resolveSymbol(fun8())) # correctly would give ambiguous error
    inspect resolveSymbol(fun8(b = 1))
    inspect resolveSymbol(fun8(c = false))
    inspect resolveSymbol(1.1 / 2.0)

  block:
    var c1 = false
    doAssert not overloadExists(fun8(c = c1))
    const c2 = false
    doAssert overloadExists(fun8(c = c2))
    var c3 = 10
    doAssert overloadExists(fun8(d = c3))
    doAssert c3 == 10
    resolveSymbol(fun8(d = c3))(d = c3)
    doAssert c3 == 11
    let t = resolveSymbol(fun8(d = c3))
    doAssert type(t) is proc
    t(d = c3)
    doAssert c3 == 12

  block:
    var z = 10
    proc fun9(z0: int) = z+=z0
    proc fun9(z0: float) = doAssert false
    let t = resolveSymbol(fun9(12))
    # can't work with `const t = fun9`: invalid type for const
    doAssert type(t) is proc
    t(3)
    doAssert z == 10+3
    inspect resolveSymbol(fun9(12))
    inspect(resolveSymbol(t), resolveLet=true)

import std/strutils
import std/macros
import std/macros as macrosAlias

proc main2()=
  block:
    inspect resolveSymbol(`@@@`)

    let t = resolveSymbol toUpper("asdf")
    inspect resolveSymbol(t), resolveLet=true
    doAssert t("asdf") == "ASDF"
    let t2 = resolveSymbol strutils.toUpper("asdf")
    inspect resolveSymbol(t2), resolveLet=true
    doAssert t2("asdf") == "ASDF"

    inspect resolveSymbol(strutils.toUpper)
    inspect resolveSymbol(strutils.`toUpper`)
    inspect resolveSymbol(`toUpper`)
    # overloaded
    inspect resolveSymbol(`$`)
    inspect resolveSymbol(system.`$`)

    doAssert compiles resolveSymbol(system.compiles)
    inspect resolveSymbol(system.compiles)
    doAssert resolveSymbol(system.nonexistant) == nil
    doAssert resolveSymbol(nonexistant) == nil

  block:
    template bar1(): untyped = 12
    inspect resolveSymbol(bar1)
    inspect resolveSymbol(currentSourcePath)
    inspect resolveSymbol(system.currentSourcePath)
    doAssert resolveSymbol(system.currentSourcePath)() == currentSourcePath()
    inspect resolveSymbol(system.uint16)
    inspect resolveSymbol(system.cint)
    inspect resolveSymbol(cint)
    inspect resolveSymbol(system.off)
    inspect resolveSymbol(newLit(true))
    inspect resolveSymbol(mfoo1)
    inspect resolveSymbol(mfoo2)
    inspect resolveSymbol(mfoo3)
    inspect resolveSymbol(mresolve_overloads.mfoo3)
    inspect resolveSymbol(macros.nnkCallKinds)

    ## module
    inspect resolveSymbol(macros)
    inspect resolveSymbol(macrosAlias)

proc funDecl2(a: int) = discard

main()
static: main()
main2()
