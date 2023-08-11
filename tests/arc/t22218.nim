discard """
  cmd: "nim c --gc:arc $file"
  errormsg: "A channel cannot be copied; usage of '=copy' is an {.error.} defined at t22218.nim(9, 1)"
"""

type Obj[T] = object
  v: T

proc `=copy`[T](
    dest: var Obj[T],
    source: Obj[T]
  ) {.error: "A channel cannot be copied".}

from system/ansi_c import c_calloc

proc test() =
    var v: bool = true
    var chan = cast[ptr Obj[int]](c_calloc(1, csize_t sizeof(Obj[int])))
    var copy = chan[]

    echo chan.v
    echo v

test()
