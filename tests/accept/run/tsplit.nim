discard """
  file: "tsplit.nim"
  output: "true"
"""
import strutils

var s = ""
for w in split("|abc|xy|z", {'|'}):
  s.add("#")
  s.add(w)

if s == "#abc#xy#z":
  echo "true"
else:
  echo "false"
  
#OUT true



