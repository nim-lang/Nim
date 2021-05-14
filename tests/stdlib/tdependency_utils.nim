import std/private/dependency_utils

when false:
  # pending https://github.com/timotheecour/Nim/issues/731
  doAssert not compiles(addDependency("nonexistant"))

static:
  addDependency("dragonbox")
  addDependency("dragonbox") # make sure can be called twice
