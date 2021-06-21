discard """
disabled: "windows"
disabled: "openbsd"
joinable: false
disabled: 32bit
"""
# no point to test this on system with smaller address space
# was: appveyor is "out of memory"

const
  nmax = 2*1024*1024*1024

proc test(n: int) =
  var a = alloc0(9999)
  var t = cast[ptr UncheckedArray[int8]](alloc(n))
  var b = alloc0(9999)
  t[0] = 1
  t[1] = 2
  t[n-2] = 3
  t[n-1] = 4
  dealloc(a)
  dealloc(t)
  dealloc(b)

# allocator adds 48 bytes to BigChunk
# BigChunk allocator edges at 2^n * (1 - s) for s = [1..32]/64
proc test2(n: int) =
  let d = n div 256  # cover edges and more
  for i in countdown(128,1):
    for j in [-4096, -64, -49, -48, -47, -32, 0, 4096]:
      let b = n + j - i*d
      if b>0 and b<=nmax:
        test(b)
        #echo b, ": ", getTotalMem(), " ", getOccupiedMem(), " ", getFreeMem()

proc test3 =
  var n = 1
  while n <= nmax:
    test2(n)
    n *= 2
  n = nmax
  while n >= 1:
    test2(n)
    n = n div 2

test3()
