discard """
  errormsg: "undeclared identifier: '%'"
  line: 9
"""

import strutils except `%`

# doesn't work
echo "$1" % "abc"
