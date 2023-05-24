discard """
  matrix: "--mm:refc; --mm:orc"
"""

import std/private/strimpl

import std/assertions

doAssert find(cstring"Hello Nim", cstring"Nim") == 6
doAssert find(cstring"Hello Nim", cstring"N") == 6
doAssert find(cstring"Hello Nim", cstring"I") == -1
doAssert find(cstring"Hello Nim", cstring"O") == -1
