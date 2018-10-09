template accept(e) =
  static: assert(compiles(e))

template reject(e) =
  static: assert(not compiles(e))
