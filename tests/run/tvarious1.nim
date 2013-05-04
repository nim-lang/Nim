discard """
  file: "tlenopenarray.nim"
  output: '''1
0'''
"""

echo len([1_000_000]) #OUT 1

type 
  TArray = array[0..3, int]
  TVector = distinct array[0..3, int]
proc `[]`(v: TVector; idx: int): int = TArray(v)[idx]
var v: TVector
echo v[2]
