import std/private/since

when sizeof(int) <= 2:
  type IntLikeForCount = int|int8|int16|char|bool|uint8|enum
else:
  type IntLikeForCount = int|int8|int16|int32|char|bool|uint8|uint16|enum

iterator countdown*[T](a, b: T, step: Positive = 1): T {.inline.} =
  ## Counts from ordinal value `a` down to `b` (inclusive) with the given
  ## step count.
  ##
  ## `T` may be any ordinal type, `step` may only be positive.
  ##
  ## **Note**: This fails to count to ``low(int)`` if T = int for
  ## efficiency reasons.
  ##
  ## .. code-block:: Nim
  ##   for i in countdown(7, 3):
  ##     echo i # => 7; 6; 5; 4; 3
  ##
  ##   for i in countdown(9, 2, 3):
  ##     echo i # => 9; 6; 3
  when T is (uint|uint64):
    var res = a
    while res >= b:
      yield res
      if res == b: break
      dec(res, step)
  elif T is IntLikeForCount and T is Ordinal:
    var res = int(a)
    while res >= int(b):
      yield T(res)
      dec(res, step)
  else:
    var res = a
    while res >= b:
      yield res
      dec(res, step)

when defined(nimNewRoof):
  iterator countup*[T](a, b: T, step: Positive = 1): T {.inline.} =
    ## Counts from ordinal value `a` to `b` (inclusive) with the given
    ## step count.
    ##
    ## `T` may be any ordinal type, `step` may only be positive.
    ##
    ## **Note**: This fails to count to ``high(int)`` if T = int for
    ## efficiency reasons.
    ##
    ## .. code-block:: Nim
    ##   for i in countup(3, 7):
    ##     echo i # => 3; 4; 5; 6; 7
    ##
    ##   for i in countup(2, 9, 3):
    ##     echo i # => 2; 5; 8
    mixin inc
    when T is IntLikeForCount and T is Ordinal:
      var res = int(a)
      while res <= int(b):
        yield T(res)
        inc(res, step)
    else:
      var res = a
      while res <= b:
        yield res
        inc(res, step)

  iterator `..`*[T](a, b: T): T {.inline.} =
    ## An alias for `countup(a, b, 1)`.
    ##
    ## See also:
    ## * [..<](#..<.i,T,T)
    ##
    ## .. code-block:: Nim
    ##   for i in 3 .. 7:
    ##     echo i # => 3; 4; 5; 6; 7
    mixin inc
    when T is IntLikeForCount and T is Ordinal:
      var res = int(a)
      while res <= int(b):
        yield T(res)
        inc(res)
    else:
      var res = a
      while res <= b:
        yield res
        inc(res)

  template dotdotImpl(t) {.dirty.} =
    iterator `..`*(a, b: t): t {.inline.} =
      ## A type specialized version of ``..`` for convenience so that
      ## mixing integer types works better.
      ##
      ## See also:
      ## * [..<](#..<.i,T,T)
      var res = a
      while res <= b:
        yield res
        inc(res)

  dotdotImpl(int64)
  dotdotImpl(int32)
  dotdotImpl(uint64)
  dotdotImpl(uint32)

  iterator `..<`*[T](a, b: T): T {.inline.} =
    mixin inc
    var i = a
    while i < b:
      yield i
      inc i

  template dotdotLessImpl(t) {.dirty.} =
    iterator `..<`*(a, b: t): t {.inline.} =
      ## A type specialized version of ``..<`` for convenience so that
      ## mixing integer types works better.
      var res = a
      while res < b:
        yield res
        inc(res)

  dotdotLessImpl(int64)
  dotdotLessImpl(int32)
  dotdotLessImpl(uint64)
  dotdotLessImpl(uint32)

else: # not defined(nimNewRoof)
  iterator countup*[S, T](a: S, b: T, step = 1): T {.inline.} =
    ## Counts from ordinal value `a` up to `b` (inclusive) with the given
    ## step count.
    ##
    ## `S`, `T` may be any ordinal type, `step` may only be positive.
    ##
    ## **Note**: This fails to count to ``high(int)`` if T = int for
    ## efficiency reasons.
    ##
    ## .. code-block:: Nim
    ##   for i in countup(3, 7):
    ##     echo i # => 3; 4; 5; 6; 7
    ##
    ##   for i in countup(2, 9, 3):
    ##     echo i # => 2; 5; 8
    when T is IntLikeForCount and T is Ordinal:
      var res = int(a)
      while res <= int(b):
        yield T(res)
        inc(res, step)
    else:
      var res = T(a)
      while res <= b:
        yield res
        inc(res, step)

  iterator `..`*[S, T](a: S, b: T): T {.inline.} =
    ## An alias for `countup(a, b, 1)`.
    ##
    ## See also:
    ## * [..<](#..<.i,T,T)
    ##
    ## .. code-block:: Nim
    ##   for i in 3 .. 7:
    ##     echo i # => 3; 4; 5; 6; 7
    mixin inc
    when T is IntLikeForCount and T is Ordinal:
      var res = int(a)
      while res <= int(b):
        yield T(res)
        inc(res)
    else:
      var res = T(a)
      while res <= b:
        yield res
        inc(res)

  iterator `..<`*[S, T](a: S, b: T): T {.inline.} =
    mixin inc
    var i = T(a)
    while i < b:
      yield i
      inc i


iterator `||`*[S, T](a: S, b: T, annotation: static string = "omp parallel for"): T {.
  inline, magic: "OmpParFor", sideEffect.} =
  ## OpenMP parallel loop iterator. Same as `..` but the loop may run in parallel.
  ##
  ## `annotation` is an additional annotation for the code generator to use.
  ## The default annotation is `parallel for`.
  ## Please refer to the `OpenMP Syntax Reference
  ## <https://www.openmp.org/wp-content/uploads/OpenMP-4.5-1115-CPP-web.pdf>`_
  ## for further information.
  ##
  ## Note that the compiler maps that to
  ## the ``#pragma omp parallel for`` construct of `OpenMP`:idx: and as
  ## such isn't aware of the parallelism in your code! Be careful! Later
  ## versions of ``||`` will get proper support by Nim's code generator
  ## and GC.
  discard

iterator `||`*[S, T](a: S, b: T, step: Positive, annotation: static string = "omp parallel for"): T {.
  inline, magic: "OmpParFor", sideEffect.} =
  ## OpenMP parallel loop iterator with stepping.
  ## Same as `countup` but the loop may run in parallel.
  ##
  ## `annotation` is an additional annotation for the code generator to use.
  ## The default annotation is `parallel for`.
  ## Please refer to the `OpenMP Syntax Reference
  ## <https://www.openmp.org/wp-content/uploads/OpenMP-4.5-1115-CPP-web.pdf>`_
  ## for further information.
  ##
  ## Note that the compiler maps that to
  ## the ``#pragma omp parallel for`` construct of `OpenMP`:idx: and as
  ## such isn't aware of the parallelism in your code! Be careful! Later
  ## versions of ``||`` will get proper support by Nim's code generator
  ## and GC.
  discard


since (1, 3):
  template staticFor*(a, b: SomeInteger; unroll: static Positive): untyped =
    ## Compile-time unrolled for loop iterator.
    ##
    ## * If `unroll = 1`, unrolling is disabled (ignored).
    ## * If `unroll` is > `1`, unrolling is enabled.
    ## * If `unroll` is bigger than the total loop iterations,
    ##   no error is produced and the loop is completely unrolled.
    ##
    ## Example:
    ##
    ## .. code-block:: Nim
    ##   for i in staticFor(0, 99, 99): discard
    ##
    ## Compiles to approximately:
    ##
    ## .. code-block:: c
    ##   #pragma unroll 99
    ##   for (i = 0; i <= 99; ++i) {  };
    ##
    ## Nim emits `#pragma unroll` delegating the for loop unrolling to C, see also:
    ## * https://en.wikipedia.org/wiki/Loop_unrolling
    ## * http://gcc.gnu.org/onlinedocs/gcc/Loop-Specific-Pragmas.html#index-pragma-GCC-unroll-n
    ## * http://clang.llvm.org/docs/AttributeReference.html#pragma-unroll-pragma-nounroll
    ## * Only GCC and Clang are supported, otherwise a normal `..` iterator is used.
    runnableExamples:
      for i in staticFor(-9, 9, 5): echo i ## Check the generated C or Assembly.
    when defined(gcc) and not defined(js):   system.`||`(a, b, "GCC unroll " & $unroll)
    elif defined(clang) and not defined(js): system.`||`(a, b, "unroll " & $unroll)
    else:                                    system.`..`(a, b) # MSVC wont have pragma.
