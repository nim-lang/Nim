discard """
  output: '''[1, 2, 3, 4]
3
['1', '2', '3', '4', '5', '6', '7', '8', '9', 'A', 'B', 'C']
OK
'''
"""

var
  arr = [1,2,3]
  arrp = addr(arr)
  sss = @[4,5,6,7]
  sssp = addr(sss)
  ra = new(array[3, int])
  raa = [11,12,13]

#bug #3586
proc mutate[T](arr:openArray[T], brr: openArray[T]) =
  for i in 0..arr.len-1:
    doAssert(arr[i] == brr[i])

mutate(arr, arr)

#bug #2240
proc f(a: openArray[int], b: openArray[int]) =
  for i in 0..a.len-1:
   doAssert(a[i] == b[i])

var a = [7,8,9]
var p = addr a
f(p[], a)
f(sssp[], sss)

ra[0] = 11
ra[1] = 12
ra[2] = 13
f(ra[], raa)

#bug #2240b
proc fillBuffer(buf: var openArray[char]) =
  for i in 0..buf.len-1:
    buf[i] = chr(i)

proc fillSeqBuffer(b: ref seq[char]) =
  fillBuffer(b[])

proc getFilledBuffer(sz: int): ref seq[char] =
  let s : ref seq[char] = new(seq[char])
  s[] = newSeq[char](sz)
  fillBuffer(s[])
  return s

let aa = getFilledBuffer(3)
for i in 0..aa[].len-1:
  doAssert(aa[i] == chr(i))

var
  x = [1, 2, 3, 4]
  y1 = block: (
    a: (block:
      echo x
      cast[ptr array[2, int]](addr(x[0]))[]),
    b: 3)
  y2 = block:
    echo y1.a[0] + y1.a[1]
    cast[ptr array[4, int]](addr(x))[]
doAssert y1 == ([1, 2], 3)
doAssert y2 == [1, 2, 3, 4]

template newOpenArray(x: var string, size: int): openArray[char] =
  var z = 1
  toOpenArray(x, z, size)

template doSomethingAndCreate(x: var string): openArray[char] =
  let size = 12
  newOpenArray(x, size)

proc sinkk(x: openArray[char]) =
  echo x

var xArrayDeref = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ"
sinkk doSomethingAndCreate(xArrayDeref)

echo "OK"
