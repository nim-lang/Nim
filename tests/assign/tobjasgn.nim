discard """
  output: '''8 5 0 0
pre test a:test b:1 c:2 haha:3
assignment test a:test b:1 c:2 haha:3
'''
"""

# bug #1005

type
  TSomeObj = object of TObject
    a, b: int
  PSomeObj = ref object
    a, b: int
 
var a = TSomeObj(a: 8)
var b = PSomeObj(a: 5)
echo a.a, " ", b.a, " ", a.b, " ", b.b

# bug #575

type
  Something = object of Tobject
    a: string
    b, c: int32

type
  Other = object of Something
    haha: int

proc `$`(x: Other): string =
  result = "a:" & x.a & " b:" & $x.b & " c:" & $x.c & " haha:" & $x.haha

var
  t: Other

t.a = "test"
t.b = 1
t.c = 2
t.haha = 3

echo "pre test ", $t
var x = t
echo "assignment test ", x
