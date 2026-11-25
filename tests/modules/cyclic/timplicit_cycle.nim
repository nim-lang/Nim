discard """
  joinable: false
  matrix: "--warning:ImplicitCyclicImport:on"
  nimout: "mimplicit_cycle.nim(1, 8) Warning: import cycle without '.cyclic'; this is deprecated, annotate the imports on both sides of the cycle, like 'import timplicit_cycle {.cyclic.}':"
  output: '''
b
main 2
'''
"""

import mimplicit_cycle

proc fa*(): int = 1

echo "main ", fb()
