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
  ## **Note**: This fails to count to `low(int)` if T = int for
  ## efficiency reasons.
  runnableExamples:
    import sugar
    let x = collect(newSeq):
      for i in countdown(7, 3):
        i
    
    assert x == @[7, 6, 5, 4, 3]

    let y = collect(newseq):
      for i in countdown(9, 2, 3):
        i
    assert y == @[9, 6, 3]
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

iterator countup*[T](a, b: T, step: Positive = 1): T {.inline.} =
  ## Counts from ordinal value `a` to `b` (inclusive) with the given
  ## step count.
  ##
  ## `T` may be any ordinal type, `step` may only be positive.
  ##
  ## **Note**: This fails to count to `high(int)` if T = int for
  ## efficiency reasons.
  runnableExamples:
    import sugar
    let x = collect(newSeq):
      for i in countup(3, 7):
        i
    
    assert x == @[3, 4, 5, 6, 7]

    let y = collect(newseq):
      for i in countup(2, 9, 3):
        i
    assert y == @[2, 5, 8]
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
  runnableExamples:
    import sugar

    let x = collect(newSeq):
      for i in 3 .. 7:
        i

    assert x == @[3, 4, 5, 6, 7]
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
    ## A type specialized version of `..` for convenience so that
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
    ## A type specialized version of `..<` for convenience so that
    ## mixing integer types works better.
    var res = a
    while res < b:
      yield res
      inc(res)

dotdotLessImpl(int64)
dotdotLessImpl(int32)
dotdotLessImpl(uint64)
dotdotLessImpl(uint32)

iterator `||`*[S, T](a: S, b: T, annotation: static string = "parallel for"): T {.
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
  ## the `#pragma omp parallel for` construct of `OpenMP`:idx: and as
  ## such isn't aware of the parallelism in your code! Be careful! Later
  ## versions of `||` will get proper support by Nim's code generator
  ## and GC.
  discard

iterator `||`*[S, T](a: S, b: T, step: Positive, annotation: static string = "parallel for"): T {.
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
  ## the `#pragma omp parallel for` construct of `OpenMP`:idx: and as
  ## such isn't aware of the parallelism in your code! Be careful! Later
  ## versions of `||` will get proper support by Nim's code generator
  ## and GC.
  discard

iterator unroll*[S, T](a: S, b: T, annotation: static string): T {.
  inline, magic: "OmpParFor", sideEffect.} =
  discard

template unroll*(a, b: SomeInteger; num: static Natural): untyped =
  ## Compile-time unrolled for loop iterator.
  ##
  ## * If `num` is 0 or 1, unrolling is disabled (ignored).
  ## * If `num` is more than `1`, unrolling is enabled.
  ## * If `num` is bigger than the total loop iterations,
  ##   no error is produced and the loop is completely unrolled.
  ##
  ## Example:
  ##
  ## .. code-block:: Nim
  ##   for i in unroll(0, 99, 99): discard
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
  ## * https://software.intel.com/content/www/us/en/develop/documentation/cpp-compiler-developer-guide-and-reference/top/compiler-reference/pragmas/intel-specific-pragma-reference/unroll-nounroll.html
  ## * Only GCC, ICC and Clang are supported, otherwise a normal `..` iterator is used.
  runnableExamples:
    if false:
      for i in unroll(-9, 9, 5):
        echo i ## Check the generated C or Assembly.

  when defined(gcc):
    unroll(a, b, "GCC unroll " & $num)
  elif defined(clang) or defined(icc):
    unroll(a, b, "unroll " & $num)
  else:
    system.`..`(a, b)
