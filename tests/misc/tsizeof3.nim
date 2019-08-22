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


#-----------------------------------------------------------------

# bug #11792
type
  m256d {.importc: "__m256d", header: "immintrin.h".} = object

  MyKind = enum
    k1, k2, k3

  MyTypeObj = object
    kind: MyKind
    x: int
    amount: UncheckedArray[m256d]


# The sizeof(MyTypeObj) is not equal to (sizeof(int) + sizeof(MyKind)) due to
# alignment requirement of m256d, make sure Nim understands that
doAssert(sizeof(MyTypeObj) > sizeof(int) + sizeof(MyKind))

#---------------------------------------------------------------------

type
  Payload = object
    something: int
    vals: UncheckedArray[int]

static:
  doAssert(compiles(offsetOf(Payload, vals)))
