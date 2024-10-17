block: # issue #13799
  type
    X[A, B] = object
      a: A
      b: B

    Y[A] = X[A, int]
  template s(T: type X): X = T()
  template t[A, B](T: type X[A, B]): X[A, B] = T()
  proc works1(): Y[int] = s(X[int, int])
  proc works2(): Y[int] = t(X[int, int])
  proc works3(): Y[int] = t(Y[int])
  proc broken(): Y[int] = s(Y[int])
