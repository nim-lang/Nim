
# bug #2369

type HashedElem[T] = tuple[num: int, storedVal: ref T]

proc append[T](tab: var seq[HashedElem[T]], n: int, val: ref T) =
    #tab.add((num: n, storedVal: val))
    var he: HashedElem[T] = (num: n, storedVal: val)
    #tab.add(he)

var g: seq[HashedElem[int]] = @[]

proc foo() =
    var x: ref int
    new(x)
    x[] = 77
    g.append(44, x)
