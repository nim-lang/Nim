import sets

var
  a = initSet[int]()
  b = initSet[int]()
  c = initSet[string]()

for i in 0..5: a.incl(i)
for i in 1..6: b.incl(i)
for i in 0..5: c.incl($i)

doAssert map(a, proc(x: int): int = x + 1) == b
doAssert map(a, proc(x: int): string = $x) == c


proc sizeOfSet[T](s: T): int =
  ## Count by iterating over the items in the set
  for i in s:
    result += 1

var
  d: TSet[int]
  e: TOrderedSet[int]

doAssert(len(d) == 0 and sizeOfSet(d) == 0)
doAssert(len(e) == 0 and sizeOfSet(e) == 0)

d.incl(1)
e.incl(1)

d = initSet[int]()
e = initOrderedSet[int]()

doAssert(len(d) == 0 and sizeOfSet(d) == 0)
doAssert(len(e) == 0 and sizeOfSet(e) == 0)

d.incl(1)
e.incl(1)

doAssert(len(d) == 1 and sizeOfSet(d) == 1)
doAssert(len(e) == 1 and sizeOfSet(e) == 1)


var
  f: TSet[int]
  g: TOrderedSet[int]

doAssert(not f.containsOrIncl(1))
doAssert(not g.containsOrIncl(1))

doAssert f.contains(1)
doAssert g.contains(1)

doAssert len(f) == 1
doAssert len(g) == 1

doAssert sizeOfSet(f) == len(f)
doAssert sizeOfSet(g) == len(g)
