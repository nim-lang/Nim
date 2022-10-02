discard """
  output:
'''
TEMP=C:\Programs\xyz\bin
8 5 0 0
pre test a:test b:1 c:2 haha:3
assignment test a:test b:1 c:2 haha:3
abc123
'''
"""

#[
Concrete '='
Concrete '='
Concrete '='
Concrete '='
Concrete '='
GenericT[T] '=' int
GenericT[T] '=' float
GenericT[T] '=' float
GenericT[T] '=' float
GenericT[T] '=' string
GenericT[T] '=' int8
GenericT[T] '=' bool
GenericT[T] '=' bool
GenericT[T] '=' bool
GenericT[T] '=' bool
]#

block tassign:
# Test the assignment operator for complex types which need RTTI
  type
    TRec = object
      x, y: int
      s: string
      seq: seq[string]
      arr: seq[seq[array[0..3, string]]]
    TRecSeq = seq[TRec]

  proc test() =
    var
      a, b: TRec
    a.x = 1
    a.y = 2
    a.s = "Hallo!"
    a.seq = @["abc", "def", "ghi", "jkl"]
    a.arr = @[]
    setLen(a.arr, 4)
    a.arr[0] = @[]
    a.arr[1] = @[]

    b = a # perform a deep copy here!
    b.seq = @["xyz", "huch", "was", "soll"]
    doAssert len(a.seq) == 4
    doAssert a.seq[3] == "jkl"
    doAssert len(b.seq) == 4
    doAssert b.seq[3] == "soll"
    doAssert b.y == 2

  test()



import strutils
block tcopy:
  proc main() =
    const
      example = r"TEMP=C:\Programs\xyz\bin"
    var
      a, b: string
      p: int
    p = find(example, "=")
    a = substr(example, 0, p-1)
    b = substr(example, p+1)
    writeLine(stdout, a & '=' & b)

  main()



block tgenericassign:
  type
    TAny {.pure.} = object
      value: pointer
      rawType: pointer

  proc newAny(value, rawType: pointer): TAny =
    result.value = value
    result.rawType = rawType

  var name: cstring = "example"

  var ret: seq[tuple[name: string, a: TAny]] = @[]
  for i in 0 .. 8000:
    var tup = ($name, newAny(nil, nil))
    doAssert(tup[0] == "example")
    ret.add(tup)
    doAssert(ret[ret.len()-1][0] == "example")



block tgenericassign_tuples:
  var t, s: tuple[x: string, c: int]

  proc ugh: seq[tuple[x: string, c: int]] =
    result = @[("abc", 232)]

  t = ugh()[0]
  s = t
  s = ugh()[0]

  doAssert s[0] == "abc"
  doAssert s[1] == 232



block tobjasgn:
  type
    TSomeObj = object of RootObj
      a, b: int
    PSomeObj = ref object
      a, b: int

  var a = TSomeObj(a: 8)
  var b = PSomeObj(a: 5)
  echo a.a, " ", b.a, " ", a.b, " ", b.b

  # bug #575

  type
    Something = object of RootObj
      a: string
      b, c: int32

  type
    Other = object of Something
      haha: int

  proc `$`(x: Other): string =
    result = "a:" & x.a & " b:" & $x.b & " c:" & $x.c & " haha:" & $x.haha

  var
    t: Other

  t.a = "test"
  t.b = 1
  t.c = 2
  t.haha = 3

  echo "pre test ", $t
  var x = t
  echo "assignment test ", x


when false:
  type
    Concrete = object
      a, b: string

  proc `=`(d: var Concrete; src: Concrete) =
    shallowCopy(d.a, src.a)
    shallowCopy(d.b, src.b)
    echo "Concrete '='"

  var x, y: array[0..2, Concrete]
  var cA, cB: Concrete

  var cATup, cBTup: tuple[x: int, ha: Concrete]

  x = y
  cA = cB
  cATup = cBTup

  type
    GenericT[T] = object
      a, b: T

  proc `=`[T](d: var GenericT[T]; src: GenericT[T]) =
    shallowCopy(d.a, src.a)
    shallowCopy(d.b, src.b)
    echo "GenericT[T] '=' ", typeof(T).name

  var ag: GenericT[int]
  var bg: GenericT[int]

  ag = bg

  var xg, yg: array[0..2, GenericT[float]]
  var cAg, cBg: GenericT[string]

  var cATupg, cBTupg: tuple[x: int, ha: GenericT[int8]]

  xg = yg
  cAg = cBg
  cATupg = cBTupg

  var caSeqg, cbSeqg: seq[GenericT[bool]]
  newSeq(cbSeqg, 4)
  caSeqg = cbSeqg

  when false:
    type
      Foo = object
        case b: bool
        of false: xx: GenericT[int]
        of true: yy: bool

    var
      a, b: Foo
    a = b

block tgeneric_assign_varargs:
  template fatal(msgs: varargs[string]) =
    for msg in msgs:
      stdout.write(msg)
    stdout.write('\n')

  fatal "abc", "123"
