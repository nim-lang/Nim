discard """
  output: '''package1/strutils
package2/strutils
noconflicts
new os.nim'''
"""

import package1/strutils as su1
import package2.strutils as su2

import os

su1.foo()
su2.foo()
echo "noconflicts"
yay()
