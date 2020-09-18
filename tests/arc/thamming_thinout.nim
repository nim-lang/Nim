discard """
  cmd: "nim c --gc:orc -d:nimThinout -r $file"
  output: '''The first 20 hammings are:  1 2 3 4 5 MEM IS 0'''
"""

# test Nim Hamming Number Lazy List algo with reference counts and not...
# compile with "-d:release -d:danger" and test with various
# memory managment GC's, allocators, threading, etc.

from times import epochTime
from math import log2

# implement our own basic BigInt so the bigints library isn't necessary...
type
  BigInt = object
    digits: seq[uint32]
let zeroBigInt = BigInt(digits: @[ 0'u32 ])
let oneBigInt = BigInt(digits: @[ 1'u32 ])

proc shladd(bi: var BigInt; n: int; a: BigInt) =
  var cry = 0'u64
  for i in 0 ..< min(bi.digits.len, a.digits.len):
    cry += (bi.digits[i].uint64 shl n) + a.digits[i].uint64
    bi.digits[i] = cry.uint32
    cry = cry shr 32
  if cry > 0'u64:
    bi.digits.add cry.uint32

proc `$`(x: BigInt): string =
  if x.digits.len == 0 or (x.digits.len == 1 and x.digits[0] == 0'u32):
    return "0"
  var n = x
  var msd = n.digits.high
  result = ""
  while msd >= 0:
    if n.digits[msd] == 0'u32: msd.dec; continue
    var brw = 0.uint64
    for i in countdown(msd, 0):
      let dvdnd = n.digits[i].uint64 + (brw shl 32)
      let q = dvdnd div 10'u64; brw = dvdnd - q*10'u64; n.digits[i] = q.uint32
    result &= $brw
  for i in 0 .. result.high shr 1:
    let tmp = result[^(i + 1)]
    result[^(i + 1)] = result[i]
    result[i] = tmp

proc convertTrival2BigInt(tpl: (uint32, uint32, uint32)): BigInt =
  result = oneBigInt
  let (x2, x3, x5) = tpl
  for _ in 1 .. x2: result.shladd 1, zeroBigInt
  for _ in 1 .. x3: result.shladd 1, result
  for _ in 1 .. x5: result.shladd 2, result

type LogRep = (float64, (uint32, uint32, uint32))
type LogRepf = proc(x: LogRep): LogRep
const one: LogRep = (0.0f64, (0u32, 0u32, 0u32))
proc `<`(me: LogRep, othr: LogRep): bool = me[0] < othr[0]

const lb2 = 1.0'f64
const lb3 = 3.0'f64.log2
const lb5 = 5.0'f64.log2

proc mul2(me: LogRep): LogRep =
  let (lr, tpl) = me; let (x2, x3, x5) = tpl
  (lr + lb2, (x2 + 1, x3, x5))

proc mul3(me: LogRep): LogRep =
  let (lr, tpl) = me; let (x2, x3, x5) = tpl
  (lr + lb3, (x2, x3 + 1, x5))

proc mul5(me: LogRep): LogRep =
  let (lr, tpl) = me; let (x2, x3, x5) = tpl
  (lr + lb5, (x2, x3, x5 + 1))

type
  LazyList = ref object
    hd: LogRep
    tlf: proc(): LazyList {.closure.}
    tl: LazyList

proc rest(ll: LazyList): LazyList = # not thread-safe; needs lock on thunk
  if ll.tlf != nil:
    ll.tl = ll.tlf()
    ll.tlf = nil
  ll.tl

iterator hamming(until: int): (uint32, uint32, uint32) =
  proc merge(x, y: LazyList): LazyList =
    let xh = x.hd
    let yh = y.hd
    if xh < yh: LazyList(hd: xh, tlf: proc(): auto = merge x.rest, y)
    else: LazyList(hd: yh, tlf: proc(): auto = merge x, y.rest)
  proc smult(mltf: LogRepf; s: LazyList): LazyList =
    proc smults(ss: LazyList): LazyList =
      LazyList(hd: ss.hd.mltf, tlf: proc(): auto = ss.rest.smults)
    s.smults
  proc unnsm(s: LazyList, mltf: LogRepf): LazyList =
    var r: LazyList = nil
    let frst = LazyList(hd: one, tlf: proc(): LazyList = r)
    r = if s == nil: smult mltf, frst else: s.merge smult(mltf, frst)
    r
  var hmpll: LazyList = ((nil.unnsm mul5).unnsm mul3).unnsm mul2
  #  var hmpll: LazyList = nil; for m in [mul5, mul3, mul2]: echo one.m # ; hmpll = unnsm(hmpll, m)
  yield one[1]
  var cnt = 1
  while hmpll != nil:
    yield hmpll.hd[1]
    hmpll = hmpll.rest # almost forever
    cnt.inc
    if cnt > until: break
  #when declared(thinout):
  thinout(hmpll)

proc main =
  stdout.write "The first 20 hammings are:  "
  for h in hamming(4):
    write stdout, h.convertTrival2BigInt, " "

  for h in hamming(200):
    discard h.convertTrival2BigInt

let mem = getOccupiedMem()
main()
echo "MEM IS ", getOccupiedMem() - mem

#[
result = (smults, :envP.:up)(rest(:envP.ss2))

proc anon =
  var
    :tmpD_284230
    :tmpD_284233
    :tmpD_284236
  try:
    `=sink_283407`(result_283502,
      `=sink_283927`(:tmpD_284236, (smults_283495,
        wasMoved_284234(:tmpD_284233)
        `=_284014`(:tmpD_284233, :envP_283898.:up_283899)
        :tmpD_284233))
      :tmpD_284236(
      `=sink_283407`(:tmpD_284230, rest_283366(:envP_283898.ss2_-283497))
      :tmpD_284230))
  finally:
    `=destroy_283914`(:tmpD_284236)
    `=destroy_283388`(:tmpD_284230)

proc smuls(ss: LazyList_283350; :envP_283891): LazyList_283350  =
  var :env_283913
  try:
    `=destroy_283951`(:env_283913)
    internalNew_43643(:env_283913)
    `=_283401`(:env_283913.ss2_-283497, ss_283497)
    :env_283913.:up_283899 = :envP_283891
    `=sink_283407`(result_283498, LazyList_283350(hd_283353: :envP_283891.mltf1_-283492(
        :env_283913.ss2_-283497.hd_283353), tlf_283356: (:anonymous_283499,
      let blitTmp_284227 = :env_283913
      wasMoved_284228(:env_283913)
      blitTmp_284227)))
  finally:
    `=destroy_283951`(:env_283913)

proc smul =
  var
    :env_283969
    :tmpD_284220
  try:
    `=destroy_284008`(:env_283969)
    internalNew_43643(:env_283969)
    `=_283976`(:env_283969.mltf1_-283492, mltf_283492)
    proc smults(ss: LazyList_283350; :envP_283891): LazyList_283350 =
      result_283498 = LazyList_283350(hd_283353: mltf_283492(ss_283497.hd_283353), tlf_283356: proc (
          :envP_283898): auto_43100 = result_283502 = smults_283495(rest_283366(ss_283497)))

    `=sink_283407`(result_283494,
      `=sink_283927`(:tmpD_284220, (smults_283495,
        let blitTmp_284218 = :env_283969
        wasMoved_284219(:env_283969)
        blitTmp_284218))
      :tmpD_284220(s_283493))
  finally:
    `=destroy_283914`(:tmpD_284220)
    `=destroy_284008`(:env_283969)
]#
