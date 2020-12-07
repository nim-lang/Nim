func incl*[T](x: var set[T], y: T) {.magic: "Incl".} =
  ## Includes element `y` in the set `x`.
  ##
  ## This is the same as `x = x + {y}`, but it might be more efficient.
  runnableExamples:
    var a = {1, 3, 5}
    a.incl(2)
    assert a == {1, 2, 3, 5}
    a.incl(4)
    assert a == {1, 2, 3, 4, 5}

template incl*[T](x: var set[T], y: set[T]) =
  ## Includes the set `y` in the set `x`.
  runnableExamples:
    var a = {1, 3, 5, 7}
    var b = {4, 5, 6}
    a.incl(b)
    assert a == {1, 3, 4, 5, 6, 7}
  x = x + y

func excl*[T](x: var set[T], y: T) {.magic: "Excl".} =
  ## Excludes element `y` from the set `x`.
  ##
  ## This is the same as `x = x - {y}`, but it might be more efficient.
  runnableExamples:
    var b = {2, 3, 5, 6, 12, 545}
    b.excl(5)
    assert b == {2, 3, 6, 12, 545}

template excl*[T](x: var set[T], y: set[T]) =
  ## Excludes the set `y` from the set `x`.
  runnableExamples:
    var a = {1, 3, 5, 7}
    var b = {3, 4, 5}
    a.excl(b) 
    assert a == {1, 7}
  x = x - y

func card*[T](x: set[T]): int {.magic: "Card".} =
  ## Returns the cardinality of the set `x`, i.e. the number of elements
  ## in the set.
  runnableExamples:
    var a = {1, 3, 5, 7}
    assert card(a) == 4
    var b = {1, 3, 5, 7, 5}
    assert card(b) == 4 # repeated 5 doesn't count

func len*[T](x: set[T]): int {.magic: "Card".}
  ## An alias for `card(x)`.


func `*`*[T](x, y: set[T]): set[T] {.magic: "MulSet".} =
  ## This operator computes the intersection of two sets.
  runnableExamples:
    assert {1, 2, 3} * {2, 3, 4} == {2, 3}

func `+`*[T](x, y: set[T]): set[T] {.magic: "PlusSet".} =
  ## This operator computes the union of two sets.
  runnableExamples:
    assert {1, 2, 3} + {2, 3, 4} == {1, 2, 3, 4}

func `-`*[T](x, y: set[T]): set[T] {.magic: "MinusSet".} =
  ## This operator computes the difference of two sets.
  runnableExamples:
    assert {1, 2, 3} - {2, 3, 4} == {1}

func contains*[T](x: set[T], y: T): bool {.magic: "InSet".} =
  ## One should overload this proc if one wants to overload the `in` operator.
  ##
  ## The parameters are in reverse order! `a in b` is a template for
  ## `contains(b, a)`.
  ## This is because the unification algorithm that Nim uses for overload
  ## resolution works from left to right.
  ## But for the `in` operator that would be the wrong direction for this
  ## piece of code:
  runnableExamples:
    var s: set[range['a'..'z']] = {'a'..'c'}
    assert s.contains('c')
    assert 'b' in s
    assert 'd' notin s
    assert set['a'..'z'] is set[range['a'..'z']]
  ## If `in` had been declared as `[T](elem: T, s: set[T])` then `T` would
  ## have been bound to `char`. But `s` is not compatible to type
  ## `set[char]`! The solution is to bind `T` to `range['a'..'z']`. This
  ## is achieved by reversing the parameters for `contains`; `in` then
  ## passes its arguments in reverse order.
