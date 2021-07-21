discard """
  errormsg: "type mismatch: obtained <ptr Hard[system.string]> expected 'Book[system.string]'"
  file: "tarraycons_ptr_generic2.nim"
  line: 17
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
