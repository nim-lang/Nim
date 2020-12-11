##[
tests for misc pragmas that don't need a separate file
]##

block:
  static: doAssert not defined(tpragmas_misc_def)
  {.undef(tpragmas_misc_def).} # works even if not set
  static: doAssert not defined(tpragmas_misc_def)
  {.define(tpragmas_misc_def).}
  static: doAssert defined(tpragmas_misc_def)
  {.undef(tpragmas_misc_def).}
  static: doAssert not defined(tpragmas_misc_def)
