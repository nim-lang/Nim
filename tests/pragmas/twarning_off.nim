discard """
  nimout: '''
compile start
Hint: warn_module [Processing]
Hint: hashes [Processing]
warn_module.nim(6, 6) Hint: 'test' is declared but not used [XDeclaredButNotUsed]
compile end
'''
"""

static:
  echo "compile start"

import warn_module

static:
  echo "compile end"
