discard """
  output: '''
copy!
copy!
3
2
'''
"""

type Foo = distinct int

var counter = 0

proc `=destroy`(pkt: var Foo) =
  if cast[int](pkt) != 0:
    echo cast[int](pkt)

proc `=copy`(a: var Foo, b: Foo) =
  if cast[int](a) == cast[int](b):
    return

  `=destroy`(a)
  if cast[int](b) == 0:
    zeroMem(addr a, sizeof(Foo))
  else:
    counter += 1
    copyMem(addr a, addr counter, sizeof(Foo))
    echo "copy!"

proc makeFoo(): Foo =
  counter += 1
  cast[Foo](counter)


type Bar = object
  val: Foo


proc consume(x: sink Bar) =
  discard

let x = Bar(val: makeFoo())
consume(x)
discard x
