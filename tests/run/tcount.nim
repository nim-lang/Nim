discard """
  file:"tcount.nim"
  output:"SUCCESS count"
"""
import algorithm
var cntTestArr = [100, 100, 100, 0]
if count(cntTestArr, 100) != 3:
  echo "FAILED count"
else:
  echo "SUCCESS count"
