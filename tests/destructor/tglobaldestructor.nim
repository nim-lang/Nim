discard """
  cmd: '''nim c --gc:arc $file'''
  output: '''(v: 42)
igotdestroyed'''
"""

import objFile

echo test
