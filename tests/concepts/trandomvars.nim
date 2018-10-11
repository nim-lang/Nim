discard """
  file: "trandomvars.nim"
  output: '''
true
true
true
3
18.0
324.0
11.0
'''
"""


import sugar


block one:
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

  when isMainModule:
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



block two:
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
  
  
  proc fakeRandom(): Random =
    result.random = () => 0.5
  
  let x = uniform(1, 10).map((x: float) => 2 * x)
  
  var rng = fakeRandom()
  
  echo rng.sample(x)
  