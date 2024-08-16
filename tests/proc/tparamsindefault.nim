discard """
output: '''
@[1, 2, 3]@[1, 2, 3]
a
a
1
3 is an int
2 is an int
miau is a string
f1 1 1 1
f1 2 3 3
f1 10 20 30
f2 100 100 100
f2 200 300 300
f2 300 400 400
f3 10 10 20
f3 10 15 25
true true
false true
world
typedescDefault
'''
"""

template reject(x) =
  assert(not compiles(x))

block:
  # https://github.com/nim-lang/Nim/issues/7756
  proc foo[T](x: seq[T], y: seq[T] = x) =
    echo x, y

  let a = @[1, 2, 3]
  foo(a)

block:
  # https://github.com/nim-lang/Nim/issues/1201
  proc issue1201(x: char|int = 'a') = echo x

  issue1201()
  issue1201('a')
  issue1201(1)

  # https://github.com/nim-lang/Nim/issues/7000
  proc test(a: int|string = 2) =
    when a is int:
        echo a, " is an int"
    elif a is string:
        echo a, " is a string"

  test(3) # works
  test() # works
  test("miau")

block:
  # https://github.com/nim-lang/Nim/issues/3002 and similar
  proc f1(a: int, b = a, c = b) =
    echo "f1 ", a, " ", b, " ", c

  proc f2(a: int, b = a, c: int = b) =
    echo "f2 ", a, " ", b, " ", c

  proc f3(a: int, b = a, c = a + b) =
    echo "f3 ", a, " ", b, " ", c

  f1 1
  f1(2, 3)
  f1 10, 20, 30
  100.f2
  200.f2 300
  300.f2(400)

  10.f3()
  10.f3(15)

  reject:
    # This is a type mismatch error:
    proc f4(a: int, b = a, c: float = b) = discard

  reject:
    # undeclared identifier
    proc f5(a: int, b = c, c = 10) = discard

  reject:
    # undeclared identifier
    proc f6(a: int, b = b) = discard

  reject:
    # undeclared identifier
    proc f7(a = a) = discard

block:
  proc f(a: var int, b: ptr int, c = addr(a)) =
    echo addr(a) == b, " ",  b == c

  var x = 10
  f(x, addr(x))
  f(x, nil, nil)

block:
  # https://github.com/nim-lang/Nim/issues/1046
  proc pySubstr(s: string, start: int, endd = s.len()): string =
    var
      revStart = start
      revEnd = endd

    if start < 0:
      revStart = s.len() + start
    if endd < 0:
      revEnd = s.len() + endd

    return s[revStart ..  revEnd-1]

  echo pySubstr("Hello world", -5)


# bug #11660

func typedescDefault(T: typedesc; arg: T = 0) = debugEcho "typedescDefault"
typedescDefault(int)
