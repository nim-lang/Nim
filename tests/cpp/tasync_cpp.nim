discard """
  targets: "cpp"
  output: "hello"
  cmd: "nim cpp --nilseqs:on --nimblePath:tests/deps $file"
"""

# bug #3299

import jester
import asyncdispatch, asyncnet

# bug #5081
#import nre

echo "hello"
