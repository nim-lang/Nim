discard """
  targets: "cpp"
  output: "hello"
  cmd: "nim cpp --nilseqs:on --clearNimblePath --nimblePath:build/deps/pkgs $file"
"""

# bug #3299

import jester
import asyncdispatch, asyncnet

# bug #5081
#import nre

echo "hello"
