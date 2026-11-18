# bug #11052: a proc with the same name as its module
import std/macros
import m11052/module

doAssert module() == "ran"
doAssert module.module() == "ran"
doAssert not compiles(module.module.module())

macro hasImpl(pro: typed{nkSym}): bool =
  newLit(pro.getImpl != nil)

doAssert hasImpl(module.module)
