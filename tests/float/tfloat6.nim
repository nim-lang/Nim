discard """
  output: '''
1e-06 : 1e-06
1e-06 : 1e-06
0.001 : 0.001
1e-06 : 1e-06
1e-06 : 1e-06
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
