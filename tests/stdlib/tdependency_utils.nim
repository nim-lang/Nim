import std/private/dependency_utils

doAssert not compiles(addDependency("nonexistant"))

static:
  addDependency("dragonbox")
  addDependency("dragonbox") # make sure can be called twice
