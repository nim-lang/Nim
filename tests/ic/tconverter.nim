discard """
  output: "yes"
"""

import mdefconverter

echo "yes"

#!EDIT!#

discard """
  output: "converted int to bool"
"""

import mdefconverter

if 4:
  echo "converted int to bool"
