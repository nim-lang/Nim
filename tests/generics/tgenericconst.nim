discard """
output: '''
@[1, 2]
@[3, 4]
1
'''
"""

# https://github.com/nim-lang/Nim/issues/5756

type
  Vec*[N : static[int]] = object
    x: int
    arr*: array[N, int32]

  Mat*[M,N: static[int]] = object
    x: int
    arr*: array[M, Vec[N]]

proc vec2*(x,y:int32) : Vec[2] =
  result.arr = [x,y]
  result.x = 10

proc mat2*(a,b: Vec[2]): Mat[2,2] =
  result.arr = [a,b]
  result.x = 20

const M = mat2(vec2(1, 2), vec2(3, 4))

let m1 = M
echo @(m1.arr[0].arr)
echo @(m1.arr[1].arr)

proc foo =
  let m2 = M
  echo m1.arr[0].arr[0]

foo()

