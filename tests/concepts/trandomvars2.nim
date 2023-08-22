discard """
output: "11.0"
"""

type
  # A random number generator
  Random = object
    random: proc(): float
  # A generic typeclass for a random var
  RandomVar[A] = concept x
    var rng: Random
    rng.sample(x) is A
  # A few concrete instances
  Uniform = object
    a, b: float
  ClosureVar[A] = object
    f: proc(rng: var Random): A

# How to sample from various concrete instances
proc sample(rng: var Random, u: Uniform): float = u.a + (u.b - u.a) * rng.random()

proc sample[A](rng: var Random, c: ClosureVar[A]): A = c.f(rng)

proc uniform(a, b: float): Uniform = Uniform(a: a, b: b)

# How to lift a function on values to a function on random variables
proc map[A, B](x: RandomVar[A], f: proc(a: A): B): ClosureVar[B] =
  proc inner(rng: var Random): B =
    f(rng.sample(x))

  result.f = inner

import sugar

proc fakeRandom(): Random =
  result.random = () => 0.5

let x = uniform(1, 10).map((x: float) => 2 * x)

var rng = fakeRandom()

echo rng.sample(x)
