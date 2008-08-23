# Memory handling for small objects

const
  minRequestSize = 2 * sizeof(pointer) # minimal block is 16 bytes
  pageSize = 1024 * sizeof(int)
  pageBits = pageSize div minRequestSize
  pageMask = pageSize-1

  bitarraySize = pageBits div (sizeof(int)*8)
  dataSize = pageSize - (bitarraySize+6) * sizeof(pointer)

type
  TMinRequest {.final.} = object
    next, prev: ptr TMinRequest  # stores next free bit

  TChunk {.pure.} = object # a chunk manages at least a page
    size: int              # lowest bit signals if it is a small chunk (0) or
                           # a big chunk (1)
    typ: PNimType
    next, prev: ptr TChunk
    nextOfSameType: ptr TChunk

  TSmallChunk = object of TChunk ## manages pageSize bytes for a type and a 
                                 ## fixed size
    free: int                    ## index of first free bit
    bits: array[0..bitarraySize-1, int]
    data: array[0..dataSize div minRequestSize - 1, TMinRequest]
  
  PSmallChunk = ptr TSmallChunk

assert(sizeof(TSmallChunk) == pageSize)

proc getNewChunk(size: int, typ: PNimType): PSmallChunk =
  result = cast[PSmallChunk](getPages(1))
  result.size = PageSize
  result.typ = typ
  result.next = chunkHead
  result.prev = nil
  chunkHead.prev = result
  chunkHead = result.next
  result.nextOfSameType = cast[PSmallChunk](typ.chunk)
  typ.chunk = result
  result.free = addr(result.data[0])
  result.data[0].next = addr(result.data[1])
  result.data[0].prev = nil
  result.data[high(result.data)].next = nil
  result.data[high(result.data)].prev = addr(result.data[high(result.data)-1])
  for i in 1..high(result.data)-1:
    result.data[i].next = addr(result.data[i+1])
    result.data[i].prev = addr(result.data[i-1])

proc newSmallObj(size: int, typ: PNimType): pointer =
  var chunk = cast[PSmallChunk](typ.chunk)
  if chunk == nil or chunk.free <= 0: 
    if chunk.free < 0: GC_collect()
    chunk = getNewChunk(size, typ)
    chunk.nextOfSameType = typ.chunk
    typ.chunk = chunk
  var idx = chunk.free
  setBit(chunk.bits[idx /% bitarraySize], idx %% bitarraySize)
  result = cast[pointer](cast[TAddress](addr(chunk.data)) + 
                        minRequestSize * idx)
  var res = cast[PMinRequest](result)
  chunk.free = res.next
  res.next
  
proc freeObj(obj: pointer) = 
  var chunk = cast[PChunk](cast[TAddress(obj) and not pageMask)
  if size and 1 == 0: # small chunk  
    var idx = (cast[TAddress](obj) shr pageShift) div minRequestSize
    resetBit(chunk.bits[idx /% bitarraySize], idx %% bitarraySize)
  
