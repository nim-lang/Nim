discard """
output: '''optional-present'''
"""

# Regression test: `compiles((; import X))` must resolve identically under
# `nim ic` and whole-program compilation. `mtryimport` picks its `chosen()`
# body via `when compiles((; import moptdep))`; whole-program compilation always
# takes the `true` branch (prints "optional-present"). Under `nim ic` the
# optional module isn't scheduled, so a build-order-dependent `compiles` reports
# `false` and this prints "optional-MISSING" instead. See mtryimport.nim /
# moptdep.nim.

import mtryimport

echo chosen()
