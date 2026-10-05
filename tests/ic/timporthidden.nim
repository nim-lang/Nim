discard """
output: '''42'''
"""

# `import x {.all.}` makes x's PRIVATE symbols visible. Under IC that means the
# hidden half of a loaded module's interface has to be there — and it is now
# built on demand rather than at load time, because almost nothing ever reads it
# (1.70M hidden stubs against 0.29M exported ones on a cold Atlas build).
#
# The trap the first attempt fell into: a module has TWO FileIndexes. `c.mods`
# in the decode context is keyed by the one `registerNifSuffix` mints for the
# NIF suffix; `g.ifaces` is indexed by the module's source file. Asking one with
# the other misses silently, and this test is what says so.

import mimporthidden {.all.}

echo secret() + hiddenToo(35)
