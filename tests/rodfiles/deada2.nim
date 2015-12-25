discard """
  output: '''246
xyzabc
'''
"""

import deadg, deadb

# now add call to previously unused proc p2:
echo p2("xyz", "abc")
