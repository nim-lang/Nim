## A BiTable is a table that can be seen as an optimized pair
## of (Table[Id, Val], Table[Val, Id]).

import hashes

type
  Id* = distinct uint32

  BiTable*[T] = object
    vals: seq[T] # indexed by Id
    keys: seq[Id]  # indexed by hash(val)

proc nextTry(h, maxHash: Hash): Hash {.inline.} =
  result = (h + 1) and maxHash

template maxHash(t): untyped = high(t.keys)
template isFilled(x: Id): bool = x.uint32 > 0'u32

const
  NullId* = Id(0)

proc `$`*(x: Id): string {.borrow.}
proc hash*(x: Id): Hash {.borrow.}
proc `==`*(x, y: Id): bool {.borrow.}

proc mustRehash(length, counter: int): bool {.inline.} =
  assert(length > counter)
  result = (length * 2 < counter * 3) or (length - counter < 4)

const
  idStart = 256 # Ids do not start with 0 but with this value. The IR needs it.

proc isBuiltin*(x: Id): bool {.inline.} = uint32(x) < idStart

template idToIdx(x: Id): int = x.int - idStart

proc enlarge[T](t: var BiTable[T]) =
  var n: seq[Id]
  newSeq(n, len(t.keys) * 2)
  swap(t.keys, n)
  for i in 0..high(n):
    let eh = n[i]
    if isFilled(eh):
      var j = hash(t.vals[idToIdx eh]) and maxHash(t)
      while isFilled(t.keys[j]):
        j = nextTry(j, maxHash(t))
      t.keys[j] = move n[i]

proc getOrIncl*[T](t: var BiTable[T]; v: T): Id =
  let origH = hash(v)
  var h = origH and maxHash(t)
  if t.keys.len != 0:
    while true:
      let id = t.keys[h]
      if not isFilled(id): break
      if t.vals[idToIdx t.keys[h]] == v: return id
      h = nextTry(h, maxHash(t))
    # not found, we need to insert it:
    if mustRehash(t.keys.len, t.vals.len):
      enlarge(t)
      # recompute where to insert:
      h = origH and maxHash(t)
      while true:
        let id = t.keys[h]
        if not isFilled(id): break
        h = nextTry(h, maxHash(t))
  else:
    setLen(t.keys, 16)
    h = origH and maxHash(t)

  result = Id(t.vals.len + idStart)
  t.keys[h] = result
  t.vals.add v


proc `[]`*[T](t: var BiTable[T]; id: Id): var T {.inline.} =
  let idx = idToIdx id
  assert idx < t.vals.len
  result = t.vals[idx]

proc `[]`*[T](t: BiTable[T]; id: Id): lent T {.inline.} =
  let idx = idToIdx id
  assert idx < t.vals.len
  result = t.vals[idx]

when isMainModule:

  var t: BiTable[string]

  echo getOrIncl(t, "hello")

  echo getOrIncl(t, "hello")
  echo getOrIncl(t, "hello3")
  echo getOrIncl(t, "hello4")
  echo getOrIncl(t, "helloasfasdfdsa")
  echo getOrIncl(t, "hello")

  for i in 0 ..< 100_000:
    discard t.getOrIncl($i & "___" & $i)

  for i in 0 ..< 100_000:
    assert t.getOrIncl($i & "___" & $i).idToIdx == i + 4
  echo t.vals.len

  echo t.vals[0]
  echo t.vals[1004]
