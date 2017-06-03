import sequtils,math

type Matrix*[M,N: static[int];T:SomeNumber] = array[M, array[N, T]]
 
template toMat[M,N,T](iter: untyped): untyped =
  when compiles(iter.len):
    var i = 0
    var result:Matrix[M,N,T] 
    for x in iter:
      result[i] = x
      inc i
    result
  else:
    var result: Matrix[M,N,T] 
    for x in iter:
      result.add(x)
    result

proc `$`*(m: Matrix): string =
  result = "(["
  for arr in m:
    if result.len > 2: result.add "]\n ["
    for i in arr.low..arr.high: 
      if i < arr.high: result.add $arr[i]&" "
      else : result.add $arr[i]
  result.add "])"
 
proc `*`*[M,P,N,T](a: Matrix[M,P,T]; b: Matrix[P,N,T]): Matrix[M,N,T] =
  for i in result.low .. result.high:
    for j in result[0].low .. result[0].high:
      for k in a[0].low .. a[0].high:
        result[i][j] += a[i][k] * b[k][j]
 
proc transpose*[M, N,T](m: Matrix[M,N,T]): Matrix[N,M,T] =
  for i in result.low .. result.high:
    for j in result[0].low .. result[0].high:
      result[i][j] = m[j][i]

proc `+`*[M,N,T](a, b: Matrix[M,N,T]): Matrix[M,N,T]=
  for i in result.low .. result.high:
    for j in result[0].low .. result[0].high:
        result[i][j] = a[i][j] + b[i][j]

proc `-`*[M,N,T](a, b: Matrix[M,N,T]): Matrix[M,N,T]=
  for i in result.low .. result.high:
    for j in result[0].low .. result[0].high:
        result[i][j] = a[i][j] - b[i][j]

proc `-`*[M,N,T](m: Matrix[M,N,T]): Matrix[M,N,T]=
  for i in result.low .. result.high:
    for j in result[0].low .. result[0].high:
        result[i][j] = -m[i][j]

proc `*`*[M,N,T](a: Matrix[M,N,T]; k:T): Matrix[M,N,T]=
  for i in result.low .. result.high:
    for j in result[0].low .. result[0].high:
        result[i][j] = k*a[i][j]

proc `**`*[M,N,T](a: Matrix[M,N,T]; k:float64): Matrix[M,N,float64]=
  for i in result.low .. result.high:
    for j in result[0].low .. result[0].high:
        result[i][j] = pow(float64(a[i][j]),k)

when isMainModule:
  let a = [[1.0,  1.0,  1.0,   1.0],
         [2.0,  4.0,  8.0,  16.0],
         [3.0,  9.0, 27.0,  81.0],
         [4.0, 16.0, 64.0, 256.0]]
 
  let b = [[  4.0  , -3.0  ,  4/3.0,  -1/4.0 ],
         [-13/3.0, 19/4.0, -7/3.0,  11/24.0],
         [  3/2.0, -2.0  ,  7/6.0,  -1/4.0 ],
         [ -1/6.0,  1/4.0, -1/6.0,   1/24.0]]

  let x = [[1,2,3],[4,5,6]]
  let y = [[1,4],[2,5],[3,6]]
  let z = [[0, 1, 2, 3, 4],
           [5, 6, 7, 8, 9],
           [1, 0, 0, 0,42]]

  assert x * y == [[14,32],[32,77]] 
  echo transpose(z)
  echo x+x
  echo x*y
  echo x-x
  echo -x
  echo x ** 2