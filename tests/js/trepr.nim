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
  
  doassert(repr(na) == "-120")
  doassert(repr(nb) == "-32700")
  doassert(repr(nc) == "-2147483000")
  doassert(repr(nd) ==  "-9223372036854775000")
  doassert(repr(ne) == "-1234567")
  doassert(repr(pa) == "120")
  doassert(repr(pb) == "32700")
  doassert(repr(pc) == "2147483000")
  doassert(repr(pd) ==  "9223372036854775000")
  doassert(repr(pe) == "1234567")

block uints:
  let 
    a: uint8 = 254'u8
    b: uint16 = 65300'u16
    c: uint32 =  4294967290'u32
    # d: uint64 = 18446744073709551610'u64  -> unknown node type
    e: uint = 1234567
  
  doassert(repr(a) == "254")
  doassert(repr(b) == "65300")
  doassert(repr(c) == "4294967290")
  # doassert(repr(d) ==  "18446744073709551610")
  doassert(repr(e) == "1234567")

block floats:
  let 
    a: float32 = 3.4e38'f32
    b: float64 = 1.7976931348623157e308'f64
    c: float = 1234.567e89
  
  when defined js: 
    doassert(repr(a) == "3.4e+38") # in C: 3.399999952144364e+038
    doassert(repr(b) == "1.7976931348623157e+308") # in C: 1.797693134862316e+308
    doassert(repr(c) == "1.234567e+92") # in C: 1.234567e+092

block bools:
  let 
    a: bool = true
    b: bool = false
  
  doassert(repr(a) == "true") 
  doassert(repr(b) == "false")

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
  
  doassert(repr(aeA) == "aeA") 
  doassert(repr(aeB) == "aeB")
  doassert(repr(aeC) == "aeC") 
  doassert(repr(heA) == "heA")
  doassert(repr(heB) == "heB") 
  doassert(repr(heC) == "heC")

block chars:
  let
    a = 'a'
    b = 'z'
    one = '1'
    nl = '\x0A'
  
  doassert(repr(a) == "'a'")
  doassert(repr(b) == "'z'")
  doassert(repr(one) == "'1'")
  doassert(repr(nl) == "'\\10'")

block strings:
  let 
    a:string = "12345"
    b:string = "hello,repr"
    c:string = "hi\nthere"
  when defined js: # C prepends the pointer, JS does not.
    doassert(repr(a) == "\"12345\"")
    doassert(repr(b) == "\"hello,repr\"")
    doassert(repr(c) == "\"hi\nthere\"")  

block sets:
  let
    a: set[int16] = {1'i16,2'i16,3'i16}
    b: set[char] = {'A','k'}
    
  doassert(repr(a) == "{1, 2, 3}")
  doassert(repr(b) == "{'A', 'k'}")

block ranges:
  let 
    a: range[0..12] = 6
    b: range[-12..0] = -6
  doassert(repr(a) == "6")
  doassert(repr(b) == "-6")

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
    ot: OtherTuple = (a:true,b:120'i8)
    t: ATuple = (a:42, b:12.34,c:"tuple",d:ot)
  when defined js:
    doassert(repr(ot) == """
[Field0 = true,
Field1 = 120]
""")
    doassert(repr(t) == """
[Field0 = 42,
Field1 = 12.34,
Field2 = "tuple",
Field3 = [Field0 = true,
Field1 = 120]]
""")

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
    oo: OtherObj = OtherObj(a:true,b:120'i8)
    o: AnObj = AnObj(a:42, b:12.34,c:oo)

  doassert(repr(oo) == """
[a = true,
b = 120]
""")
  doassert(repr(o) == """
[a = 42,
b = 12.34,
c = [a = true,
b = 120]]
""")

block arrays:
  type
    AObj = object
      x: int
      y: array[3,float]
  let
    a = [0.0,1,2]
    b = [a,a,a]
    o = AObj(x:42,y:a)
    c = [o,o,o]
    d = ["hi","array","!"]
    
  doassert(repr(a) == "[0.0, 1.0, 2.0]\n", repr(a))
  doassert(repr(b) == "[[0.0, 1.0, 2.0], [0.0, 1.0, 2.0], [0.0, 1.0, 2.0]]\n")
  doassert(repr(c) == """
[[x = 42,
y = [0.0, 1.0, 2.0]], [x = 42,
y = [0.0, 1.0, 2.0]], [x = 42,
y = [0.0, 1.0, 2.0]]]
""")
  doassert(repr(d) == "[\"hi\", \"array\", \"!\"]\n")

block seqs:
  type
    AObj = object
      x: int
      y: seq[float]
  let
    a = @[0.0,1,2]
    b = @[a,a,a]
    o = AObj(x:42,y:a)
    c = @[o,o,o]
    d = @["hi","array","!"]
    
  doassert(repr(a) == "@[0.0, 1.0, 2.0]\n", repr(a))
  doassert(repr(b) == "@[@[0.0, 1.0, 2.0], @[0.0, 1.0, 2.0], @[0.0, 1.0, 2.0]]\n")
  doassert(repr(c) == """
@[[x = 42,
y = @[0.0, 1.0, 2.0]], [x = 42,
y = @[0.0, 1.0, 2.0]], [x = 42,
y = @[0.0, 1.0, 2.0]]]
""")
  doassert(repr(d) == "@[\"hi\", \"array\", \"!\"]\n")

block ptrs:
  type 
    AObj = object
      x: ptr array[2, AObj]
      y: int
  var 
    a = [12.0,13.0,14.0]
    b = addr a[0]
    c = addr a[2]
    d = AObj()
  
  doassert(repr(a) == "[12.0, 13.0, 14.0]\n")
  doassert(repr(b) == "ref 0 --> 12.0\n")
  doassert(repr(c) == "ref 2 --> 14.0\n")
  doassert(repr(d) == """
[x = nil,
y = 0]
""")

block ptrs:
  type 
    AObj = object
      x: ref array[2, AObj]
      y: int
  var 
    a = AObj()
  
  new(a.x)

  doassert(repr(a) == """
[x = ref 0 --> [[x = nil,
y = 0], [x = nil,
y = 0]],
y = 0]
""")

block procs:
  proc test(): int =
    echo "hello"
  var 
    ptest = test
    nilproc: proc(): int
  
  doassert(repr(test) == "0\n")
  doassert(repr(ptest) == "0\n")
  doassert(repr(nilproc) == "nil\n")

block bunch:
  type
    AnEnum = enum
      eA,eB,eC
    B = object
      a: string
      b: seq[char] 
    A = object
      a : uint32
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
      o: tuple[ x: B, y: string]
      p: proc(b:B):ref B
      q: cstring
      
  proc refB(b:B):ref B =
    new result
    result[] = b
  
  var
    aa : A
    bb : B = B( a: "inner", b: @['o','b','j'])
    cc : A = A( a:12, b:1, c:1.2, d:'\0', e:eC,
                f:"hello", g:{'A'}, h: {2'i16},
                i: ["hello","world","array"], 
                j: @["hello","world","seq"], k: -1,
                l:bb, m: refB(bb), n: addr bb,
                o: (bb, "tuple!"), p: refB, q: "cstringtest" )

  doassert(repr(aa) == """
[a = 0,
b = 0,
c = 0.0,
d = '\0',
e = eA,
f = nil,
g = {},
h = {},
i = [nil, nil, nil],
j = nil,
k = 0,
l = [a = nil,
b = nil],
m = nil,
n = nil,
o = [Field0 = [a = nil,
b = nil],
Field1 = nil],
p = nil,
q = nil]
""")
  doassert(repr(cc) == """
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
q = "cstringtest"]
""")