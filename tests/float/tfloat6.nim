discard """
disabled: "windows"
"""

import strutils

doAssert "0.00_0001".parseFloat() == 1E-6
doAssert "0.00__00_01".parseFloat() == 1E-6
doAssert "0.0_01".parseFloat() == 0.001
doAssert "0.00_000_1".parseFloat() == 1E-6
doAssert "0.00000_1".parseFloat() == 1E-6

doAssert "1_0.00_0001".parseFloat() == 10.000001
doAssert "1__00.00_0001".parseFloat() == 1_00.000001
