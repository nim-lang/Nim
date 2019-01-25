discard """
  output: '''
2
3
9
257
1
2
3
'''
disabled: "true"
"""

# Disabled since some versions of GCC ignore the 'packed' attribute

# Test

type
  Foo {.packed.} = object
    a: int8
    b: int8

  Bar {.packed.} = object
    a: int8
    b: int16

  Daz {.packed.} = object
    a: int32
    b: int8
    c: int32


var f = Foo(a: 1, b: 1)
var b: Bar
var d: Daz

echo sizeof(f)
echo sizeof(b)
echo sizeof(d)
echo (cast[ptr int16](f.addr)[])

type
  Union {.union.} = object
    a: int8
    b: int8

var u: Union
u.a = 1
echo u.b
u.a = 2
echo u.b
u.b = 3
echo u.a
