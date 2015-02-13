discard """
  output: '''TMatrix[3, 3, system.int]
3'''
"""

import typetraits

type
  TMatrix*[N,M: static[int], T] = object
    data*: array[0..N*M-1, T]

  TMat2[T] = TMatrix[2,2,T]

proc echoMatrix(a: TMatrix) =
  echo a.type.name
  echo TMatrix.N

proc echoMat2(a: TMat2) =
  echo TMat2.M
  
var m = TMatrix[3,3,int](data: [1,2,3,4,5,6,7,8,9])

echoMatrix m
#echoMat2 m

