discard """
output: '''
13{(.{}}{*4&*$**()&*@1235
5
4
3
2
1
0
it should stop now
18446744073709551615
4294967295
Whopie
10
10
1
1
'''
"""


import deques

block t1217:
  type
    Test = enum
      `1`, `3`, `{`, `(.`, `{}}{`, `*4&*$**()&*@`

  let `.}` = 1
  let `(}` = 2
  let `[` = 3
  let `]` = 5

  echo `1`, `3`, `{`, `(.`, `{}}{`, `*4&*$**()&*@`, `.}`, `(}`, `[`, `]`


block t1638:
  let v1 = 7
  let v2 = 7'u64

  let t1 = v1 mod 2 # works
  let t2 = 7'u64 mod 2'u64 # works
  let t3 = v2 mod 2'u64 # Error: invalid type: 'range 0..1(uint64)
  let t4 = (v2 mod 2'u64).uint64 # works


block t2550:
  var x: uint # doesn't work
  doAssert x mod 2 == 0

  var y: uint64 # doesn't work
  doAssert y mod 2 == 0

  var z: uint32 # works
  doAssert z mod 2 == 0

  var a: int # works
  doAssert a mod 2 == 0


block t1420:
  var x = 40'u32
  var y = 30'u32
  doAssert x > y # works

  doAssert((40'i32) > (30'i32))
  doAssert((40'u32) > (30'u32)) # Error: ordinal type expected


block t4220:
  const count: uint = 5
  var stop_me = false

  for i in countdown(count, 0):
    echo i
    if stop_me: break
    if i == 0:
      echo "it should stop now"
      stop_me = true


block t3985:
  const
    HIGHEST_64BIT_UINT = 0xFFFFFFFFFFFFFFFF'u
    HIGHEST_32BIT_UINT = 0xFFFFFFFF'u
  echo($HIGHEST_64BIT_UINT)
  echo($HIGHEST_32BIT_UINT)


block t569:
  type
    TWidget = object
      names: Deque[string]
  var w = TWidget(names: initDeque[string]())
  addLast(w.names, "Whopie")
  for n in w.names: echo(n)


block t681:
  type TSomeRange = object
    hour: range[0..23]
  var value: string
  var val12 = TSomeRange(hour: 12)

  value = $(if val12.hour > 12: val12.hour - 12 else: val12.hour)
  doAssert value == "12"


block t1334:
  var ys = @[4.1, 5.6, 7.2, 1.7, 9.3, 4.4, 3.2]
  #var x = int(ys.high / 2) #echo ys[x] # Works
  doAssert ys[int(ys.high / 2)] == 1.7 # Doesn't work


block t1344:
  var expected: int
  var x: range[1..10] = 10

  try:
    x += 1
    echo x
  except OverflowError, RangeError:
    expected += 1
    echo x

  try:
    inc x
    echo x
  except OverflowError, RangeError:
    expected += 1
    echo x

  x = 1
  try:
    x -= 1
    echo x
  except OverflowError, RangeError:
    expected += 1
    echo x

  try:
    dec x
    echo x
  except OverflowError, RangeError:
    expected += 1
    echo x

  doAssert expected == 4
