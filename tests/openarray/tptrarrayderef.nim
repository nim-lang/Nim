discard """
  file: "tptrarrayderef.nim"
  output: "OK"
"""

var
  arr = [1,2,3]
  arrp = addr(arr)
  sss = @[4,5,6,7]
  sssp = addr(sss)
  ra = new(array[3, int])
  raa = [11,12,13]

#bug #3586
proc mutate[T](arr:openarray[T], brr: openArray[T]) =
  for i in 0..arr.len-1:
    doAssert(arr[i] == brr[i])
    
mutate(arr, arr)

#bug #2240
proc f(a: openarray[int], b: openArray[int]) =
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
proc fillBuffer(buf: var openarray[char]) =
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
  
echo "OK"