discard """
output: '''
[4, 5, 6]
[16, 25, 36]
[16, 25, 36]
apple
banana
Fruit
2
4
3
none
skin
paper
@[2, 3, 4]321
9.0 4.0
3
@[(1, 2), (3, 5)]
2
@["a", "new one", "c"]
@[1, 2, 3]
3
dflfdjkl__abcdefgasfsgdfgsgdfggsdfasdfsafewfkljdsfajs
dflfdjkl__abcdefgasfsgdfgsgdfggsdfasdfsafewfkljdsfajsdf
kgdchlfniambejop
fjpmholcibdgeakn
2.0
a:1
a:2
a:3
ret:
ret:1
ret:12
123
'''
joinable: false
"""

block tarray:
  type
    TMyArray = array[0..2, int]
    TMyRecord = tuple[x, y: int]
    TObj = object
      arr: TMyarray


  proc sum(a: openArray[int]): int =
    result = 0
    var i = 0
    while i < len(a):
      inc(result, a[i])
      inc(i)

  proc getPos(r: TMyRecord): int =
    result = r.x + r.y

  doAssert sum([1, 2, 3, 4]) == 10
  doAssert sum([]) == 0
  doAssert getPos( (x: 5, y: 7) ) == 12

  # bug #1669
  let filesToCreate = ["tempdir/fl1.a", "tempdir/fl2.b",
              "tempdir/tempdir2/fl3.e", "tempdir/tempdir2/tempdir3/fl4.f"]

  var found: array[0..filesToCreate.high, bool]

  doAssert found.len == 4

  # make sure empty arrays are assignable (bug #6853)
  const arr1: array[0, int] = []
  const arr2 = []
  let arr3: array[0, string] = []

  doAssert(arr1.len == 0)
  doAssert(arr2.len == 0)
  doAssert(arr3.len == 0)

  # Negative array length is not allowed (#6852)
  doAssert(not compiles(block:
    var arr: array[-1, int]))


  proc mul(a, b: TMyarray): TMyArray =
    result = a
    for i in 0..len(a)-1:
      result[i] = a[i] * b[i]

  var
    x, y: TMyArray
    o: TObj

  proc varArr1(x: var TMyArray): var TMyArray = x
  proc varArr2(x: var TObj): var TMyArray = x.arr

  x = [4, 5, 6]
  echo repr(varArr1(x))

  y = x
  echo repr(mul(x, y))

  o.arr = mul(x, y)
  echo repr(varArr2(o))


  const
    myData = [[1,2,3], [4, 5, 6]]

  doAssert myData[0][2] == 3



block tarraycons:
  type
    TEnum = enum
      eA, eB, eC, eD, eE, eF

  const
    myMapping: array[TEnum, array[0..1, int]] = [
      eA: [1, 2],
      eB: [3, 4],
      [5, 6],
      eD: [0: 8, 1: 9],
      eE: [0: 8, 9],
      eF: [2, 1: 9]
    ]

  doAssert myMapping[eC][1] == 6



block tarraycons_ptr_generic:
  type
    Fruit = object of RootObj
      name: string
    Apple = object of Fruit
    Banana = object of Fruit

  var
    ir = Fruit(name: "Fruit")
    ia = Apple(name: "apple")
    ib = Banana(name: "banana")

  let x = [ia.addr, ib.addr, ir.addr]
  for c in x: echo c.name

  type
    Vehicle[T] = object of RootObj
      tire: T
    Car[T] = object of Vehicle[T]
    Bike[T] = object of Vehicle[T]

  var v = Vehicle[int](tire: 3)
  var c = Car[int](tire: 4)
  var b = Bike[int](tire: 2)

  let y = [b.addr, c.addr, v.addr]
  for c in y: echo c.tire

  type
    Book[T] = ref object of RootObj
      cover: T
    Hard[T] = ref object of Book[T]
    Soft[T] = ref object of Book[T]

  var bn = Book[string](cover: "none")
  var hs = Hard[string](cover: "skin")
  var bp = Soft[string](cover: "paper")

  let z = [bn, hs, bp]
  for c in z: echo c.cover



block tarraylen:
  var a: array[0, int]
  doAssert a.len == 0
  doAssert array[0..0, int].len == 1
  doAssert array[0..0, int]([1]).len == 1
  doAssert array[1..1, int].len == 1
  doAssert array[1..1, int]([1]).len == 1
  doAssert array[2, int].len == 2
  doAssert array[2, int]([1, 2]).len == 2
  doAssert array[1..3, int].len == 3
  doAssert array[1..3, int]([1, 2, 3]).len == 3
  doAssert array[0..2, int].len == 3
  doAssert array[0..2, int]([1, 2, 3]).len == 3
  doAssert array[-2 .. -2, int].len == 1
  doAssert([1, 2, 3].len == 3)
  doAssert([42].len == 1)




type ustring = distinct string
converter toUString(s: string): ustring = ustring(s)

block tarrayindx:
  proc putEnv(key, val: string) =
    # XXX: we have to leak memory here, as we cannot
    # free it before the program ends (says Borland's
    # documentation)
    var
      env: ptr array[0..500000, char]
    env = cast[ptr array[0..500000, char]](alloc(len(key) + len(val) + 2))
    for i in 0..len(key)-1: env[i] = key[i]
    env[len(key)] = '='
    for i in 0..len(val)-1:
      env[len(key)+1+i] = val[i]

  # bug #7153
  const
    UnsignedConst = 1024'u
  type
    SomeObject = object
      s1: array[UnsignedConst, uint32]

  var
    obj: SomeObject

  doAssert obj.s1[0] == 0
  doAssert obj.s1[0u] == 0

  # bug #8049
  proc `[]`(s: ustring, i: int): ustring = s
  doAssert "abcdefgh"[1..2] == "bc"
  doAssert "abcdefgh"[1..^2] == "bcdefg"



block troof:
  proc foo[T](x, y: T): T = x

  var a = @[1, 2, 3, 4]
  var b: array[3, array[2, float]] = [[1.0,2], [3.0,4], [8.0,9]]
  echo a[1.. ^1], a[^2], a[^3], a[^4]
  echo b[^1][^1], " ", (b[^2]).foo(b[^1])[^1]

  b[^1] = [8.8, 8.9]

  var c: seq[(int, int)] = @[(1,2), (3,4)]

  proc takeA(x: ptr int) = echo x[]

  takeA(addr c[^1][0])
  c[^1][1] = 5
  echo c

  proc useOpenarray(x: openArray[int]) =
    echo x[^2]

  proc mutOpenarray(x: var openArray[string]) =
    x[^2] = "new one"

  useOpenarray([1, 2, 3])

  var z = @["a", "b", "c"]
  mutOpenarray(z)
  echo z

  # bug #6675
  var y: array[1..5, int] = [1,2,3,4,5]
  y[3..5] = [1, 2, 3]
  echo y[3..5]


  var d: array['a'..'c', string] = ["a", "b", "c"]
  doAssert d[^1] == "c"




import strutils, sequtils, typetraits, os

type
  MetadataArray* = object
    data*: array[8, int]
    len*: int

# Commenting the converter removes the error "lib/system.nim(3536, 3) Error: for a 'var' type a variable needs to be passed"
converter toMetadataArray*(se: varargs[int]): MetadataArray {.inline.} =
  result.len = se.len
  for i in 0..<se.len:
    result.data[i] = se[i]


block troofregression:
  when NimVersion >= "0.17.3":
    type Index = int or BackwardsIndex
    template `^^`(s, i: untyped): untyped =
      when i is BackwardsIndex:
        s.len - int(i)
      else: i
  else:
    type Index = int
    template `^^`(s, i: untyped): untyped =
      i

  ## With Nim devel from the start of the week (~Oct30) I managed to trigger "lib/system.nim(3536, 4) Error: expression has no address"
  ## but I can't anymore after updating Nim (Nov5)
  ## Now commenting this plain compiles and removes the error "lib/system.nim(3536, 3) Error: for a 'var' type a variable needs to be passed"
  proc `[]`(a: var MetadataArray, idx: Index): var int {.inline.} =
    a.data[a ^^ idx]


  ##############################
  ### Completely unrelated lib that triggers the issue

  type
    MySeq[T] = ref object
      data: seq[T]

  proc test[T](sx: MySeq[T]) =
    # Removing the backward index removes the error "lib/system.nim(3536, 3) Error: for a 'var' type a variable needs to be passed"
    echo sx.data[^1] # error here

  let s = MySeq[int](data: @[1, 2, 3])
  s.test()


  # bug #6989

  type Dist = distinct int

  proc mypred[T: Ordinal](x: T): T = T(int(x)-1)
  proc cons(x: int): Dist = Dist(x)

  var d: Dist

  template `^+`(s, i: untyped): untyped =
    (when i is BackwardsIndex: s.len - int(i) else: int(i))

  proc `...`[T, U](a: T, b: U): HSlice[T, U] =
    result.a = a
    result.b = b

  proc `...`[T](b: T): HSlice[int, T] =
    result.b = b

  template `...<`(a, b: untyped): untyped =
    ## a shortcut for 'a..pred(b)'.
    a ... pred(b)

  template check(a, b) =
    if $a != b:
      echo "Failure ", a, " != ", b

  check typeof(4 ...< 1), "HSlice[system.int, system.int]"
  check typeof(4 ...< ^1), "HSlice[system.int, system.BackwardsIndex]"
  check typeof(4 ... pred(^1)), "HSlice[system.int, system.BackwardsIndex]"
  check typeof(4 ... mypred(8)), "HSlice[system.int, system.int]"
  check typeof(4 ... mypred(^1)), "HSlice[system.int, system.BackwardsIndex]"

  var rot = 8

  proc bug(s: string): string =
    result = s
    result = result[result.len - rot .. ^1] & "__" & result[0 ..< ^rot]

  const testStr = "abcdefgasfsgdfgsgdfggsdfasdfsafewfkljdsfajsdflfdjkl"

  echo bug(testStr)
  echo testStr[testStr.len - 8 .. testStr.len - 1] & "__" & testStr[0 .. testStr.len - pred(rot)]

  var
    instructions = readFile(parentDir(currentSourcePath) / "troofregression2.txt").split(',')
    programs = "abcdefghijklmnop"

  proc dance(dancers: string): string =
    result = dancers
    for instr in instructions:
      let rem = instr[1 .. instr.high]
      case instr[0]
      of 's':
        let rot = rem.parseInt
        result = result[result.len - rot .. ^1] & result[0 ..< ^rot]
      of 'x':
        let
          x = rem.split('/')
          a = x[0].parseInt
          b = x[1].parseInt
        swap(result[a], result[b])
      of 'p':
        let
          a = result.find(rem[0])
          b = result.find(rem[^1])
        result[a] = rem[^1]
        result[b] = rem[0]
      else: discard

  proc longDance(dancers: string, iterations = 1_000_000_000): string =
    var
      dancers = dancers
      seen = @[dancers]
    for i in 1 .. iterations:
      dancers = dancers.dance()
      if dancers in seen:
        return seen[iterations mod i]
      seen.add(dancers)

  echo dance(programs)
  echo longDance(programs)



block tunchecked:
  {.boundchecks: on.}
  type Unchecked = UncheckedArray[char]

  var x = cast[ptr Unchecked](alloc(100))
  x[5] = 'x'



import macros
block t7818:
  # bug #7818
  # this is not a macro bug, but array construction bug
  # I use macro to avoid object slicing
  # see #7712 and #7637

  type
    Vehicle[T] = object of RootObj
      tire: T
    Car[T] = object of Vehicle[T]
    Bike[T] = object of Vehicle[T]

  macro peek(n: typed): untyped =
    let val = getTypeImpl(n).treeRepr
    newLit(val)

  block test_t7818:
    var v = Vehicle[int](tire: 3)
    var c = Car[int](tire: 4)
    var b = Bike[int](tire: 2)

    let y = peek([c, b, v])
    let z = peek([v, c, b])
    doAssert(y == z)

  block test_t7906_1:
    proc init(x: typedesc, y: int): ref x =
      result = new(ref x)
      result.tire = y

    var v = init(Vehicle[int], 3)
    var c = init(Car[int], 4)
    var b = init(Bike[int], 2)

    let y = peek([c, b, v])
    let z = peek([v, c, b])
    doAssert(y == z)

  block test_t7906_2:
    var v = Vehicle[int](tire: 3)
    var c = Car[int](tire: 4)
    var b = Bike[int](tire: 2)

    let y = peek([c.addr, b.addr, v.addr])
    let z = peek([v.addr, c.addr, b.addr])
    doAssert(y == z)

  block test_t7906_3:
    type
      Animal[T] = object of RootObj
        hair: T
      Mammal[T] = object of Animal[T]
      Monkey[T] = object of Mammal[T]

    var v = Animal[int](hair: 3)
    var c = Mammal[int](hair: 4)
    var b = Monkey[int](hair: 2)

    let z = peek([c.addr, b.addr, v.addr])
    let y = peek([v.addr, c.addr, b.addr])
    doAssert(y == z)

  type
    Fruit[T] = ref object of RootObj
      color: T
    Apple[T] = ref object of Fruit[T]
    Banana[T] = ref object of Fruit[T]

  proc testArray[T](x: array[3, Fruit[T]]): string =
    result = ""
    for c in x:
      result.add $c.color

  proc testOpenArray[T](x: openArray[Fruit[T]]): string =
    result = ""
    for c in x:
      result.add $c.color

  block test_t7906_4:
    var v = Fruit[int](color: 3)
    var c = Apple[int](color: 4)
    var b = Banana[int](color: 2)

    let y = peek([c, b, v])
    let z = peek([v, c, b])
    doAssert(y == z)

  block test_t7906_5:
    var a = Fruit[int](color: 1)
    var b = Apple[int](color: 2)
    var c = Banana[int](color: 3)

    doAssert(testArray([a, b, c]) == "123")
    doAssert(testArray([b, c, a]) == "231")

    doAssert(testOpenArray([a, b, c]) == "123")
    doAssert(testOpenArray([b, c, a]) == "231")

    doAssert(testOpenArray(@[a, b, c]) == "123")
    doAssert(testOpenArray(@[b, c, a]) == "231")

  proc testArray[T](x: array[3, ptr Vehicle[T]]): string =
    result = ""
    for c in x:
      result.add $c.tire

  proc testOpenArray[T](x: openArray[ptr Vehicle[T]]): string =
    result = ""
    for c in x:
      result.add $c.tire

  block test_t7906_6:
    var u = Vehicle[int](tire: 1)
    var v = Bike[int](tire: 2)
    var w = Car[int](tire: 3)

    doAssert(testArray([u.addr, v.addr, w.addr]) == "123")
    doAssert(testArray([w.addr, u.addr, v.addr]) == "312")

    doAssert(testOpenArray([u.addr, v.addr, w.addr]) == "123")
    doAssert(testOpenArray([w.addr, u.addr, v.addr]) == "312")

    doAssert(testOpenArray(@[u.addr, v.addr, w.addr]) == "123")
    doAssert(testOpenArray(@[w.addr, u.addr, v.addr]) == "312")

block trelaxedindextyp:
  # any integral type is allowed as index
  proc foo(x: ptr UncheckedArray[int]; idx: uint64) = echo x[idx]
  proc foo(x: seq[int]; idx: uint64) = echo x[idx]
  proc foo(x: string|cstring; idx: uint64) = echo x[idx]
  proc foo(x: openArray[int]; idx: uint64) = echo x[idx]

block t3899:
  # https://github.com/nim-lang/Nim/issues/3899
  type O = object
    a: array[1..2,float]
  template `[]`(x: O, i: int): float =
    x.a[i]
  const c = O(a: [1.0,2.0])
  echo c[2]

block arrayLiterals:
  type ABC = enum A, B, C
  template Idx[IdxT, ElemT](arr: array[IdxT, ElemT]): untyped = IdxT
  doAssert [A: 0, B: 1].Idx is range[A..B]
  doAssert [A: 0, 1, 3].Idx is ABC
  doAssert [1: 2][1] == 2
  doAssert [-1'i8: 2][-1] == 2
  doAssert [-1'i8: 2, 3, 4, 5].Idx is range[-1'i8..2'i8]



# bug #8316

proc myAppend[T](a:T):string=
  echo "a:", a
  return $a

template append2*(args: varargs[string, myAppend]): string =
  var ret:string
  for a in args:
    echo "ret:", ret
    ret.add(a)
  ret

let foo = append2("1", "2", "3")
echo foo

block t12466:
  # https://github.com/nim-lang/Nim/issues/12466
  var a: array[288, uint16]
  for i in 0'u16 ..< 144'u16:
    a[0'u16 + i] = i
  for i in 0'u16 ..< 8'u16:
    a[0'u16 + i] = i

block t17705:
  # https://github.com/nim-lang/Nim/pull/17705
  var a = array[0, int].low
  a = int(a)
  var b = array[0, int].high
  b = int(b)

block t18643:
  # https://github.com/nim-lang/Nim/issues/18643
  let a: array[0, int] = []
  var caught = false
  let b = 9999999
  try:
    echo a[b]
  except IndexDefect:
    caught = true
  doAssert caught, "IndexDefect not caught!"
