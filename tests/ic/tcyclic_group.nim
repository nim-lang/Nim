discard """
  description: '''IC vs `nim c`: a cycle group (`import m {.cyclic.}`) compiled in one process'''
"""

#? metamorphic

# The modules of an import cycle are one strongly connected component that
# `nim ic` compiles in a single `nim m --icGroup` process. With `.cyclic` the
# group's routines call each other across the cycle, so the backend has to
# agree on the main module's name with the other modules' translation units
# and must not lose the main module's top-level code.

#!FLAGS --experimental:cyclicImports

#!FILE b.nim
import main {.cyclic.}
proc fb*(): int = fa() + 10

#!FILE main.nim
import b {.cyclic.}
proc fa*(): int = 1
echo fa() + fb()
#!STEP expect: 12

#!FILE b.nim
import main {.cyclic.}
proc fb*(): int = fa() + 20
#!STEP expect: 22; body-edit

#!FILE main.nim
import b {.cyclic.}
proc fa*(): int = 1
proc fc*(): int = 100
echo fa() + fb()

#!FILE b.nim
import main {.cyclic.}
proc fb*(): int = fc() + fa()
#!STEP expect: 102; iface-edit
