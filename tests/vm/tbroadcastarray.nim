discard """
  targets: "c js"
  matrix: "--mm:orc; --mm:refc"
  output: "ok"
"""

# big zeroed arrays computed by the VM come back in the compact broadcast form
type
  Key = array[48, byte]
  Comm = object
    keys: array[512, Key]
    agg: Key
  Mixed = object
    names: array[40, string]
    nums: array[100, int]

proc mk(): Comm = discard
proc mkMixed(): Mixed =
  result.nums[99] = 7
const c = mk()
const z = default(array[1000, int])
const m = mkMixed()
static:
  doAssert c.keys[511][47] == 0
  doAssert z[999] == 0 and z.len == 1000
  doAssert m.nums[99] == 7 and m.nums[0] == 0 and m.names[39] == ""
var v = c
v.keys[3][5] = 9
doAssert v.keys[3][5] == 9 and v.keys[2][5] == 0 and c.keys[3][5] == 0
doAssert c == default(Comm)
var s = @z
s[5] = 1
doAssert s.len == 1000 and s[5] == 1 and z[5] == 0
doAssert m.nums[99] == 7 and m.names[0].len == 0
var mm = m
mm.names[3] = "x"
doAssert mm.names[3] == "x"
const zs = default(array[64, seq[int]])
var q = zs
q[63].add 4
doAssert q[63] == @[4] and zs[63].len == 0
echo "ok"
