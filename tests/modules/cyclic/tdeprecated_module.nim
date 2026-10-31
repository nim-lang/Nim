discard """
  joinable: false
  nimout: "tdeprecated_module.nim(11, 15) Warning: use something else; mdeprecated_module is deprecated [Deprecated]"
  output: "2"
"""

# The pragmas before the first import of a module of the group run before the
# imports of the group: the module is deprecated by the time this module
# imports it.

import pragmas/mdeprecated_module {.cyclic.}

proc fa*(): int = fb()
echo fa()
