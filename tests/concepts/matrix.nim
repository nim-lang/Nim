type
  Matrix*[M, N: static[int]; T] = object
    data: array[M*N, T]

proc `[]`*(M: Matrix; m, n: int): M.T =
  M.data[m * M.N + n]

proc `[]=`*(M: var Matrix; m, n: int; v: M.T) =
  M.data[m * M.N + n] = v

# Adapt the Matrix type to the concept's requirements
template Rows*(M: type Matrix): untyped = M.M
template Cols*(M: type Matrix): untyped = M.N
template ValueType*(M: type Matrix): typedesc = M.T
