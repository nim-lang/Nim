type
  Vec*[N: static[int], T] = object
    arr*: array[N, T]

  Mat*[N,M: static[int], T] = object
    arr*: array[N, Vec[M,T]]

var m : Mat[3,3,float]
var strMat : Mat[m.N, m.M, string]
var lenMat : Mat[m.N, m.M, int]

