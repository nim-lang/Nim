discard """
  output: '''
before tensor2:
[0.0, 1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0, 9.0, 10.0, 11.0, 12.0, 13.0, 14.0, 15.0, 16.0, 17.0, 18.0, 19.0, 20.0, 21.0, 22.0, 23.0]
before tensor3:
[0.0, 1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0, 9.0, 10.0, 11.0, 12.0, 13.0, 14.0, 15.0, 16.0, 17.0, 18.0, 19.0, 20.0, 21.0, 22.0, 23.0, 24.0, 25.0, 26.0]
after tensor3:
[0.0, 1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0, 9.0, 10.0, 11.0, 12.0, 13.0, 14.0, 15.0, 16.0, 17.0, 18.0, 19.0, 20.0, 21.0, 22.0, 23.0, 24.0, 25.0, 26.0]
a3:
[1000.0, 1001.0, 1002.0, 1003.0, 1004.0, 1005.0, 1006.0, 1007.0, 1008.0, 1009.0, 1010.0, 1011.0, 1012.0, 1013.0, 1014.0, 1015.0, 1016.0, 1017.0, 1018.0, 1019.0, 1020.0, 1021.0, 1022.0, 1023.0, 1024.0, 1025.0, 1026.0]'''
"""

import macros

type
  Tensor[Dim : static[int]] = object
    data: array[Dim, float64]

proc transpose(tensor: Tensor): Tensor =
  # fake implementation, don't transpose anything at all
  # just do something to see a change happening
  for i in 0 ..< tensor.data.len:
    result.data[i] = 1000 + tensor.data[i]

var tensor2: Tensor[24]
var tensor3: Tensor[27]

for i, x in tensor2.data.mpairs():
  x = float64(i)

for i, x in tensor3.data.mpairs():
  x = float64(i)

echo "before tensor2:\n", tensor2.data.repr
echo "before tensor3:\n", tensor3.data.repr

var a3 = transpose(tensor3)
echo "after tensor3:\n", tensor3.data.repr
echo "a3:\n", a3.data.repr
