discard """
  output: '''0 0
pre test a:test b:1 c:2 haha:3
assignment test a:test b:1 c:2 haha:3
'''
"""

# bug #1005

type
  TSomeObj = object of TObject
    a: int
  PSomeObj = ref object
    a: int
 
var a = TSomeObj()
var b = PSomeObj()
echo a.a, " ", b.a

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
