discard """
  joinable: false
  matrix: "--warning:ImplicitCyclicImport:on"
  nimout: "nested/mnested_d.nim(2, 8) Warning: import cycle without '.cyclic'; this is deprecated, annotate the imports on both sides of the cycle, like 'import mnested_a {.cyclic.}':"
  output: "1111"
"""

# `mnested_d` imports `mnested_a` while the group of this module and
# `mnested_a` is being checked: that is an import cycle, although
# `mnested_a` is not on the import stack.
import nested/mnested_a {.cyclic.}
import nested/mnested_c

proc fb*(): int = fc() + 10
