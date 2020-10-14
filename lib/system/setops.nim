proc incl*[T](x: var set[T], y: T) {.magic: "Incl", noSideEffect.}
  ## Includes element ``y`` in the set ``x``.
  ##
  ## This is the same as ``x = x + {y}``, but it might be more efficient.
  ##
  ## .. code-block:: Nim
  ##   var a = {1, 3, 5}
  ##   a.incl(2) # a <- {1, 2, 3, 5}
  ##   a.incl(4) # a <- {1, 2, 3, 4, 5}

template incl*[T](x: var set[T], y: set[T]) =
  ## Includes the set ``y`` in the set ``x``.
  ##
  ## .. code-block:: Nim
  ##   var a = {1, 3, 5, 7}
  ##   var b = {4, 5, 6}
  ##   a.incl(b)  # a <- {1, 3, 4, 5, 6, 7}
  x = x + y

proc excl*[T](x: var set[T], y: T) {.magic: "Excl", noSideEffect.}
  ## Excludes element ``y`` from the set ``x``.
  ##
  ## This is the same as ``x = x - {y}``, but it might be more efficient.
  ##
  ## .. code-block:: Nim
  ##   var b = {2, 3, 5, 6, 12, 545}
  ##   b.excl(5)  # b <- {2, 3, 6, 12, 545}

template excl*[T](x: var set[T], y: set[T]) =
  ## Excludes the set ``y`` from the set ``x``.
  ##
  ## .. code-block:: Nim
  ##   var a = {1, 3, 5, 7}
  ##   var b = {3, 4, 5}
  ##   a.excl(b)  # a <- {1, 7}
  x = x - y

proc card*[T](x: set[T]): int {.magic: "Card", noSideEffect.}
  ## Returns the cardinality of the set ``x``, i.e. the number of elements
  ## in the set.
  ##
  ## .. code-block:: Nim
  ##   var a = {1, 3, 5, 7}
  ##   echo card(a) # => 4

proc len*[T](x: set[T]): int {.magic: "Card", noSideEffect.}
  ## An alias for `card(x)`.


proc `*`*[T](x, y: set[T]): set[T] {.magic: "MulSet", noSideEffect.}
  ## This operator computes the intersection of two sets.
  ##
  ## .. code-block:: Nim
  ##   let
  ##     a = {1, 2, 3}
  ##     b = {2, 3, 4}
  ##   echo a * b # => {2, 3}
proc `+`*[T](x, y: set[T]): set[T] {.magic: "PlusSet", noSideEffect.}
  ## This operator computes the union of two sets.
  ##
  ## .. code-block:: Nim
  ##   let
  ##     a = {1, 2, 3}
  ##     b = {2, 3, 4}
  ##   echo a + b # => {1, 2, 3, 4}
proc `-`*[T](x, y: set[T]): set[T] {.magic: "MinusSet", noSideEffect.}
  ## This operator computes the difference of two sets.
  ##
  ## .. code-block:: Nim
  ##   let
  ##     a = {1, 2, 3}
  ##     b = {2, 3, 4}
  ##   echo a - b # => {1}

proc contains*[T](x: set[T], y: T): bool {.magic: "InSet", noSideEffect.}
  ## One should overload this proc if one wants to overload the ``in`` operator.
  ##
  ## The parameters are in reverse order! ``a in b`` is a template for
  ## ``contains(b, a)``.
  ## This is because the unification algorithm that Nim uses for overload
  ## resolution works from left to right.
  ## But for the ``in`` operator that would be the wrong direction for this
  ## piece of code:
  ##
  ## .. code-block:: Nim
  ##   var s: set[range['a'..'z']] = {'a'..'c'}
  ##   assert s.contains('c')
  ##   assert 'b' in s
  ##
  ## If ``in`` had been declared as ``[T](elem: T, s: set[T])`` then ``T`` would
  ## have been bound to ``char``. But ``s`` is not compatible to type
  ## ``set[char]``! The solution is to bind ``T`` to ``range['a'..'z']``. This
  ## is achieved by reversing the parameters for ``contains``; ``in`` then
  ## passes its arguments in reverse order.
