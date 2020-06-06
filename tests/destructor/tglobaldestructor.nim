discard """
  cmd: '''nim c --newruntime $file'''
  output: '''
igotdestroyed
(v: 42)
igotdestroyed
'''
"""

import objFile

echo test
