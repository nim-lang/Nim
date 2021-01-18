# xxx consider merging with `tests/stdlib/trepr.nim` to increase overall test coverage

block ints:
  let
    na: int8 = -120'i8
    nb: int16 = -32700'i16
    nc: int32 = -2147483000'i32
    nd: int64 = -9223372036854775000'i64
    ne: int = -1234567
    pa: int8 = 120'i8
    pb: int16 = 32700'i16
    pc: int32 = 2147483000'i32
    pd: int64 = 9223372036854775000'i64
    pe: int = 1234567

  doAssert(repr(na) == "-120")
  doAssert(repr(nb) == "-32700")
  doAssert(repr(nc) == "-2147483000")
  doAssert(repr(nd) == "-9223372036854775000")
  doAssert(repr(ne) == "-1234567")
  doAssert(repr(pa) == "120")
  doAssert(repr(pb) == "32700")
  doAssert(repr(pc) == "2147483000")
  doAssert(repr(pd) == "9223372036854775000")
  doAssert(repr(pe) == "1234567")

block uints:
  let
    a: uint8 = 254'u8
    b: uint16 = 65300'u16
    c: uint32 = 4294967290'u32
    # d: uint64 = 18446744073709551610'u64  -> unknown node type
    e: uint = 1234567

  doAssert(repr(a) == "254")
  doAssert(repr(b) == "65300")
  doAssert(repr(c) == "4294967290")
  # doAssert(repr(d) == "18446744073709551610")
  doAssert(repr(e) == "1234567")

block floats:
  let
    a: float32 = 3.4e38'f32
    b: float64 = 1.7976931348623157e308'f64
    c: float = 1234.567e89

  when defined js:
    doAssert(repr(a) == "3.4e+38") # in C: 3.399999952144364e+038
    doAssert(repr(b) == "1.7976931348623157e+308") # in C: 1.797693134862316e+308
    doAssert(repr(c) == "1.234567e+92") # in C: 1.234567e+092

block bools:
  let
    a: bool = true
    b: bool = false

  doAssert(repr(a) == "true")
  doAssert(repr(b) == "false")

block enums:
  type
    AnEnum = enum
      aeA
      aeB
      aeC
    HoledEnum = enum
      heA = -12
      heB = 15
      heC = 123

  doAssert(repr(aeA) == "aeA")
  doAssert(repr(aeB) == "aeB")
  doAssert(repr(aeC) == "aeC")
  doAssert(repr(heA) == "heA")
  doAssert(repr(heB) == "heB")
  doAssert(repr(heC) == "heC")

block emums_and_unicode: #6741
  type K = enum Kanji = "漢字"
  let kanji = Kanji
  doAssert(kanji == Kanji, "Enum values are not equal")
  doAssert($kanji == $Kanji, "Enum string values are not equal")

block chars:
  let
    a = 'a'
    b = 'z'
    one = '1'
    nl = '\x0A'

  doAssert(repr(a) == "'a'")
  doAssert(repr(b) == "'z'")
  doAssert(repr(one) == "'1'")
  doAssert(repr(nl) == "'\\10'")

block strings:
  let
    a: string = "12345"
    b: string = "hello,repr"
    c: string = "hi\nthere"
  when defined js: # C prepends the pointer, JS does not.
    doAssert(repr(a) == "\"12345\"")
    doAssert(repr(b) == "\"hello,repr\"")
    doAssert(repr(c) == "\"hi\\10there\"")

block sets:
  let
    a: set[int16] = {1'i16, 2'i16, 3'i16}
    b: set[char] = {'A', 'k'}

  doAssert(repr(a) == "{1, 2, 3}")
  doAssert(repr(b) == "{'A', 'k'}")

block ranges:
  let
    a: range[0..12] = 6
    b: range[-12..0] = -6
  doAssert(repr(a) == "6")
  doAssert(repr(b) == "-6")

block tuples:
  type
    ATuple = tuple
      a: int
      b: float
      c: string
      d: OtherTuple
    OtherTuple = tuple
      a: bool
      b: int8

  let
    ot: OtherTuple = (a: true, b: 120'i8)
    t: ATuple = (a: 42, b: 12.34, c: "tuple", d: ot)
  when defined js:
    doAssert(repr(ot) == """
[Field0 = true,
Field1 = 120]""")
    doAssert(repr(t) == """
[Field0 = 42,
Field1 = 12.34,
Field2 = "tuple",
Field3 = [Field0 = true,
Field1 = 120]]""")

block objects:
  type
    AnObj = object
      a: int
      b: float
      c: OtherObj
    OtherObj = object
      a: bool
      b: int8
  let
    oo: OtherObj = OtherObj(a: true, b: 120'i8)
    o: AnObj = AnObj(a: 42, b: 12.34, c: oo)

  doAssert(repr(oo) == """
[a = true,
b = 120]""")
  doAssert(repr(o) == """
[a = 42,
b = 12.34,
c = [a = true,
b = 120]]""")

block arrays:
  type
    AObj = object
      x: int
      y: array[3,float]
  let
    a = [0.0, 1, 2]
    b = [a, a, a]
    o = AObj(x: 42, y: a)
    c = [o, o, o]
    d = ["hi", "array", "!"]

  doAssert(repr(a) == "[0.0, 1.0, 2.0]")
  doAssert(repr(b) == "[[0.0, 1.0, 2.0], [0.0, 1.0, 2.0], [0.0, 1.0, 2.0]]")
  doAssert(repr(c) == """
[[x = 42,
y = [0.0, 1.0, 2.0]], [x = 42,
y = [0.0, 1.0, 2.0]], [x = 42,
y = [0.0, 1.0, 2.0]]]""")
  doAssert(repr(d) == "[\"hi\", \"array\", \"!\"]")

block seqs:
  type
    AObj = object
      x: int
      y: seq[float]
  let
    a = @[0.0, 1, 2]
    b = @[a, a, a]
    o = AObj(x: 42, y: a)
    c = @[o, o, o]
    d = @["hi", "array", "!"]

  doAssert(repr(a) == "@[0.0, 1.0, 2.0]")
  doAssert(repr(b) == "@[@[0.0, 1.0, 2.0], @[0.0, 1.0, 2.0], @[0.0, 1.0, 2.0]]")
  doAssert(repr(c) == """
@[[x = 42,
y = @[0.0, 1.0, 2.0]], [x = 42,
y = @[0.0, 1.0, 2.0]], [x = 42,
y = @[0.0, 1.0, 2.0]]]""")
  doAssert(repr(d) == "@[\"hi\", \"array\", \"!\"]")

block ptrs:
  type
    AObj = object
      x: ptr array[2, AObj]
      y: int
  var
    a = [12.0, 13.0, 14.0]
    b = addr a[0]
    c = addr a[2]
    d = AObj()

  doAssert(repr(a) == "[12.0, 13.0, 14.0]")
  doAssert(repr(b) == "ref 0 --> 12.0")
  doAssert(repr(c) == "ref 2 --> 14.0")
  doAssert(repr(d) == """
[x = nil,
y = 0]""")

block ptrs:
  type
    AObj = object
      x: ref array[2, AObj]
      y: int
  var
    a = AObj()

  new(a.x)

  doAssert(repr(a) == """
[x = ref 0 --> [[x = nil,
y = 0], [x = nil,
y = 0]],
y = 0]""")

block procs:
  proc test(): int =
    echo "hello"
  var
    ptest = test
    nilproc: proc(): int

  doAssert(repr(test) == "0")
  doAssert(repr(ptest) == "0")
  doAssert(repr(nilproc) == "nil")

block bunch:
  type
    AnEnum = enum
      eA, eB, eC
    B = object
      a: string
      b: seq[char]
    A = object
      a: uint32
      b: int
      c: float
      d: char
      e: AnEnum
      f: string
      g: set[char]
      h: set[int16]
      i: array[3,string]
      j: seq[string]
      k: range[-12..12]
      l: B
      m: ref B
      n: ptr B
      o: tuple[x: B, y: string]
      p: proc(b: B): ref B
      q: cstring

  proc refB(b:B):ref B =
    new result
    result[] = b

  var
    aa: A
    bb: B = B(a: "inner", b: @['o', 'b', 'j'])
    cc: A = A(a: 12, b: 1, c: 1.2, d: '\0', e: eC,
                f: "hello", g: {'A'}, h: {2'i16},
                i: ["hello", "world", "array"],
                j: @["hello", "world", "seq"], k: -1,
                l: bb, m: refB(bb), n: addr bb,
                o: (bb, "tuple!"), p: refB, q: "cstringtest" )

  doAssert(repr(aa) == """
[a = 0,
b = 0,
c = 0.0,
d = '\0',
e = eA,
f = "",
g = {},
h = {},
i = ["", "", ""],
j = @[],
k = 0,
l = [a = "",
b = @[]],
m = nil,
n = nil,
o = [Field0 = [a = "",
b = @[]],
Field1 = ""],
p = nil,
q = nil]""")
  doAssert(repr(cc) == """
[a = 12,
b = 1,
c = 1.2,
d = '\0',
e = eC,
f = "hello",
g = {'A'},
h = {2},
i = ["hello", "world", "array"],
j = @["hello", "world", "seq"],
k = -1,
l = [a = "inner",
b = @['o', 'b', 'j']],
m = ref 0 --> [a = "inner",
b = @['o', 'b', 'j']],
n = ref 0 --> [a = "inner",
b = @['o', 'b', 'j']],
o = [Field0 = [a = "inner",
b = @['o', 'b', 'j']],
Field1 = "tuple!"],
p = 0,
q = "cstringtest"]""")

block another:
  type
    Size1 = enum
      s1a, s1b
    Size2 = enum
      s2c=0, s2d=20000
    Size3 = enum
      s3e=0, s3f=2000000000

  doAssert(repr([s1a, s1b]) == "[s1a, s1b]")
  doAssert(repr([s2c, s2d]) == "[s2c, s2d]")
  doAssert(repr([s3e, s3f]) == "[s3e, s3f]")

block another2:

  type
    AnEnum = enum
      en1, en2, en3, en4, en5, en6

    Point {.final.} = object
      x, y, z: int
      s: array[0..1, string]
      e: AnEnum

  var
    p: Point
    q: ref Point
    s: seq[ref Point]

  p.x = 0
  p.y = 13
  p.z = 45
  p.s[0] = "abc"
  p.s[1] = "xyz"
  p.e = en6

  new(q)
  q[] = p

  s = @[q, q, q, q]

  doAssert(repr(p) == """
[x = 0,
y = 13,
z = 45,
s = ["abc", "xyz"],
e = en6]""")
  doAssert(repr(q) == """
ref 0 --> [x = 0,
y = 13,
z = 45,
s = ["abc", "xyz"],
e = en6]""")
  doAssert(repr(s) == """
@[ref 0 --> [x = 0,
y = 13,
z = 45,
s = ["abc", "xyz"],
e = en6], ref 1 --> [x = 0,
y = 13,
z = 45,
s = ["abc", "xyz"],
e = en6], ref 2 --> [x = 0,
y = 13,
z = 45,
s = ["abc", "xyz"],
e = en6], ref 3 --> [x = 0,
y = 13,
z = 45,
s = ["abc", "xyz"],
e = en6]]""")
  doAssert(repr(en4) == "en4")

  doAssert(repr({'a'..'p'}) == "{'a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i', 'j', 'k', 'l', 'm', 'n', 'o', 'p'}")
