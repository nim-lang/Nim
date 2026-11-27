discard """
  targets: "c cpp js"
  joinable: false
  output: '''
5
base
derived
'''
"""

# The partner module is finished first and its code calls `fb` and `mk`,
# whose implementations come after other statements here, so they are not
# checked yet when the partner's code is generated: it needs prototypes.
import fwd/mfwd_codegen {.cyclic.}

proc fb*(): int
type Derived* = ref object of Base
proc mk*(): Base
discard 0
proc fb*(): int = 5
method name*(x: Derived): string = "derived"
proc mk*(): Base = Derived()
