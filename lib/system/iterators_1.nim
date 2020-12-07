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

iterator countup*[S, T](a: S, b: T, step = 1): T {.inline.} =
  ## Counts from ordinal value `a` up to `b` (inclusive) with the given
  ## step count.
  ##
  ## `S`, `T` may be any ordinal type, `step` may only be positive.
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
  ## * [..<](#..<.i,S,T)
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
