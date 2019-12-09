discard """
  output: '''
1
2
3
4
2
88
timplicit done
'''
"""


for x in [1, 2, 3, 4]:
  echo x


type
  TValue* {.pure, final.} = object of RootObj
    a: int
  PValue = ref TValue
  PPValue = ptr PValue


var x: PValue
new x
var sp: PPValue = addr x

sp.a = 2
if sp.a == 2: echo 2  # with sp[].a the error is gone

# Test the new auto-deref a little

{.experimental.}

proc p(x: var int; y: int) = x += y

block:
  var x: ref int
  new(x)

  x.p(44)

  var indirect = p
  x.indirect(44)

  echo x[]

  echo "timplicit done"
