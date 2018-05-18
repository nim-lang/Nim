discard """
  file: "tarraycons_ptr_generic2.nim"
  line: 17
  errormsg: "type mismatch: got <ptr Hard[system.string]> but expected 'Book[system.string]'"
"""

type
  Book[T] = ref object of RootObj
    cover: T
  Hard[T] = ref object of Book[T]
  Soft[T] = ref object of Book[T]

var bn = Book[string](cover: "none")
var hs = Hard[string](cover: "skin")
var bp = Soft[string](cover: "paper")

let z = [bn, hs.addr, bp]
