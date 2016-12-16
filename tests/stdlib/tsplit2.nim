discard """
  file: "tsplit2.nim"
  output: "true"
"""
import strutils

var s = ""
for w in split("|abc|xy|z", {'|'}):
  s.add("#")
  s.add(w)

try:
  discard "hello".split("")
  echo "false"
except ValueError:
  echo "true"

#OUT true

