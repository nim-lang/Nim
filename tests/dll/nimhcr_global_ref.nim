discard """
  output: "4 7"
"""

# With hot code reloading a global is reached through a pointer the runtime
# hands out. Assigning a ref to it passes its address to the `=sink` hook,
# and that took the address of the pointer instead: the hook overwrote the
# pointer, and the next read crashed. Only builds without -d:release call the
# hook there.

import nimhcr_global_ref_a

setBox(4)
let first = box.n
box = Box(n: 7)
echo first, " ", box.n
