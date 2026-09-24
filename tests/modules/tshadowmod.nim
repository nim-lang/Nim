discard """
  output: '''template:module:x
module:y'''
"""

# bug: `import shadowmod` and `template shadowmod` both land in the top level
# scope, but a template that takes parameters cannot be an expression on its
# own, so the `shadowmod` on the left of `shadowmod.shadowmod(s)` is the
# imported module and the call is qualified. `tmemshadow` is the other side of
# this: there the declaration takes no parameters and wins.

import mshadowmod as shadowmod

template shadowmod(data: string): string =
  "template:" & shadowmod.shadowmod(data)

echo shadowmod("x")
echo shadowmod.shadowmod("y")
