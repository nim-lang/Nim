discard """
  output: '''[10, 0, 0, 0, 0, 0, 0, 0]
255
1 1
0.5'''
"""

# bug #1181

type
  TFoo = object
    x: int32

proc mainowar =
  var foo: TFoo
  foo.x = 0xff
  var arr1 = cast[ptr array[4, uint8]](addr foo)[] # Fails.
  echo arr1[when cpuEndian == littleEndian: 0 else: 3]

  var i = 1i32
  let x = addr i
  var arr2 = cast[ptr array[4, uint8]](x)[] # Fails.
  echo arr2[when cpuEndian == littleEndian: 0 else: 3], " ", i

  # bug #1715
  var a: array[2, float32] = [0.5'f32, 0.7]
  let p = addr a
  var b = p[]
  echo b[0]


# bug 2963
var
  a = [8, 7, 3, 10, 0, 0, 0, 1]
  b = [10, 0, 0, 0, 0, 0, 0, 0]
  ap = addr a
ap[] = b
echo repr(a)

mainowar()
