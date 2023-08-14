discard """
  exitcode: 1
  output: '''
First top-level statement of ModuleB
m22469.nim(3)            m22469
fatal.nim(53)            sysFatal
Error: unhandled exception: over- or underflow [OverflowDefect]
'''
"""

# bug #22469

# ModuleA
import m22469
echo "ModuleA about to have exception"
echo high(int) + 1
