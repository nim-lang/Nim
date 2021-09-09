discard """
  nimout: '''
compile start
warn_module.nim(6, 6) Hint: 'test' is declared but not used [XDeclaredButNotUsed]
'''
"""

static:
  echo "compile start"

import warn_module
