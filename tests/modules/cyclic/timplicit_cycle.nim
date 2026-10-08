discard """
  joinable: false
  matrix: "--warning:ImplicitCyclicImport:on"
  nimout: "mimplicit_cycle.nim(1, 8) Warning: import cycle without '.cyclic'; this is deprecated, use 'import timplicit_cycle {.cyclic.}':"
  output: '''
b
main 2
'''
"""

import mimplicit_cycle

proc fa*(): int = 1

echo "main ", fb()
