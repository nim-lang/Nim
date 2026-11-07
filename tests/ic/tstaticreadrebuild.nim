discard """
  description: '''IC: editing a file read by `staticRead` rebuilds its reader (#26614)'''
"""

#? metamorphic

#!FILE v.txt
one
#!FILE lib.nim
const w* = staticRead("v.txt")
#!FILE main.nim
import std/strutils
import lib
const v = staticRead("v.txt")
echo v.strip, " ", w.strip
#!STEP expect: one one

#!FILE v.txt
two
#!STEP expect: two two
