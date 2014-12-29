# implements and tests an efficient radix tree

## another method to store an efficient array of pointers: 
## We use a radix tree with node compression. 
## There are two node kinds:

const BitsPerUnit = 8*sizeof(int)

type
  TRadixNodeKind = enum rnLinear, rnFull, rnLeafBits, rnLeafLinear
  PRadixNode = ptr TRadixNode
  TRadixNode {.pure, inheritable.} = object
    kind: TRadixNodeKind
  TRadixNodeLinear = object of TRadixNode
    len: int8
    keys: array [0..31, int8]
    vals: array [0..31, PRadixNode]
  
  TRadixNodeFull = object of TRadixNode
    b: array [0..255, PRadixNode]
  TRadixNodeLeafBits = object of TRadixNode
    b: array [0..7, int]
  TRadixNodeLeafLinear = object of TRadixNode
    len: int8
    keys: array [0..31, int8]

var
  root: PRadixNode

proc searchInner(r: PRadixNode, a: int): PRadixNode = 
  case r.kind
  of rnLinear:
    var x = cast[ptr TRadixNodeLinear](r)
    for i in 0..ze(x.len)-1: 
      if ze(x.keys[i]) == a: return x.vals[i]
  of rnFull: 
    var x = cast[ptr TRadixNodeFull](r)
    return x.b[a]
  else: assert(false)

proc testBit(w, i: int): bool {.inline.} = 
  result = (w and (1 shl (i %% BitsPerUnit))) != 0

proc setBit(w: var int, i: int) {.inline.} = 
  w = w or (1 shl (i %% BitsPerUnit))

proc resetBit(w: var int, i: int) {.inline.} = 
  w = w and not (1 shl (i %% BitsPerUnit))

proc testOrSetBit(w: var int, i: int): bool {.inline.} = 
  var x = (1 shl (i %% BitsPerUnit))
  if (w and x) != 0: return true
  w = w or x

proc searchLeaf(r: PRadixNode, a: int): bool = 
  case r.kind
  of rnLeafBits:
    var x = cast[ptr TRadixNodeLeafBits](r)
    return testBit(x.b[a /% BitsPerUnit], a)
  of rnLeafLinear:
    var x = cast[ptr TRadixNodeLeafLinear](r)
    for i in 0..ze(x.len)-1: 
      if ze(x.keys[i]) == a: return true
  else: assert(false)

proc exclLeaf(r: PRadixNode, a: int) = 
  case r.kind
  of rnLeafBits:
    var x = cast[ptr TRadixNodeLeafBits](r)
    resetBit(x.b[a /% BitsPerUnit], a)
  of rnLeafLinear:
    var x = cast[ptr TRadixNodeLeafLinear](r)
    var L = ze(x.len)
    for i in 0..L-1: 
      if ze(x.keys[i]) == a: 
        x.keys[i] = x.keys[L-1]
        dec(x.len)
        return
  else: assert(false)

proc contains*(r: PRadixNode, a: ByteAddress): bool =
  if r == nil: return false
  var x = searchInner(r, a shr 24 and 0xff)
  if x == nil: return false
  x = searchInner(x, a shr 16 and 0xff)
  if x == nil: return false
  x = searchInner(x, a shr 8 and 0xff)
  if x == nil: return false
  return searchLeaf(x, a and 0xff)

proc excl*(r: PRadixNode, a: ByteAddress): bool =
  if r == nil: return false
  var x = searchInner(r, a shr 24 and 0xff)
  if x == nil: return false
  x = searchInner(x, a shr 16 and 0xff)
  if x == nil: return false
  x = searchInner(x, a shr 8 and 0xff)
  if x == nil: return false
  exclLeaf(x, a and 0xff)

proc addLeaf(r: var PRadixNode, a: int): bool = 
  if r == nil:
    # a linear node:
    var x = cast[ptr TRadixNodeLinear](alloc(sizeof(TRadixNodeLinear)))
    x.kind = rnLeafLinear
    x.len = 1'i8
    x.keys[0] = toU8(a)
    r = x
    return false # not already in set
  case r.kind 
  of rnLeafBits: 
    var x = cast[ptr TRadixNodeLeafBits](r)
    return testOrSetBit(x.b[a /% BitsPerUnit], a)
  of rnLeafLinear: 
    var x = cast[ptr TRadixNodeLeafLinear](r)
    var L = ze(x.len)
    for i in 0..L-1: 
      if ze(x.keys[i]) == a: return true
    if L <= high(x.keys):
      x.keys[L] = toU8(a)
      inc(x.len)
    else: 
      # transform into a full node:
      var y = cast[ptr TRadixNodeLeafBits](alloc0(sizeof(TRadixNodeLeafBits)))
      y.kind = rnLeafBits
      for i in 0..ze(x.len)-1: 
        var u = ze(x.keys[i])
        setBit(y.b[u /% BitsPerUnit], u)
      setBit(y.b[a /% BitsPerUnit], a)
      dealloc(r)
      r = y
  else: assert(false)

proc addInner(r: var PRadixNode, a: int, d: int): bool = 
  if d == 0: 
    return addLeaf(r, a and 0xff)
  var k = a shr d and 0xff
  if r == nil:
    # a linear node:
    var x = cast[ptr TRadixNodeLinear](alloc(sizeof(TRadixNodeLinear)))
    x.kind = rnLinear
    x.len = 1'i8
    x.keys[0] = toU8(k)
    r = x
    return addInner(x.vals[0], a, d-8)
  case r.kind
  of rnLinear:
    var x = cast[ptr TRadixNodeLinear](r)
    var L = ze(x.len)
    for i in 0..L-1: 
      if ze(x.keys[i]) == k: # already exists
        return addInner(x.vals[i], a, d-8)
    if L <= high(x.keys):
      x.keys[L] = toU8(k)
      inc(x.len)
      return addInner(x.vals[L], a, d-8)
    else: 
      # transform into a full node:
      var y = cast[ptr TRadixNodeFull](alloc0(sizeof(TRadixNodeFull)))
      y.kind = rnFull
      for i in 0..L-1: y.b[ze(x.keys[i])] = x.vals[i]
      dealloc(r)
      r = y
      return addInner(y.b[k], a, d-8)
  of rnFull: 
    var x = cast[ptr TRadixNodeFull](r)
    return addInner(x.b[k], a, d-8)
  else: assert(false)

proc incl*(r: var PRadixNode, a: ByteAddress) {.inline.} = 
  discard addInner(r, a, 24)
  
proc testOrIncl*(r: var PRadixNode, a: ByteAddress): bool {.inline.} = 
  return addInner(r, a, 24)
      
iterator innerElements(r: PRadixNode): tuple[prefix: int, n: PRadixNode] = 
  if r != nil:
    case r.kind 
    of rnFull: 
      var r = cast[ptr TRadixNodeFull](r)
      for i in 0..high(r.b):
        if r.b[i] != nil: 
          yield (i, r.b[i])
    of rnLinear: 
      var r = cast[ptr TRadixNodeLinear](r)
      for i in 0..ze(r.len)-1: 
        yield (ze(r.keys[i]), r.vals[i])
    else: assert(false)

iterator leafElements(r: PRadixNode): int = 
  if r != nil:
    case r.kind
    of rnLeafBits: 
      var r = cast[ptr TRadixNodeLeafBits](r)
      # iterate over any bit:
      for i in 0..high(r.b): 
        if r.b[i] != 0: # test all bits for zero
          for j in 0..BitsPerUnit-1: 
            if testBit(r.b[i], j): 
              yield i*BitsPerUnit+j
    of rnLeafLinear: 
      var r = cast[ptr TRadixNodeLeafLinear](r)
      for i in 0..ze(r.len)-1: 
        yield ze(r.keys[i])
    else: assert(false)
    
iterator elements*(r: PRadixNode): ByteAddress {.inline.} = 
  for p1, n1 in innerElements(r): 
    for p2, n2 in innerElements(n1):
      for p3, n3 in innerElements(n2):
        for p4 in leafElements(n3): 
          yield p1 shl 24 or p2 shl 16 or p3 shl 8 or p4
  
proc main() =
  const
    numbers = [128, 1, 2, 3, 4, 255, 17, -8, 45, 19_000]
  var
    r: PRadixNode = nil
  for x in items(numbers):
    echo testOrIncl(r, x)
  for x in elements(r): echo(x)

main()


when false:
  proc traverse(r: PRadixNode, prefix: int, d: int) = 
    if r == nil: return
    case r.kind 
    of rnLeafBits: 
      assert(d == 0)
      var x = cast[ptr TRadixNodeLeafBits](r)
      # iterate over any bit:
      for i in 0..high(x.b): 
        if x.b[i] != 0: # test all bits for zero
          for j in 0..BitsPerUnit-1: 
            if testBit(x.b[i], j): 
              visit(prefix or i*BitsPerUnit+j)
    of rnLeafLinear: 
      assert(d == 0)
      var x = cast[ptr TRadixNodeLeafLinear](r)
      for i in 0..ze(x.len)-1: 
        visit(prefix or ze(x.keys[i]))
    of rnFull: 
      var x = cast[ptr TRadixNodeFull](r)
      for i in 0..high(r.b):
        if r.b[i] != nil: 
          traverse(r.b[i], prefix or (i shl d), d-8)
    of rnLinear: 
      var x = cast[ptr TRadixNodeLinear](r)
      for i in 0..ze(x.len)-1: 
        traverse(x.vals[i], prefix or (ze(x.keys[i]) shl d), d-8)

  type
    TRadixIter {.final.} = object
      r: PRadixNode
      p: int
      x: int

  proc init(i: var TRadixIter, r: PRadixNode) =
    i.r = r
    i.x = 0
    i.p = 0
    
  proc nextr(i: var TRadixIter): PRadixNode = 
    if i.r == nil: return nil
    case i.r.kind 
    of rnFull: 
      var r = cast[ptr TRadixNodeFull](i.r)
      while i.x <= high(r.b):
        if r.b[i.x] != nil: 
          i.p = i.x
          return r.b[i.x]
        inc(i.x)
    of rnLinear: 
      var r = cast[ptr TRadixNodeLinear](i.r)
      if i.x < ze(r.len): 
        i.p = ze(r.keys[i.x])
        result = r.vals[i.x]
        inc(i.x)
    else: assert(false)

  proc nexti(i: var TRadixIter): int = 
    result = -1
    case i.r.kind 
    of rnLeafBits: 
      var r = cast[ptr TRadixNodeLeafBits](i.r)
      # iterate over any bit:    
      for i in 0..high(r.b): 
        if x.b[i] != 0: # test all bits for zero
          for j in 0..BitsPerUnit-1: 
            if testBit(x.b[i], j): 
              visit(prefix or i*BitsPerUnit+j)
    of rnLeafLinear: 
      var r = cast[ptr TRadixNodeLeafLinear](i.r)
      if i.x < ze(r.len): 
        result = ze(r.keys[i.x])
        inc(i.x)

  iterator elements(r: PRadixNode): ByteAddress {.inline.} = 
    var
      a, b, c, d: TRadixIter
    init(a, r)
    while true: 
      var x = nextr(a)
      if x != nil: 
        init(b, x)
        while true: 
          var y = nextr(b)
          if y != nil: 
            init(c, y)
            while true:
              var z = nextr(c)
              if z != nil: 
                init(d, z)
                while true:
                  var q = nexti(d)
                  if q != -1: 
                    yield a.p shl 24 or b.p shl 16 or c.p shl 8 or q
