discard """
output: '''
@[48, 57]
'''
"""
# bug #7238

type ByteArrayBE*[N: static[int]] = array[N, byte]
  ## A byte array that stores bytes in big-endian order

proc toByteArrayBE*[T: SomeInteger](num: T): ByteArrayBE[sizeof(T)]=
  ## Convert an integer (in native host endianness) to a big-endian byte array
  ## Notice the result type
  const N = T.sizeof
  for i in 0 ..< N:
    result[i] = byte((num shr ((N-1-i) * 8)) and high(int8))

let a = 12345.toByteArrayBE
echo a[^2 .. ^1] # to make it work on both 32-bit and 64-bit

#---------------------------------------------------------------------

type
  Payload = object
    something: int
    vals: UncheckedArray[int]

static:
  doAssert(compiles(offsetOf(Payload, vals)))


type
  GoodboySave* {.bycopy.} = object
    saveCount: uint8
    savePoint: uint16
    shards: uint32
    friendCount: uint8
    friendCards: set[0..255]
    locationsKnown: set[0..127]
    locationsUnlocked: set[0..127]
    pickupsObtained: set[0..127]
    pickupsUsed: set[0..127]
    pickupCount: uint8

block: # bug #20914
  block:
    proc csizeof[T](a: T): int {.importc:"sizeof", nodecl.}

    var s: GoodboySave
    doAssert sizeof(s) == 108
    doAssert csizeof(s) == static(sizeof(s))

  block:
    proc calignof[T](a: T): int {.importc:"alignof", header: "<stdalign.h>".}

    var s: set[0..256]
    doAssert alignof(s) == 1
    doAssert calignof(s) == static(alignof(s))
