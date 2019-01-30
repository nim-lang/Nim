discard """
output: ""
"""

import strutils

const x  = [1'i32, -1, -10, 10, -10, 10, -20, 30, -40, 50, 7 shl 28, -(7 shl 28), 7 shl 28, -(7 shl 28)]
const y  = [-1'i32, 1, -10, -10, 10, 10, -20, -30, 40, 50, 1 shl 30, 1 shl 30, -(1 shl 30), -(1 shl 30)]


const res_xor = block:
  var tmp: seq[int64]
  for i in 0..<x.len:
    tmp.add(int64(x[i] xor y[i]))
  tmp

const res_and = block:
  var tmp: seq[int64]
  for i in 0..<x.len:
    tmp.add(int64(x[i] and y[i]))
  tmp
 
const res_or = block:
  var tmp: seq[int64]
  for i in 0..<x.len:
    tmp.add(int64(x[i] or y[i]))
  tmp


let xx = x
let yy = y

for i in 0..<xx.len:
  let z_xor = int64(xx[i] xor yy[i])
  let z_and = int64(xx[i] and yy[i])
  let z_or = int64(xx[i] or yy[i])
  doAssert(z_xor == res_xor[i], $i & ": " & $res_xor[i] & "  " & $z_xor)
  doAssert(z_and == res_and[i], $i & ": " & $res_and[i] & "  " & $z_and)
  doAssert(z_or == res_or[i], $i & ": " & $res_or[i] & "  " & $z_or)

#---------------------------------------------------------------------

const x2 = [1'i32,  -1, 10, -35, 35, -10, 20, -30, 31]
const y2 = [1'i32,  1, 10, 11, 11, 10, 20, 7, 7]

const res_shl = block:
  var tmp: seq[int64]
  for i in 0..<x2.len:
    tmp.add(int64(x2[i] shl y2[i]))
  tmp

let xx2 = x2
let yy2 = y2

for i in 0..<xx2.len:
  let z_shl = int64(xx2[i] shl yy2[i])
  doAssert(z_shl == res_shl[i], $i & ": " & $res_shl[i] & "  " & $z_shl)