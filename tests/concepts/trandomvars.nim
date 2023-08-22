discard """
output: '''
true
true
true
3
18.0
324.0
'''
"""

type RNG = object

proc random(rng: var RNG): float = 1.0

type
  RandomVar[A] = concept x
    var rng: RNG
    rng.sample(x) is A

  Constant[A] = object
    value: A

  Uniform = object
    a, b: float

  ClosureVar[A] = proc(rng: var RNG): A

proc sample[A](rng: var RNG, c: Constant[A]): A = c.value

proc sample(rng: var RNG, u: Uniform): float = u.a + (u.b - u.a) * rng.random()

proc sample[A](rng: var RNG, c: ClosureVar[A]): A = c(rng)

proc constant[A](a: A): Constant[A] = Constant[A](value: a)

proc uniform(a, b: float): Uniform = Uniform(a: a, b: b)

proc lift1[A, B](f: proc(a: A): B, r: RandomVar[A]): ClosureVar[B] =
  proc inner(rng: var RNG): B = f(rng.sample(r))

  return inner


proc main() =
  proc sq(x: float): float = x * x

  let
    c = constant(3)
    u = uniform(2, 18)
    t = lift1(sq, u)

  var rng: RNG

  echo(c is RandomVar[int])
  echo(u is RandomVar[float])
  echo(t is RandomVar[float])

  echo rng.sample(c)
  echo rng.sample(u)
  echo rng.sample(t)

main()
