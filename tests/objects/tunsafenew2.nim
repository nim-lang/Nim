discard """
valgrind: "leaks"
matrix: "-d:useMalloc"
targets: "c cpp"
"""

type
  Obj = object
    case b: bool
    else: discard
    a: UncheckedArray[byte]

var o: ref Obj
unsafeNew(o, sizeof(Obj) + 512)
zeroMem(addr o.a, 512)
