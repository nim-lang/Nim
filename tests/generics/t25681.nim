discard """
  matrix: "--warningAsError:UnusedImport:on"
  output: '''
@[1, 3, 99]
'''
"""

# bug #25681: the import of `enumutils` in `m25681` provides the implicit
# `items` of the generic and so it is used
import m25681

type F {.pure.} = enum
  a = 3, b = 1, c = 99

echo test(F)
