discard """
  output: "56"
"""

# bug #1781

proc initCombinations: array[11, array[11, int]] =
  result[0]          = [1,2,3,4,5,6,7,8,9,10,11]
  result[1][1 .. 10] =   [12,13,14,15,16,17,18,19,20,21]
  result[2][2 .. 10] =     [22,23,24,25,26,27,28,29,30]
  result[3][3 .. 10] =       [31,32,33,34,35,36,37,38]
  result[4][4 .. 10] =         [39,40,41,42,43,44,45]
  result[5][5 .. 10] =           [46,47,48,49,50,51]
  result[6][6 .. 10] =             [52,53,54,55,56]

const combinations = initCombinations()
echo combinations[6][10]
