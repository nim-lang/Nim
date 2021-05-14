import std/private/deputils

doAssert not compiles(addDependency("nonexistant"))

static:
  addDependency("dragonbox")
  addDependency("dragonbox") # make sure can be called twice
