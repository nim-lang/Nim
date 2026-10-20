discard """
  output: "10 12 10 base"
"""

# With hot code reloading, the dispatcher of a method is generated into the
# main module, which is not reloadable. The other modules must reach it
# through the HCR runtime: the module of the base method failed to compile
# (it called a `_actual` function that only the main module defines), and
# other modules called through a pointer that was never set. The main module
# registers every dispatcher, also one that it does not call itself.

import nimhcr_methods_a, nimhcr_methods_b

let t: Base = Derived()
echo t.send(1), " ", t.sendTwo(1, 2), " ", t.sendThrough(1), " ", t.describeThrough()
