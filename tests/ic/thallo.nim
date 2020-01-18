discard """
  output: "Hello World"
"""

const str = "Hello World"
echo str

# Splitters are done with this special comment:

#!EDIT!#

discard """
  output: "Hello World B"
"""

const str = "Hello World"
echo str, " B"

#!EDIT!#

discard """
  output: "Hello World C"
"""

const str = "Hello World"
var x = 7
if 3+4 == x:
  echo str, " C"
