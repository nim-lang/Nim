discard """
  file: "compilehelpers.nim"
"""
template accept(e: expr) =
  static: doAssert(compiles(e))

template reject(e: expr) =
  static: doAssert(not compiles(e))
