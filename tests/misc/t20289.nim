discard """
  action: reject
"""

type E[T] = object
  v: T

template j[T](R: type E[T], x: untyped): R = R(v: x)
template d[T](O: type E, v: T): E[T] = E[T].j(v)

proc w[T](): E[T] =
  template r(k: int): auto = default(T)
  E.d r

discard w[int]()
