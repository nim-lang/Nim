discard """
  output: '''
abcde
0
'''
  cmd: "nim c --gc:arc $file"
"""

import amodule
