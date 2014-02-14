discard """
  file: "tcgbug.nim"
  output: "success"
"""

type
  TObj = object
    x, y: int
  PObj = ref TObj

proc p(a: PObj) =
  a.x = 0

proc q(a: var PObj) =
  a.p()

var 
  a: PObj
new(a)
q(a)

# bug #914
var x = newWideCString("Hello")

echo "success"


# bug #833

type
  PFuture*[T] = ref object
    value*: T
    finished*: bool
    cb: proc (future: PFuture[T]) {.closure.}

var k = PFuture[void]()
