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
    import std/sugar
    let x = collect(newSeq):
      for i in countdown(7, 3):
        i
    
    assert x == @[7, 6, 5, 4, 3]

    let y = collect(newseq):
      for i in countdown(9, 2, 3):
        i
    assert y == @[9, 6, 3]
  var res = a
  if res >= b:
    yield res
    let endrange = succ(b, step)
    while res >= endrange:
      dec(res, step)
      yield res

iterator countup*[T](a, b: T, step: Positive = 1): T {.inline.} =
  ## Counts from ordinal value `a` to `b` (inclusive) with the given
  ## step count.
  ##
  ## `T` may be any ordinal type, `step` may only be positive.
  ##
  ## **Note**: This fails to count to `high(int)` if T = int for
  ## efficiency reasons.
  runnableExamples:
    import std/sugar
    let x = collect(newSeq):
      for i in countup(3, 7):
        i
    
    assert x == @[3, 4, 5, 6, 7]

    let y = collect(newseq):
      for i in countup(2, 9, 3):
        i
    assert y == @[2, 5, 8]
  mixin inc
  var res = a
  if res <= b:
    yield res
    let endrange = pred(b, step)
    while res <= endrange:
      inc(res, step)
      yield res

iterator `..`*[T](a, b: T): T {.inline.} =
  ## An alias for `countup(a, b, 1)`.
  ##
  ## See also:
  ## * [..<](#..<.i,T,T)
  runnableExamples:
    import std/sugar

    let x = collect(newSeq):
      for i in 3 .. 7:
        i

    assert x == @[3, 4, 5, 6, 7]
  mixin inc
  var res = a
  if res <= b:
    yield res
    let endrange = pred(b)
    while res <= endrange:
      inc(res)
      yield res

template dotdotImpl(t) {.dirty.} =
  iterator `..`*(a, b: t): t {.inline.} =
    ## A type specialized version of `..` for convenience so that
    ## mixing integer types works better.
    ##
    ## See also:
    ## * [..<](#..<.i,T,T)
    var res = a
    if res <= b:
      yield res
      let endrange = b.pred
      while res <= endrange:
        inc(res)
        yield res

dotdotImpl(int64)
dotdotImpl(int32)
dotdotImpl(uint64)
dotdotImpl(uint32)

iterator `..<`*[T](a, b: T): T {.inline.} =
  mixin inc
  var res = a
  if res < b:
    yield res
    let endrange = b.pred
    while res < endrange:
      inc(res)
      yield res

template dotdotLessImpl(t) {.dirty.} =
  iterator `..<`*(a, b: t): t {.inline.} =
    ## A type specialized version of `..<` for convenience so that
    ## mixing integer types works better.
    var res = a
    if res < b:
      yield res
      let endrange = b.pred
      while res < endrange:
        inc(res)
        yield res

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
