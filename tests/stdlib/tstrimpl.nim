import std/private/strimpl

doAssert find(cstring"Hello Nim", cstring"Nim") == 6
doAssert find(cstring"Hello Nim", cstring"N") == 6
doAssert find(cstring"Hello Nim", cstring"I") == -1
doAssert find(cstring"Hello Nim", cstring"O") == -1
