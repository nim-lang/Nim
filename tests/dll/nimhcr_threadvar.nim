discard """
  output: "1 2 12 @[\"a\", \"b\"]"
"""

# With hot code reloading every module is a library of its own. A threadvar
# read from a module other than the one that declares it was referenced as an
# `extern` symbol of the program, which no library provides, so the program
# did not link.

import nimhcr_threadvar_a

let first = bump()
let second = bump()
counter += 9
remember("a")
names.add "b"
echo first, " ", second, " ", bump(), " ", names
