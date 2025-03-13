type
  Map[K, V] = concept m, var mvar
    m[K] is V
    m[K] = V

  Table[K, V] = object

proc `[]=`[K, V](m: Table[K, V], x: sink K, y: sink V) =
  let s = x

proc `[]`[K, V](m: Table[K, V], x: sink K): V =
  let s = x

proc bat[K, V](x: Map[K, V]): V =
  let m = x

var s = Table[int, string]()
discard bat(s)
