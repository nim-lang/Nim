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

  let x9: array[-2..2, float] = [0, 1, 2, 3, 4]
  let x10: array[ABC, byte] = [a: 1, b: 2, c: 3]

block:
  type Foo = object
    x: BiggestInt
  var foo: Foo
  foo.x = case true
  of true: ord(1)
  else: 0
  foo.x = if true: ord(1) else: 0
