import tables

doAssert indexBy(newSeq[int](), proc(x: int):int = x) == initTable[int, int](), "empty int table"

var tbl1 = initTable[int, int]()
tbl1.add(1,1)
tbl1.add(2,2)
doAssert indexBy(@[1,2], proc(x: int):int = x) == tbl1, "int table"

type
  TElem = object
    foo: int
    bar: string
    
let
  elem1 = TElem(foo: 1, bar: "bar")
  elem2 = TElem(foo: 2, bar: "baz")
  
var tbl2 = initTable[string, TElem]()
tbl2.add("bar", elem1)
tbl2.add("baz", elem2)
doAssert indexBy(@[elem1,elem2], proc(x: TElem): string = x.bar) == tbl2, "element table"
