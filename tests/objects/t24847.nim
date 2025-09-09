# issue #24847

block: # original issue test
  type
    R[C] = ref object of RootObj
      b: C
    K[S] = ref object of R[S]
    W[J] = object
      case y: bool
      of false, true: discard

  proc e[T]() = discard K[T]()
  iterator h(): int {.closure.} = e[W[int]]()
  let _ = h
  type U = distinct int
  e[W[U]]()

block: # simplified
  type
    R[C] = ref object of RootObj
      b: C
    K[S] = ref object of R[S]
    W[J] = object
      case y: bool
      of false, true: discard

  type U = distinct int

  discard K[W[int]]()
  discard K[W[U]]()
