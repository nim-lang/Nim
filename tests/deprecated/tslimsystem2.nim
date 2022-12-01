{.warningAsError[Deprecated]: on.}

let comp1 = compiles do: doAssert true
let comp2 = compiles do: assertions.doAssert true
import std/assertions
doAssert true
doAssert (compiles do: assertions.doAssert true)
doAssert not comp1
doAssert not comp2
import system # refs #20967: system is deprecated
