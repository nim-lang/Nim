discard """
output: '''42'''
"""

# Regression test: `{.compileTime.}` module-level globals of a NIF-loaded module
# must be initialized so macros/compile-time procs that splice them produce valid
# code. Before the eager-init fix this failed under `nim ic` with
# "attempt to access a nil address" / "illformed AST: break nil" /
# "undeclared identifier". `koch ic` only checks the compile succeeds; a nil
# global makes `defineCtgValue` emit `var <nil>: int` / `<nil> = 42` and the
# compile fails.

import mctglobal

defineCtgValue()
echo ctgValue
