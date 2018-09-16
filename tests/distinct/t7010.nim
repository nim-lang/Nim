discard """
  exitcode: 0
  output: ''''''
"""

# Snippet not defined as ```nim

type MyInt* = distinct int

proc `+`*(x: MyInt, y: MyInt): MyInt {.borrow.}
proc `+=`*(x: var MyInt, y: MyInt) {.borrow.}
proc `=`*(x: var MyInt, y: MyInt) {.borrow.}

var next: MyInt

proc getNext*() : MyInt =
    result = next
    next += 1.MyInt
    next = next + 1.MyInt