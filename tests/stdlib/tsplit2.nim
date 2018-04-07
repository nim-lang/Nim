discard """
  file: "tsplit2.nim"
  output: "true"
"""
import strutils

var s = ""
for w in split("|abc|xy|z", {'|'}):
  s.add("#")
  s.add(w)

echo "hello".split("") == @["hello"]

#OUT true
