discard """
  output: '''
0.000001 : 0.000001
0.000001 : 0.000001
0.001 : 0.001
0.000001 : 0.000001
0.000001 : 0.000001
10.000001 : 10.000001
100.000001 : 100.000001
'''
  disabled: "windows"
"""

import strutils

echo "0.00_0001".parseFloat(), " : ", 1E-6
echo "0.00__00_01".parseFloat(), " : ", 1E-6
echo "0.0_01".parseFloat(), " : ", 0.001
echo "0.00_000_1".parseFloat(), " : ", 1E-6
echo "0.00000_1".parseFloat(), " : ", 1E-6

echo "1_0.00_0001".parseFloat(), " : ", 10.000001
echo "1__00.00_0001".parseFloat(), " : ", 1_00.000001

# bug #18148

var a = 1.1'f32
doAssert $a == "1.1", $a # fails
