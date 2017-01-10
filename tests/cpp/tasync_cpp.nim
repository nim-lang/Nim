discard """
  cmd: "nim cpp $file"
  output: "hello"
"""

# bug #3299

import jester
import asyncdispatch, asyncnet

# bug #5081
#import nre

echo "hello"
