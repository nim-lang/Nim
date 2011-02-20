discard """
  file: "tbug499771.nim"
  output: "TSubRange: 5 from 1 to 10"
"""
type TSubRange = range[1 .. 10]
var sr: TSubRange = 5
echo("TSubRange: " & $sr & " from " & $low(TSubRange) & " to " & 
     $high(TSubRange))




