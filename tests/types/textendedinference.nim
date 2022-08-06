{.hint[ConvFromXtoItselfNotNeeded]: off.}

block:
  var s: seq[string] = (discard; @[])

  var x: set[char] =
    if true:
      try:
        case 1
        of 1:
          if false:
            {'4'}
          else:
            block:
              s.add "a"
              {}
        else: {'3'}
      except: {'2'}
    else: {'1'}
  doAssert x is set[char]
  doAssert x == {}
  doAssert s == @["a"]

  x = {'a', 'b'}
  doAssert x == {'a', 'b'}

  x = (s.add "b"; {})
  doAssert x == {}
  doAssert s == @["a", "b"]

  let x2: set[byte] = {1}
  doAssert x2 == {1u8}

block:
  let x3: array[0..2, byte] = [1, 2, 3]
  #let x4: openarray[byte] = [1, 2, 3]
  #let x5: openarray[byte] = @[1, 2, 3]
  let x6: seq[byte] = @[1, 2, 3]
  let x7: seq[seq[float32]] = @[@[1, 2, 3], @[4.3, 5, 6]]
  type ABC = enum a, b, c
  let x8: array[ABC, byte] = [1, 2, 3]
  doAssert x8[a] == 1
  doAssert x8[a] + x8[b] == x8[c]

  const x9: array[-2..2, float] = [0, 1, 2, 3, 4]
  let x10: array[ABC, byte] = block:
    {.gcsafe.}:
      [a: 1, b: 2, c: 3]

block:
  type Foo = object
    x: BiggestInt
  var foo: Foo
  foo.x = case true
  of true: ord(1)
  else: 0
  foo.x = if true: ord(1) else: 0

block:
  type Foo = object
    x: (float, seq[(byte, seq[byte])])
    
  let foo = Foo(x: (1, @{2: @[], 3: @[4, 5]}))
  doAssert foo.x == (1.0, @{2u8: @[], 3u8: @[4u8, 5]})

block:
  type Foo = object
    x: tuple[a: float, b: seq[(byte, seq[byte])]]
    
  let foo = Foo(x: (a: 1, b: @{2: @[3, 4], 5: @[]}))
  doAssert foo.x == (1.0, @{2u8: @[3u8, 4], 5u8: @[]})

block:
  proc foo(): seq[float] = @[1]

  let fooLamb = proc(): seq[float] = @[1]

  doAssert foo() == fooLamb()

block:
  type Foo[T] = float32

  let x: seq[Foo[int32]] = @[1]

block:
  type Foo = ref object
  type Bar[T] = ptr object

  let x1: seq[Foo] = @[nil]
  let x2: seq[Bar[int]] = @[nil]
  let x3: seq[cstring] = @[nil]

block:
  let x: seq[cstring] = @["abc", nil, "def"]
  doAssert x.len == 3
  doAssert x[0] == cstring"abc"
  doAssert x[1].isNil
  doAssert x[2] == "def".cstring

when false: # unsupported
  block: # type conversion
    let x = seq[(cstring, float32)](@{"abc": 1.0, "def": 2.0})
    doAssert x[0] == (cstring"abc", 1.0'f32)
    doAssert x[1] == (cstring"def", 2.0'f32)
