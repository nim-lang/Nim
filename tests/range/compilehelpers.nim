template accept(e: expr) =
  static: assert(compiles(e))

template reject(e: expr) =
  static: assert(not compiles(e))

