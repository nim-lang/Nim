discard """
  output: '''dotdot
dotdot'''
"""

# bug #26741: `import a/../b` lexes `/../` as one infix operator; the IC
# dependency scanner joined the sides with a plain `/` and looked for `a/b`.

import nimblepath/../mimportdotdot
from nimblepath/../mimportdotdot as dd import nil

echo dotdot()
echo dd.dotdot()
