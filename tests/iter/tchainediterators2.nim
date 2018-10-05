discard """
  output: '''start
false
0
1
2
end
@[2, 4, 6, 8, 10]
@[4, 8, 12, 16, 20]'''
"""

# bug #3837

proc iter1(): (iterator: int) =
  let coll = [0,1,2]
  result = iterator: int {.closure.} =
    for i in coll:
      yield i

proc iter2(it: (iterator: int)): (iterator: int)  =
  result = iterator: int {.closure.} =
    echo finished(it)
    for i in it():
      yield i

echo "start"
let myiter1 = iter1()
let myiter2 = iter2(myiter1)
for i in myiter2():
  echo i
echo "end"
# start
# false
# end


from sequtils import toSeq

type Iterable*[T] = (iterator: T) | Slice[T]
  ## Everything that can be iterated over, iterators and slices so far.

proc toIter*[T](s: Slice[T]): iterator: T =
  ## Iterate over a slice.
  iterator it: T {.closure.} =
    for x in s.a..s.b:
      yield x
  return it

proc toIter*[T](i: iterator: T): iterator: T =
  ## Nop
  i

iterator map*[T,S](i: Iterable[T], f: proc(x: T): S): S =
  let i = toIter(i)
  for x in i():
    yield f(x)

proc filter*[T](i: Iterable[T], f: proc(x: T): bool): iterator: T =
  ## Iterates through an iterator and yields every item that fulfills the
  ## predicate `f`.
  ##
  ## .. code-block:: nim
  ##   for x in filter(1..11, proc(x): bool = x mod 2 == 0):
  ##     echo x
  let i = toIter(i)
  iterator it: T {.closure.} =
    for x in i():
      if f(x):
        yield x
  result = it

iterator filter*[T](i: Iterable[T], f: proc(x: T): bool): T =
  let i = toIter(i)
  for x in i():
    if f(x):
      yield x

var it = toSeq(filter(2..10, proc(x: int): bool = x mod 2 == 0))
echo it # @[2, 4, 6, 8, 10]
it = toSeq(map(filter(2..10, proc(x: int): bool = x mod 2 == 0), proc(x: int): int = x * 2))
echo it # Expected output: @[4, 8, 12, 16, 20], Actual output: @[]
