# bug #8416: inference of a static generic param through a type whose
# implementation depends on it
type Union[X: static[int]] = object
  when X == 0:
    discard
  else:
    discard

func f[X: static[int]](v: Union[X]): int = X

let k = Union[0]()
doAssert f(k) == 0
doAssert f[0](k) == 0
doAssert f(Union[3]()) == 3
