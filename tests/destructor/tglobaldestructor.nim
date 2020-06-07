discard """
  cmd: '''nim c --newruntime $file'''
  output: '''(v: 42)
igotdestroyed'''
"""

import objFile

echo test
