#
#
#            Nimrod's Runtime Library
#        (c) Copyright 2011 Alex Mitchell
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## :Author: Alex Mitchell
##
## This module implements operations for the built-in `seq`:idx: type which
## were inspired by functional programming languages. If you are looking for
## the typical `map` function which applies a function to every element in a
## sequence, it already exists in the `system <system.html>`_ module in both
## mutable and immutable styles.
##
## Also, for functional style programming you may want to pass `anonymous procs
## <manual.html#anonymous-procs>`_ to procs like ``filter`` to reduce typing.
## Anonymous procs can use `the special do notation <manual.html#do-notation>`_
## which is more convenient in certain situations.
##
## **Note**: This interface will change as soon as the compiler supports
## closures and proper coroutines.

when not defined(nimhygiene):
  {.pragma: dirty.}

proc concat*[T](seqs: varargs[seq[T]]): seq[T] =
  ## Takes several sequences' items and returns them inside a new sequence.
  ##
  ## Example:
  ##
  ## .. code-block:: nimrod
  ##   let
  ##     s1 = @[1, 2, 3]
  ##     s2 = @[4, 5]
  ##     s3 = @[6, 7]
  ##     total = concat(s1, s2, s3)
  ##   assert total == @[1, 2, 3, 4, 5, 6, 7]
  var L = 0
  for seqitm in items(seqs): inc(L, len(seqitm))
  newSeq(result, L)
  var i = 0
  for s in items(seqs):
    for itm in items(s):
      result[i] = itm
      inc(i)

proc distnct*[T](seq1: seq[T]): seq[T] =
  ## Returns a new sequence without duplicates.
  ##
  ## This proc is `misspelled` on purpose to avoid a clash with the keyword
  ## ``distinct`` used to `define a derived type incompatible with its base
  ## type <manual.html#distinct-type>`_. Example:
  ##
  ## .. code-block:: nimrod
  ##   let
  ##     dup1 = @[1, 1, 3, 4, 2, 2, 8, 1, 4]
  ##     dup2 = @["a", "a", "c", "d", "d"]
  ##     unique1 = distnct(dup1)
  ##     unique2 = distnct(dup2)
  ##   assert unique1 == @[1, 3, 4, 2, 8]
  ##   assert unique2 == @["a", "c", "d"]
  result = @[]
  for itm in items(seq1):
    if not result.contains(itm): result.add(itm)
    
proc zip*[S, T](seq1: seq[S], seq2: seq[T]): seq[tuple[a: S, b: T]] =
  ## Returns a new sequence with a combination of the two input sequences.
  ##
  ## For convenience you can access the returned tuples through the named
  ## fields `a` and `b`. If one sequence is shorter, the remaining items in the
  ## longer sequence are discarded. Example:
  ##
  ## .. code-block:: nimrod
  ##   let
  ##     short = @[1, 2, 3]
  ##     long = @[6, 5, 4, 3, 2, 1]
  ##     words = @["one", "two", "three"]
  ##     zip1 = zip(short, long)
  ##     zip2 = zip(short, words)
  ##   assert zip1 == @[(1, 6), (2, 5), (3, 4)]
  ##   assert zip2 == @[(1, "one"), (2, "two"), (3, "three")]
  ##   assert zip1[2].b == 4
  ##   assert zip2[2].b == "three"
  var m = min(seq1.len, seq2.len)
  newSeq(result, m)
  for i in 0 .. m-1: result[i] = (seq1[i], seq2[i])

iterator filter*[T](seq1: seq[T], pred: proc(item: T): bool {.closure.}): T =
  ## Iterates through a sequence and yields every item that fulfills the
  ## predicate.
  ##
  ## Example:
  ##
  ## .. code-block:: nimrod
  ##   let numbers = @[1, 4, 5, 8, 9, 7, 4]
  ##   for n in filter(numbers, proc (x: int): bool = x mod 2 == 0):
  ##     echo($n)
  ##   # echoes 4, 8, 4 in separate lines
  for i in countup(0, len(seq1) -1):
    var item = seq1[i]
    if pred(item): yield seq1[i]

proc filter*[T](seq1: seq[T], pred: proc(item: T): bool {.closure.}): seq[T] =
  ## Returns a new sequence with all the items that fulfilled the predicate.
  ##
  ## Example:
  ##
  ## .. code-block:: nimrod
  ##   let
  ##     colors = @["red", "yellow", "black"]
  ##     f1 = filter(colors, proc(x: string): bool = x.len < 6)
  ##     f2 = filter(colors) do (x: string) -> bool : x.len > 5
  ##   assert f1 == @["red", "black"]
  ##   assert f2 == @["yellow"]
  accumulateResult(filter(seq1, pred))

proc delete*[T](s: var seq[T], first=0, last=0) =
  ## Deletes in `s` the items at position `first` .. `last`. This modifies
  ## `s` itself, it does not return a copy.
  ##
  ## Example:
  ##
  ##.. code-block:: nimrod
  ##   let outcome = @[1,1,1,1,1,1,1,1]
  ##   var dest = @[1,1,1,2,2,2,2,2,2,1,1,1,1,1]
  ##   dest.delete(3, 8)
  ##   assert outcome == dest
  
  var i = first
  var j = last+1
  var newLen = len(s)-j+i
  while i < newLen:
    s[i].shallowCopy(s[j])
    inc(i)
    inc(j)
  setLen(s, newLen)

proc insert*[T](dest: var seq[T], src: openArray[T], pos=0) =
  ## Inserts items from `src` into `dest` at position `pos`. This modifies
  ## `dest` itself, it does not return a copy.
  ##
  ## Example:
  ##
  ##.. code-block:: nimrod
  ##   var dest = @[1,1,1,1,1,1,1,1]
  ##   let 
  ##     src = @[2,2,2,2,2,2]
  ##     outcome = @[1,1,1,2,2,2,2,2,2,1,1,1,1,1]
  ##   dest.insert(src, 3)
  ##   assert dest == outcome
  
  var j = len(dest) - 1
  var i = len(dest) + len(src) - 1
  dest.setLen(i + 1)

  # Move items after `pos` to the end of the sequence.
  while j >= pos:
    dest[i].shallowCopy(dest[j])
    dec(i)
    dec(j)
  # Insert items from `dest` into `dest` at `pos`
  inc(j)
  for item in src:
    dest[j] = item
    inc(j)


template filterIt*(seq1, pred: expr): expr {.immediate.} =
  ## Returns a new sequence with all the items that fulfilled the predicate.
  ##
  ## Unlike the `proc` version, the predicate needs to be an expression using
  ## the ``it`` variable for testing, like: ``filterIt("abcxyz", it == 'x')``.
  ## Example:
  ##
  ## .. code-block:: nimrod
  ##    let
  ##      temperatures = @[-272.15, -2.0, 24.5, 44.31, 99.9, -113.44]
  ##      acceptable = filterIt(temperatures, it < 50 and it > -10)
  ##      notAcceptable = filterIt(temperatures, it > 50 or it < -10)
  ##    assert acceptable == @[-2.0, 24.5, 44.31]
  ##    assert notAcceptable == @[-272.15, 99.9, -113.44]
  var result {.gensym.}: type(seq1) = @[]
  for it {.inject.} in items(seq1):
    if pred: result.add(it)
  result

template toSeq*(iter: expr): expr {.immediate.} =
  ## Transforms any iterator into a sequence.
  ##
  ## Example:
  ##
  ## .. code-block:: nimrod
  ##   let
  ##     numeric = @[1, 2, 3, 4, 5, 6, 7, 8, 9]
  ##     odd_numbers = toSeq(filter(numeric) do (x: int) -> bool:
  ##       if x mod 2 == 1:
  ##         result = true)
  ##   assert odd_numbers == @[1, 3, 5, 7, 9]
  ##
  var result {.gensym.}: seq[type(iter)] = @[]
  for x in iter: add(result, x)
  result

template foldl*(sequence, operation: expr): expr =
  ## Template to fold a sequence from left to right, returning the accumulation.
  ##
  ## The sequence is required to have at least a single element. Debug versions
  ## of your program will assert in this situation but release versions will
  ## happily go ahead. If the sequence has a single element it will be returned
  ## without applying ``operation``.
  ##
  ## The ``operation`` parameter should be an expression which uses the
  ## variables ``a`` and ``b`` for each step of the fold. Since this is a left
  ## fold, for non associative binary operations like substraction think that
  ## the sequence of numbers 1, 2 and 3 will be parenthesized as (((1) - 2) -
  ## 3).  Example:
  ##
  ## .. code-block:: nimrod
  ##   let
  ##     numbers = @[5, 9, 11]
  ##     addition = foldl(numbers, a + b)
  ##     substraction = foldl(numbers, a - b)
  ##     multiplication = foldl(numbers, a * b)
  ##     words = @["nim", "rod", "is", "cool"]
  ##     concatenation = foldl(words, a & b)
  ##   assert addition == 25, "Addition is (((5)+9)+11)"
  ##   assert substraction == -15, "Substraction is (((5)-9)-11)"
  ##   assert multiplication == 495, "Multiplication is (((5)*9)*11)"
  ##   assert concatenation == "nimrodiscool"
  assert sequence.len > 0, "Can't fold empty sequences"
  var result {.gensym.}: type(sequence[0])
  result = sequence[0]
  for i in countup(1, sequence.len - 1):
    let
      a {.inject.} = result
      b {.inject.} = sequence[i]
    result = operation
  result

template foldr*(sequence, operation: expr): expr =
  ## Template to fold a sequence from right to left, returning the accumulation.
  ##
  ## The sequence is required to have at least a single element. Debug versions
  ## of your program will assert in this situation but release versions will
  ## happily go ahead. If the sequence has a single element it will be returned
  ## without applying ``operation``.
  ##
  ## The ``operation`` parameter should be an expression which uses the
  ## variables ``a`` and ``b`` for each step of the fold. Since this is a right
  ## fold, for non associative binary operations like substraction think that
  ## the sequence of numbers 1, 2 and 3 will be parenthesized as (1 - (2 -
  ## (3))). Example:
  ##
  ## .. code-block:: nimrod
  ##   let
  ##     numbers = @[5, 9, 11]
  ##     addition = foldr(numbers, a + b)
  ##     substraction = foldr(numbers, a - b)
  ##     multiplication = foldr(numbers, a * b)
  ##     words = @["nim", "rod", "is", "cool"]
  ##     concatenation = foldr(words, a & b)
  ##   assert addition == 25, "Addition is (5+(9+(11)))"
  ##   assert substraction == 7, "Substraction is (5-(9-(11)))"
  ##   assert multiplication == 495, "Multiplication is (5*(9*(11)))"
  ##   assert concatenation == "nimrodiscool"
  assert sequence.len > 0, "Can't fold empty sequences"
  var result {.gensym.}: type(sequence[0])
  result = sequence[sequence.len - 1]
  for i in countdown(sequence.len - 2, 0):
    let
      a {.inject.} = sequence[i]
      b {.inject.} = result
    result = operation
  result

when isMainModule:
  import strutils
  block: # concat test
    let
      s1 = @[1, 2, 3]
      s2 = @[4, 5]
      s3 = @[6, 7]
      total = concat(s1, s2, s3)
    assert total == @[1, 2, 3, 4, 5, 6, 7]

  block: # duplicates test
    let
      dup1 = @[1, 1, 3, 4, 2, 2, 8, 1, 4]
      dup2 = @["a", "a", "c", "d", "d"]
      unique1 = distnct(dup1)
      unique2 = distnct(dup2)
    assert unique1 == @[1, 3, 4, 2, 8]
    assert unique2 == @["a", "c", "d"]

  block: # zip test
    let
      short = @[1, 2, 3]
      long = @[6, 5, 4, 3, 2, 1]
      words = @["one", "two", "three"]
      zip1 = zip(short, long)
      zip2 = zip(short, words)
    assert zip1 == @[(1, 6), (2, 5), (3, 4)]
    assert zip2 == @[(1, "one"), (2, "two"), (3, "three")]
    assert zip1[2].b == 4
    assert zip2[2].b == "three"

  block: # filter proc test
    let
      colors = @["red", "yellow", "black"]
      f1 = filter(colors, proc(x: string): bool = x.len < 6)
      f2 = filter(colors) do (x: string) -> bool : x.len > 5
    assert f1 == @["red", "black"]
    assert f2 == @["yellow"]

  block: # filter iterator test
    let numbers = @[1, 4, 5, 8, 9, 7, 4]
    for n in filter(numbers, proc (x: int): bool = x mod 2 == 0):
      echo($n)
    # echoes 4, 8, 4 in separate lines

  block: # filterIt test
    let
      temperatures = @[-272.15, -2.0, 24.5, 44.31, 99.9, -113.44]
      acceptable = filterIt(temperatures, it < 50 and it > -10)
      notAcceptable = filterIt(temperatures, it > 50 or it < -10)
    assert acceptable == @[-2.0, 24.5, 44.31]
    assert notAcceptable == @[-272.15, 99.9, -113.44]

  block: # toSeq test
    let
      numeric = @[1, 2, 3, 4, 5, 6, 7, 8, 9]
      odd_numbers = toSeq(filter(numeric) do (x: int) -> bool:
        if x mod 2 == 1:
          result = true)
    assert odd_numbers == @[1, 3, 5, 7, 9]

  block: # foldl tests
    let
      numbers = @[5, 9, 11]
      addition = foldl(numbers, a + b)
      substraction = foldl(numbers, a - b)
      multiplication = foldl(numbers, a * b)
      words = @["nim", "rod", "is", "cool"]
      concatenation = foldl(words, a & b)
    assert addition == 25, "Addition is (((5)+9)+11)"
    assert substraction == -15, "Substraction is (((5)-9)-11)"
    assert multiplication == 495, "Multiplication is (((5)*9)*11)"
    assert concatenation == "nimrodiscool"

  block: # foldr tests
    let
      numbers = @[5, 9, 11]
      addition = foldr(numbers, a + b)
      substraction = foldr(numbers, a - b)
      multiplication = foldr(numbers, a * b)
      words = @["nim", "rod", "is", "cool"]
      concatenation = foldr(words, a & b)
    assert addition == 25, "Addition is (5+(9+(11)))"
    assert substraction == 7, "Substraction is (5-(9-(11)))"
    assert multiplication == 495, "Multiplication is (5*(9*(11)))"
    assert concatenation == "nimrodiscool"

  block: # delete tests
    let outcome = @[1,1,1,1,1,1,1,1]
    var dest = @[1,1,1,2,2,2,2,2,2,1,1,1,1,1]
    dest.delete(3, 8)
    assert outcome == dest, """\
    Deleting range 3-9 from [1,1,1,2,2,2,2,2,2,1,1,1,1,1] 
    is [1,1,1,1,1,1,1,1]"""

  block: # insert tests
    var dest = @[1,1,1,1,1,1,1,1]
    let 
      src = @[2,2,2,2,2,2]
      outcome = @[1,1,1,2,2,2,2,2,2,1,1,1,1,1]
    dest.insert(src, 3)
    assert dest == outcome, """\
    Inserting [2,2,2,2,2,2] into [1,1,1,1,1,1,1,1]
    at 3 is [1,1,1,2,2,2,2,2,2,1,1,1,1,1]"""

  echo "Finished doc tests"
