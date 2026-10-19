discard """
  output: '''
1
1
1
2
1
1
'''
"""

# A proc type param whose formal mentions a generic invocation (`seq[Box[T]]`)
# can match with isEqual before the formal is instantiated; the backend type
# alias check must compare against the instantiated formal.

type Box[T] = object
  item: T

proc take[T](x: T, cb: proc(v: seq[Box[T]])) =
  cb(@[Box[T](item: x)])

take(1, proc(v: seq[Box[int]]) = echo v.len)

proc outer[T](x: T) =
  take(x, proc(v: seq[Box[T]]) = echo v.len)

outer("a")

block lent_return:
  let g = @[Box[int](item: 3)]
  proc take[T](x: T, cb: proc(): lent seq[Box[T]]) = echo cb().len
  take(1, proc(): lent seq[Box[int]] = g)

block var_param:
  proc take[T](x: T, cb: proc(v: var seq[Box[T]])) =
    var s = @[Box[T](item: x)]
    cb(s)
    echo s.len
  take(1, proc(v: var seq[Box[int]]) = v.add Box[int](item: 2))

block generic_actual:
  proc g[U](v: seq[Box[U]]) = echo v.len
  proc take[T](x: T, cb: proc(v: seq[Box[T]]) {.nimcall.}) = cb(@[Box[T](item: x)])
  take(1, g)

block static_param:
  type Arr[N: static int] = object
    d: array[N, int]
  proc take[N: static int](x: Arr[N], cb: proc(v: seq[Arr[N]])) = cb(@[x])
  take(Arr[2](), proc(v: seq[Arr[2]]) = echo v.len)
