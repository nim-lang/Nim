discard """
output: '''true
true
true
true
p has been called.
p has been called.
implicit generic
generic
false
true
-1
Meow'''
"""

# https://github.com/nim-lang/Nim/issues/1147
type TTest = object
  vals: seq[int]

proc add*(self: var TTest, val: int) =
  self.vals.add(val)

type CAddable = concept x
  x[].add(int)

echo((ref TTest) is CAddable) # true

# https://github.com/nim-lang/Nim/issues/1570
type ConcretePointOfFloat = object
  x, y: float

type ConcretePoint[Value] = object
  x, y: Value

type AbstractPointOfFloat = concept p
  p.x is float and p.y is float

let p1 = ConcretePointOfFloat(x: 0, y: 0)
let p2 = ConcretePoint[float](x: 0, y: 0)

echo p1 is AbstractPointOfFloat      # true
echo p2 is AbstractPointOfFloat      # true
echo p2.x is float and p2.y is float # true

# https://github.com/nim-lang/Nim/issues/2018
type ProtocolFollower = concept
  true # not a particularly involved protocol

type ImplementorA = object
type ImplementorB = object

proc p[A: ProtocolFollower, B: ProtocolFollower](a: A, b: B) =
  echo "p has been called."

p(ImplementorA(), ImplementorA())
p(ImplementorA(), ImplementorB())

# https://github.com/nim-lang/Nim/issues/2423
proc put*[T](c: seq[T], x: T) = echo "generic"
proc put*(c: seq) = echo "implicit generic"

type
  Container[T] = concept c
    put(c)
    put(c, T)

proc c1(x: Container) = echo "implicit generic"
c1(@[1])

proc c2[T](x: Container[T]) = echo "generic"
c2(@[1])

# https://github.com/nim-lang/Nim/issues/2882
type
  Paper = object
    name: string

  Bendable = concept x
    bend(x is Bendable)

proc bend(p: Paper): Paper = Paper(name: "bent-" & p.name)

var paper = Paper(name: "red")
echo paper is Bendable

type
  A = concept self
    size(self) is int

  B = object

proc size(self: B): int =
  return -1

proc size(self: A): int =
  return 0

let b = B()
echo b is A
echo b.size()

# https://github.com/nim-lang/Nim/issues/7125
type
  Thing = concept x
    x.hello is string
  Cat = object

proc hello(d: Cat): string = "Meow"

proc sayHello(c: Thing) = echo(c.hello)

var a: Thing = Cat()
a.sayHello()
