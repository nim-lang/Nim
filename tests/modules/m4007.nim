type Vec4*[T] = array[4, T]

proc vec4*[T](x, y, z, w: T): Vec4[T] =
  Vec4[T]([x, y, z, w])

proc `addr`*[T](v: var Vec4[T]): ptr T =
  v[0].addr

proc stuff*[T](v: var Vec4[T]) = discard
