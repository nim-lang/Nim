template fun2*(a: bool, body: untyped): untyped = discard
template fun2*(a: int, body: untyped): untyped = discard
template fun2*(body: untyped): untyped = discard

import random

type RandomVar*[A] = concept x
  var rng: Rand
  rng.sample(x) is A

proc abs*(x: RandomVar[float]): float = 123.456
