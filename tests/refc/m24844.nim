type
  S*[T] = ref object of RootObj
    k: string
  A*[T] = ref object of S[T]

proc p*[T](): S[T] = S[T]()
proc u*() = discard A[int]()
discard A[int]()