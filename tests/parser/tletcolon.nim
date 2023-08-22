discard """
  output: '''boo
3
44 3
more body code
yes
yes
block expression works'''
"""

template x(body): untyped =
  body
  44

template y(val, body): untyped =
  body
  val

proc mana =
  let foo = x:
    echo "boo"
  var foo2: int
  foo2 = y 3:
    echo "3"
  echo foo, " ", foo2

mana()
let other = x:
  echo "more body code"
  if true:
    echo "yes"
  else:
    echo "no"
let outer = y(5):
  echo "yes"


# bug #6609
type
  TextureInternalFormat = enum RED, RGB, RGBA

const channels = 4

let format =
    if channels == 1:
        TextureInternalFormat.RED
    elif channels == 3:
        TextureInternalFormat.RGB
    elif channels == 4:
        TextureInternalFormat.RGBA
    else:
        echo "Texture Format Unknown, assuming RGB"  #This echo causes an error
        TextureInternalFormat.RGB

# Block as expressions #3827
block:
  let x = block:
    var y = 2
    echo "block expression works"
    y*y
  doAssert x == 4


# bug 10861
macro foo(a: untyped): untyped = 
  a             

let c1 = foo:
  1 + 1

const c2 = foo:
  1 + 1

const c3 = 
  foo: 1 + 1
