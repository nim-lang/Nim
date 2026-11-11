# bug #10867
import hashes, tables

{.experimental: "codeReordering".}

type Foo = object

var table = initTable[Foo, int]()
table[Foo()] = 0
doAssert table.len == 1

proc hash(f: Foo): Hash = 0
