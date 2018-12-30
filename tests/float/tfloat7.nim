discard """
output: '''
passed.
passed.
passed.
passed.
passed.
passed.
passed.
'''
"""

import strutils
template expect_fail(x) =
  try:
    discard x
    echo("expected to fail!")
  except ValueError:
    echo("passed.")

expect_fail("1_0._00_0001".parseFloat())
expect_fail("_1_0_00.0001".parseFloat())
expect_fail("10.00.01".parseFloat())
expect_fail("10.00E_01".parseFloat())
expect_fail("10.00E_01".parseFloat())
expect_fail("10.00E".parseFloat())
expect_fail("10.00A".parseFloat())
