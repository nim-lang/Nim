discard """
  file:"trotate.nim"
  output:"SUCCESS rotate"
"""
import algorithm
var testRot = [1,2,3,4,5,6,7]
rotate(testRot, 0, 3, len(testRot))
if testRot != [4,5,6,7,1,2,3]:
  echo "FAILED rotate"
else:
  echo "SUCCESS rotate"
