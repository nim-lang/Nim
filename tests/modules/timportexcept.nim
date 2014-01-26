discard """
  line: 9
  errormsg: "undeclared identifier: '%'"
"""

import strutils except `%`

# doesn't work
echo "$1" % "abc"

