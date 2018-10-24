discard """
output: '''
Hello World
Hello World
Hello World
Hello World
1
1
2
509
littleEndian

02468101214161820
(x: "string here", a: 1)
hallo40
1
2
'''
"""


import strutils, math


block tack:
  # the Ackermann function
  proc ack(x, y: int): int =
    if x != 0:
      if y != 0:
        return ack(x-1, ack(x, y-1))
      return ack(x-1, 1)
    else:
      return y + 1

  doAssert ack(3, 4) == 125



block tcast:
  type MyProc = proc() {.cdecl.}
  type MyProc2 = proc() {.nimcall.}
  type MyProc3 = proc() #{.closure.} is implicit

  proc testProc()  = echo "Hello World"

  proc callPointer(p: pointer) =
    # can cast to proc(){.cdecl.}
    let ffunc0 = cast[MyProc](p)
    # can cast to proc(){.nimcall.}
    let ffunc1 = cast[MyProc2](p)
    # cannot cast to proc(){.closure.}
    doAssert(not compiles(cast[MyProc3](p)))

    ffunc0()
    ffunc1()

  callPointer(cast[pointer](testProc))



block fibo:
  proc FibonacciA(n: int): int64 =
    var fn = float64(n)
    var p: float64 = (1.0 + sqrt(5.0)) / 2.0
    var q: float64 = 1.0 / p
    return int64((pow(p, fn) + pow(q, fn)) / sqrt(5.0))

  doAssert FibonacciA(4) == 3



block tcast:
  type MyProc = proc() {.cdecl.}
  type MyProc2 = proc() {.nimcall.}
  type MyProc3 = proc() #{.closure.} is implicit

  proc testProc() = echo "Hello World"

  proc callPointer(p: pointer) =
    # can cast to proc(){.cdecl.}
    let ffunc0 = cast[MyProc](p)
    # can cast to proc(){.nimcall.}
    let ffunc1 = cast[MyProc2](p)
    # cannot cast to proc(){.closure.}
    doAssert(not compiles(cast[MyProc3](p)))

    ffunc0()
    ffunc1()

  callPointer(cast[pointer](testProc))



block charinc:
  var c = '\0'
  while true:
    if c == '\xFF': break
    inc c
  echo "1"



block colonisproc:
  proc p(a, b: int, c: proc ()) =
    c()

  when false:
    # language spec changed:
    p(1, 3):
      echo 1
      echo 3

  p(1, 1, proc() =
    echo 1
    echo 2)



block temit:
  # Test the new ``emit`` pragma:
  {.emit: """
  static int cvariable = 420;

  """.}

  proc embedsC() =
    var nimVar = 89
    {.emit: """printf("%d\n", cvariable + (int)`nimVar`);""".}

  embedsC()



block tendian:
  # test the new endian magic
  writeLine(stdout, repr(system.cpuEndian))



block emptyecho:
  echo()



block tfilter:
  proc filter[T](list: seq[T], f: proc (item: T): bool {.closure.}): seq[T] =
    result = @[]
    for i in items(list):
      if f(i):
        result.add(i)
  let nums = @[0, 1, 2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20]

  when true:
    let nums2 = filter(nums,
                 (proc (item: int): bool =
                   result = (item mod 2) == 0)
                 )

  proc outer =
    # lets use a proper closure this time:
    var modulo = 2
    let nums2 = filter(nums,
                 (proc (item: int): bool = result = (item mod modulo) == 0)
                 )
    for n in nums2: stdout.write(n)
    stdout.write("\n")
  outer()

  proc compose[T](f1, f2: proc (x: T): T {.closure.}): proc (x: T): T {.closure.} =
    result = (proc (x: T): T =
               result = f1(f2(x)))
  proc add5(x: int): int = result = x + 5

  var test = compose(add5, add5)
  doAssert test(5) == 15



block tlocals:
  proc simple[T](a: T) =
    var
      x = "string here"
    echo locals()
  simple(1)

  type Foo2[T]=object
    a2: T

  proc numFields(T: typedesc[tuple|object]): int=
    var t:T
    for _ in t.fields: inc result

  proc test(baz: int, qux: var int): int =
    var foo: Foo2[int]
    let bar = "abc"
    let c1 = locals()
    doAssert numFields(c1.foo.type) == 1
    doAssert c1.bar == "abc"
    doAssert c1.baz == 123
    doAssert c1.result == 0
    doAssert c1.qux == 456

  var x1 = 456
  discard test(123, x1)



block tnewderef:
  var x: ref int
  new(x)
  x[] = 3
  doAssert x[] == 3



block tnewsets:
  const elem = ' '
  var s: set[char] = {elem}
  assert(elem in s and 'a' not_in s and 'c' not_in s )



block tpos:
  # test this particular function
  proc mypos(sub, s: string, start: int = 0): int =
    var
      i, j, M, N: int
    M = sub.len
    N = s.len
    i = start
    j = 0
    if i >= N:
      result = -1
    else:
      while true:
        if s[i] == sub[j]:
          inc(i)
          inc(j)
        else:
          i = i - j + 1
          j = 0
        if (j >= M) or (i >= N): break
      if j >= M:
        result = i - M
      else:
        result = -1

  var sub = "hello"
  var s = "world hello"
  doAssert mypos(sub, s) == 6



block tstrdesc:
  var x: array[0..2, int]
  x = [0, 1, 2]

  type
    TStringDesc {.final.} = object
      len, space: int # len and space without counting the terminating zero
      data: array[0..0, char] # for the '\0' character

  var emptyString {.exportc: "emptyString".}: TStringDesc



block tstrange:
  # test for extremely strange bug
  proc ack(x: int, y: int): int =
    if x != 0:
      if y != 5:
        return y
      return x
    return x+y

  proc gen[T](a: T) =
    write(stdout, a)

  gen("hallo")
  write(stdout, ack(5, 4))
  #OUT hallo4

  # bug #1442
  let h=3
  for x in 0..<h.int:
    echo x



block tunsignedinc:
  block: # bug #2427
    var x = 0'u8
    dec x # OverflowError
    x -= 1 # OverflowError
    x = x - 1 # No error
    doAssert(x == 253'u8)

  block:
    var x = 130'u8
    x += 130'u8
    doAssert(x == 4'u8)

  block:
    var x = 40000'u16
    x = x + 40000'u16
    doAssert(x == 14464'u16)

  block:
    var x = 4000000000'u32
    x = x + 4000000000'u32
    doAssert(x == 3705032704'u32)

  block:
    var x = 123'u16
    x -= 125
    doAssert(x == 65534'u16)



block tvarious1:
  doAssert len([1_000_000]) == 1

  type
    TArray = array[0..3, int]
    TVector = distinct array[0..3, int]
  proc `[]`(v: TVector; idx: int): int = TArray(v)[idx]
  var v: TVector
  doAssert v[2] == 0
