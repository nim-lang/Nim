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
    result[i] = byte(num shr ((N-1-i) * 8))

let a = 12345.toByteArrayBE
echo a[^2 .. ^1] # to make it work on both 32-bit and 64-bit
