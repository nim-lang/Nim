discard """
  file: "tminelt.nim"
  output: "SUCCESS minElm"
"""

#simple check for algo's min elt proc
import algorithm
var testArr = [100, 200, 3, 4, 5, 2 ,9]
var minElm = minElement(testArr, cmp[int])
if minElm != 2:
    echo "FAILED minELm"
else:
    echo "SUCCESS minElm"
