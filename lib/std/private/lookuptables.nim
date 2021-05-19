#[
Experimental API, subject to change.

## benchmark
see tests/benchmarks/tlookuptables.nim

## design goals
* low level module with few/no dependencies, which can be used in other modules;
  this precludes importing math, tables, hashes.
* high performance (faster than `std/tables`)
* avoid the complexity of tables.nim + friends (but could serve as building block for it)
]#

func nextPowerOfTwo*(x: int): int {.inline.} =
  ## documented (for now) in `nextPowerOfTwo.math`
  result = x - 1
  when defined(cpu64):
    result = result or (result shr 32)
  when sizeof(int) > 2:
    result = result or (result shr 16)
  when sizeof(int) > 1:
    result = result or (result shr 8)
  result = result or (result shr 4)
  result = result or (result shr 2)
  result = result or (result shr 1)
  result += 1 + ord(x <= 0)

type
  SimpleHash* = uint
    # math works out better with `uint` than with
    # int as done in `hash.Hash`
  LookupTable*[T] = object
    cells*: seq[SimpleHash]
    keys*: seq[T]

const pseudoRandomMixing = 5
  # this could be chosen to minimize the exppected number
  # of calls to `nextCell`, if the key distribution is known.

template nextCell(h, m): untyped =
  ## pseudo-random probing
  (h * pseudoRandomMixing) and m

template simpleHash[T](a: T): SimpleHash =
  cast[SimpleHash](a)

proc initLookupTable*[T](a: openArray[T]): LookupTable[T] =
  ## Returns a lookup table that supports efficient lookup.
  let size = max(2, nextPowerOfTwo(a.len * 3 div 2))
  result.cells.setLen size
  result.keys.setLen size
  let m = SimpleHash(size - 1)
  var i = 1'u
  for ai in a:
    var index = ai.simpleHash and m
    while true:
      let h = result.cells[index]
      if h == 0: break
      index = nextCell(h, m)
    result.cells[index] = i
    result.keys[index] = ai
    inc(i)

proc lookup*[T](tab: LookupTable[T], key: T): int =
  ## return `-1` if `key` not found, else an index `i`
  ## at which we can find `key`.
  runnableExamples:
    let a = @[100.0, 0.0, 13.3, -3.12]
    let b = a.initLookupTable
    assert b.lookup(13.3) == 2 # found at index 2
    assert b.lookup(0.3) == -1 # not found
  let size = tab.cells.len
  let m = SimpleHash(size - 1)
  var index = key.simpleHash and m
  while true:
    let h = tab.cells[index]
    if h == 0: return -1
    elif tab.keys[index] == key:
      return cast[int](h - 1)
    else:
      index = nextCell(h, m)
