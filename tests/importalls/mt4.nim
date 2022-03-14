import ./m1 {.all.} except foo1
import std/assertions

doAssert foo2 == 2
doAssert declared(foo2)
doAssert not compiles(foo1)
