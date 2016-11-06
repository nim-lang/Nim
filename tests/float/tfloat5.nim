discard """
  file: "tfloat5.nim"
  output: '''0 : 0.0
0 : 0.0
0 : 0.0
0 : 0.0'''
"""

import parseutils

var f: float
echo "*".parseFloat(f), " : ", f
echo "/".parseFloat(f), " : ", f
echo "+".parseFloat(f), " : ", f
echo "-".parseFloat(f), " : ", f
