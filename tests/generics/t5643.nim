type
  Matrix*[M, N: static[int], T: SomeFloat] = object
    data: ref array[N * M, T]

  Matrix64*[M, N: static[int]] = Matrix[M, N, float64]

proc zeros64(M,N: static[int]): Matrix64[M,N] =
  new result.data
  for i in 0 .. < (M * N):
    result.data[i] = 0'f64

proc bar*[M,N: static[int], T](a: Matrix[M,N,T], b: Matrix[M,N,T]) =
  discard

let a = zeros64(2,2)
bar(a,a)
  # https://github.com/nim-lang/Nim/issues/5643
  #
  # The test case was failing here, because the compiler failed to
  # detect the two matrix instantiations as the same type.
  #
  # The root cause was that the `T` type variable is a different
  # type after the first Matrix type has been matched.
  #
  # Sigmatch was failing to match the second version of `T`, but
  # due to some complex interplay between tyOr, tyTypeDesc and
  # tyGenericParam this was allowed to went through. The generic
  # instantiation of the second matrix was incomplete and the
  # generic cache lookup failed, producing two separate types.

