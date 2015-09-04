discard """
  file: "tbug499771.nim"
  output: '''TSubRange: 5 from 1 to 10
true true true'''
"""
type
  TSubRange = range[1 .. 10]
  TEnum = enum A, B, C
var sr: TSubRange = 5
echo("TSubRange: " & $sr & " from " & $low(TSubRange) & " to " &
     $high(TSubRange))

const cset = {A} + {B}
echo A in cset, " ", B in cset, " ", C notin cset
