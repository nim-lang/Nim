#
#
#            Nim's Runtime Library
#        (c) Copyright 2011 Alexander Mitchell-Robinson
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## Although this module has ``seq`` in its name, it implements operations
## not only for `seq`:idx: type, but for three built-in container types under
## the ``openArray`` umbrella:
## * sequences
## * strings
## * array
##
## The system module defines several common functions, such as:
## * ``newSeq[T]`` for creating new sequences of type ``T``
## * ``@`` for converting arrays and strings to sequences
## * ``add`` for adding new elements to strings and sequences
## * ``&`` for string and seq concatenation
## * ``in`` (alias for ``contains``) and ``notin`` for checking if an item is
##   in a container
##
## This module builds upon that, providing additional functionality in form of
## procs, iterators and templates inspired by functional programming
## languages.
##
## For functional style programming you have different options at your disposal:
## * pass `anonymous proc<manual.html#procedures-anonymous-procs>`_
## * import `sugar module<sugar.html>`_  and use
##   `=> macro<sugar.html#%3D>.m,untyped,untyped>`_
## * use `...It templates<#18>`_
##   (`mapIt<#mapIt.t,typed,untyped>`_,
##   `filterIt<#filterIt.t,untyped,untyped>`_, etc.)
##
## The chaining of functions is possible thanks to the
## `method call syntax<manual.html#procs-method-call-syntax>`_.
##
## .. code-block::
##   import sequtils, sugar
##
##   # Creating a sequence from 1 to 10, multiplying each member by 2,
##   # keeping only the members which are not divisible by 6.
##   let
##     foo = toSeq(1..10).map(x => x*2).filter(x => x mod 6 != 0)
##     bar = toSeq(1..10).mapIt(it*2).filterIt(it mod 6 != 0)
##
##   doAssert foo == bar
##   echo foo                  # @[2, 4, 8, 10, 14, 16, 20]
##
##   echo foo.any(x => x > 17) # true
##   echo bar.allIt(it < 20)   # false
##   echo foo.foldl(a + b)     # 74; sum of all members
##
## .. code-block::
##   import sequtils
##   from strutils import join
##
##   let
##     vowels = @"aeiou" # creates a sequence @['a', 'e', 'i', 'o', 'u']
##     foo = "sequtils is an awesome module"
##
##   echo foo.filterIt(it notin vowels).join # "sqtls s n wsm mdl"
##
## ----
##
## **See also**:
## * `strutils module<strutils.html>`_ for common string functions
## * `sugar module<sugar.html>`_ for syntactic sugar macros
## * `algorithm module<algorithm.html>`_ for common generic algorithms
## * `json module<json.html>`_ for a structure which allows
##   heterogeneous members


include "system/inclrtl"

import macros

when not defined(nimhygiene):
  {.pragma: dirty.}


macro evalOnceAs(expAlias, exp: untyped, letAssigneable: static[bool]): untyped =
  ## Injects ``expAlias`` in caller scope, to avoid bugs involving multiple
  ##  substitution in macro arguments such as
  ## https://github.com/nim-lang/Nim/issues/7187
  ## ``evalOnceAs(myAlias, myExp)`` will behave as ``let myAlias = myExp``
  ## except when ``letAssigneable`` is false (e.g. to handle openArray) where
  ## it just forwards ``exp`` unchanged
  expectKind(expAlias, nnkIdent)
  var val = exp

  result = newStmtList()
  # If `exp` is not a symbol we evaluate it once here and then use the temporary
  # symbol as alias
  if exp.kind != nnkSym and letAssigneable:
    val = genSym()
    result.add(newLetStmt(val, exp))

  result.add(
    newProc(name = genSym(nskTemplate, $expAlias), params = [getType(untyped)],
      body = val, procType = nnkTemplateDef))

proc concat*[T](seqs: varargs[seq[T]]): seq[T] =
  ## Takes several sequences' items and returns them inside a new sequence.
  ## All sequences must be of the same type.
  ##
  ## See also:
  ## * `distribute proc<#distribute,seq[T],Positive>`_ for a reverse
  ##   operation
  ##
  runnableExamples:
    let
      s1 = @[1, 2, 3]
      s2 = @[4, 5]
      s3 = @[6, 7]
      total = concat(s1, s2, s3)
    assert total == @[1, 2, 3, 4, 5, 6, 7]

  var L = 0
  for seqitm in items(seqs): inc(L, len(seqitm))
  newSeq(result, L)
  var i = 0
  for s in items(seqs):
    for itm in items(s):
      result[i] = itm
      inc(i)

proc count*[T](s: openArray[T], x: T): int =
  ## Returns the number of occurrences of the item `x` in the container `s`.
  ##
  runnableExamples:
    let
      a = @[1, 2, 2, 3, 2, 4, 2]
      b = "abracadabra"
    assert count(a, 2) == 4
    assert count(a, 99) == 0
    assert count(b, 'r') == 2

  for itm in items(s):
    if itm == x:
      inc result

proc cycle*[T](s: openArray[T], n: Natural): seq[T] =
  ## Returns a new sequence with the items of the container `s` repeated
  ## `n` times.
  ## `n` must be a non-negative number (zero or more).
  ##
  runnableExamples:
    let
      s = @[1, 2, 3]
      total = s.cycle(3)
    assert total == @[1, 2, 3, 1, 2, 3, 1, 2, 3]

  result = newSeq[T](n * s.len)
  var o = 0
  for x in 0 ..< n:
    for e in s:
      result[o] = e
      inc o

proc repeat*[T](x: T, n: Natural): seq[T] =
  ## Returns a new sequence with the item `x` repeated `n` times.
  ## `n` must be a non-negative number (zero or more).
  ##
  runnableExamples:
    let
      total = repeat(5, 3)
    assert total == @[5, 5, 5]

  result = newSeq[T](n)
  for i in 0 ..< n:
    result[i] = x

proc deduplicate*[T](s: openArray[T], isSorted: bool = false): seq[T] =
  ## Returns a new sequence without duplicates.
  ##
  ## Setting the optional argument ``isSorted`` to ``true`` (default: false)
  ## uses a faster algorithm for deduplication.
  ##
  runnableExamples:
    let
      dup1 = @[1, 1, 3, 4, 2, 2, 8, 1, 4]
      dup2 = @["a", "a", "c", "d", "d"]
      unique1 = deduplicate(dup1)
      unique2 = deduplicate(dup2, isSorted = true)
    assert unique1 == @[1, 3, 4, 2, 8]
    assert unique2 == @["a", "c", "d"]

  result = @[]
  if s.len > 0:
    if isSorted:
      var prev = s[0]
      result.add(prev)
      for i in 1..s.high:
        if s[i] != prev:
          prev = s[i]
          result.add(prev)
    else:
      for itm in items(s):
        if not result.contains(itm): result.add(itm)

proc zip*[S, T](s1: openArray[S], s2: openArray[T]): seq[tuple[a: S, b: T]] =
  ## Returns a new sequence with a combination of the two input containers.
  ##
  ## The input containers can be of different types.
  ## If one container is shorter, the remaining items in the longer container
  ## are discarded.
  ##
  ## For convenience you can access the returned tuples through the named
  ## fields `a` and `b`.
  ##
  runnableExamples:
    let
      short = @[1, 2, 3]
      long = @[6, 5, 4, 3, 2, 1]
      words = @["one", "two", "three"]
      letters = "abcd"
      zip1 = zip(short, long)
      zip2 = zip(short, words)
      zip3 = zip(long, letters)
    assert zip1 == @[(1, 6), (2, 5), (3, 4)]
    assert zip2 == @[(1, "one"), (2, "two"), (3, "three")]
    assert zip3 == @[(a: 6, b: 'a'), (a: 5, b: 'b'), (a: 4, b: 'c'),
                     (a: 3, b: 'd')]
    assert zip1[2].b == 4
    assert zip2[2].b == "three"

  var m = min(s1.len, s2.len)
  newSeq(result, m)
  for i in 0 ..< m:
    result[i] = (s1[i], s2[i])

proc distribute*[T](s: seq[T], num: Positive, spread = true): seq[seq[T]] =
  ## Splits and distributes a sequence `s` into `num` sub-sequences.
  ##
  ## Returns a sequence of `num` sequences. For *some* input values this is the
  ## inverse of the `concat <#concat,varargs[seq[T]]>`_ proc.
  ## The input sequence `s` can be empty, which will produce
  ## `num` empty sequences.
  ##
  ## If `spread` is false and the length of `s` is not a multiple of `num`, the
  ## proc will max out the first sub-sequence with ``1 + len(s) div num``
  ## entries, leaving the remainder of elements to the last sequence.
  ##
  ## On the other hand, if `spread` is true, the proc will distribute evenly
  ## the remainder of the division across all sequences, which makes the result
  ## more suited to multithreading where you are passing equal sized work units
  ## to a thread pool and want to maximize core usage.
  ##
  runnableExamples:
    let numbers = @[1, 2, 3, 4, 5, 6, 7]
    assert numbers.distribute(3) == @[@[1, 2, 3], @[4, 5], @[6, 7]]
    assert numbers.distribute(3, false) == @[@[1, 2, 3], @[4, 5, 6], @[7]]
    assert numbers.distribute(6)[0] == @[1, 2]
    assert numbers.distribute(6)[1] == @[3]

  if num < 2:
    result = @[s]
    return
  let num = int(num) # XXX probably only needed because of .. bug

  # Create the result and calculate the stride size and the remainder if any.
  result = newSeq[seq[T]](num)
  var
    stride = s.len div num
    first = 0
    last = 0
    extra = s.len mod num

  if extra == 0 or spread == false:
    # Use an algorithm which overcounts the stride and minimizes reading limits.
    if extra > 0: inc(stride)
    for i in 0 ..< num:
      result[i] = newSeq[T]()
      for g in first ..< min(s.len, first + stride):
        result[i].add(s[g])
      first += stride
  else:
    # Use an undercounting algorithm which *adds* the remainder each iteration.
    for i in 0 ..< num:
      last = first + stride
      if extra > 0:
        extra -= 1
        inc(last)
      result[i] = newSeq[T]()
      for g in first ..< last:
        result[i].add(s[g])
      first = last

proc map*[T, S](s: openArray[T], op: proc (x: T): S {.closure.}):
                                                            seq[S]{.inline.} =
  ## Returns a new sequence with the results of `op` proc applied to every
  ## item in the container `s`.
  ##
  ## Since the input is not modified you can use it to
  ## transform the type of the elements in the input container.
  ##
  ## See also:
  ## * `mapIt template<#mapIt.t,typed,untyped>`_
  ## * `apply proc<#apply,openArray[T],proc(T)_2>`_ for the in-place version
  ##
  runnableExamples:
    let
      a = @[1, 2, 3, 4]
      b = map(a, proc(x: int): string = $x)
    assert b == @["1", "2", "3", "4"]

  newSeq(result, s.len)
  for i in 0 ..< s.len:
    result[i] = op(s[i])

proc apply*[T](s: var openArray[T], op: proc (x: var T) {.closure.})
                                                              {.inline.} =
  ## Applies `op` to every item in `s` modifying it directly.
  ##
  ## Note that container `s` must be declared as a ``var``
  ## and it is required for your input and output types to
  ## be the same, since `s` is modified in-place.
  ## The parameter function takes a ``var T`` type parameter.
  ##
  ## See also:
  ## * `applyIt template<#applyIt.t,untyped,untyped>`_
  ## * `map proc<#map,openArray[T],proc(T)>`_
  ##
  runnableExamples:
    var a = @["1", "2", "3", "4"]
    apply(a, proc(x: var string) = x &= "42")
    assert a == @["142", "242", "342", "442"]

  for i in 0 ..< s.len: op(s[i])

proc apply*[T](s: var openArray[T], op: proc (x: T): T {.closure.})
                                                              {.inline.} =
  ## Applies `op` to every item in `s` modifying it directly.
  ##
  ## Note that container `s` must be declared as a ``var``
  ## and it is required for your input and output types to
  ## be the same, since `s` is modified in-place.
  ## The parameter function takes and returns a ``T`` type variable.
  ##
  ## See also:
  ## * `applyIt template<#applyIt.t,untyped,untyped>`_
  ## * `map proc<#map,openArray[T],proc(T)>`_
  ##
  runnableExamples:
    var a = @["1", "2", "3", "4"]
    apply(a, proc(x: string): string = x & "42")
    assert a == @["142", "242", "342", "442"]

  for i in 0 ..< s.len: s[i] = op(s[i])

iterator filter*[T](s: openArray[T], pred: proc(x: T): bool {.closure.}): T =
  ## Iterates through a container `s` and yields every item that fulfills the
  ## predicate `pred` (function that returns a `bool`).
  ##
  ## See also:
  ## * `fliter proc<#filter,openArray[T],proc(T)>`_
  ## * `filterIt template<#filterIt.t,untyped,untyped>`_
  ##
  runnableExamples:
    let numbers = @[1, 4, 5, 8, 9, 7, 4]
    var evens = newSeq[int]()
    for n in filter(numbers, proc (x: int): bool = x mod 2 == 0):
      evens.add(n)
    assert evens == @[4, 8, 4]

  for i in 0 ..< s.len:
    if pred(s[i]):
      yield s[i]

proc filter*[T](s: openArray[T], pred: proc(x: T): bool {.closure.}): seq[T]
                                                                  {.inline.} =
  ## Returns a new sequence with all the items of `s` that fulfilled the
  ## predicate `pred` (function that returns a `bool`).
  ##
  ## See also:
  ## * `filterIt template<#filterIt.t,untyped,untyped>`_
  ## * `filter iterator<#filter.i,openArray[T],proc(T)>`_
  ## * `keepIf proc<#keepIf,seq[T],proc(T)>`_ for the in-place version
  ##
  runnableExamples:
    let
      colors = @["red", "yellow", "black"]
      f1 = filter(colors, proc(x: string): bool = x.len < 6)
      f2 = filter(colors, proc(x: string): bool = x.contains('y'))
    assert f1 == @["red", "black"]
    assert f2 == @["yellow"]

  result = newSeq[T]()
  for i in 0 ..< s.len:
    if pred(s[i]):
      result.add(s[i])

proc keepIf*[T](s: var seq[T], pred: proc(x: T): bool {.closure.})
                                                                {.inline.} =
  ## Keeps the items in the passed sequence `s` if they fulfilled the
  ## predicate `pred` (function that returns a `bool`).
  ##
  ## Note that `s` must be declared as a ``var``.
  ##
  ## Similar to the `filter proc<#filter,openArray[T],proc(T)>`_,
  ## but modifies the sequence directly.
  ##
  ## See also:
  ## * `keepItIf template<#keepItIf.t,seq,untyped>`_
  ## * `filter proc<#filter,openArray[T],proc(T)>`_
  ##
  runnableExamples:
    var floats = @[13.0, 12.5, 5.8, 2.0, 6.1, 9.9, 10.1]
    keepIf(floats, proc(x: float): bool = x > 10)
    assert floats == @[13.0, 12.5, 10.1]

  var pos = 0
  for i in 0 ..< len(s):
    if pred(s[i]):
      if pos != i:
        shallowCopy(s[pos], s[i])
      inc(pos)
  setLen(s, pos)

proc delete*[T](s: var seq[T]; first, last: Natural) =
  ## Deletes in the items of a sequence `s` at positions ``first..last``
  ## (including both ends of a range).
  ## This modifies `s` itself, it does not return a copy.
  ##
  runnableExamples:
    let outcome = @[1,1,1,1,1,1,1,1]
    var dest = @[1,1,1,2,2,2,2,2,2,1,1,1,1,1]
    dest.delete(3, 8)
    assert outcome == dest

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
  ## Notice that `src` and `dest` must be of the same type.
  ##
  runnableExamples:
    var dest = @[1,1,1,1,1,1,1,1]
    let
      src = @[2,2,2,2,2,2]
      outcome = @[1,1,1,2,2,2,2,2,2,1,1,1,1,1]
    dest.insert(src, 3)
    assert dest == outcome

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


template filterIt*(s, pred: untyped): untyped =
  ## Returns a new sequence with all the items of `s` that fulfilled the
  ## predicate `pred`.
  ##
  ## Unlike the `filter proc<#filter,openArray[T],proc(T)>`_ and
  ## `filter iterator<#filter.i,openArray[T],proc(T)>`_,
  ## the predicate needs to be an expression using the ``it`` variable
  ## for testing, like: ``filterIt("abcxyz", it == 'x')``.
  ##
  ## See also:
  ## * `fliter proc<#filter,openArray[T],proc(T)>`_
  ## * `filter iterator<#filter.i,openArray[T],proc(T)>`_
  ##
  runnableExamples:
    let
      temperatures = @[-272.15, -2.0, 24.5, 44.31, 99.9, -113.44]
      acceptable = temperatures.filterIt(it < 50 and it > -10)
      notAcceptable = temperatures.filterIt(it > 50 or it < -10)
    assert acceptable == @[-2.0, 24.5, 44.31]
    assert notAcceptable == @[-272.15, 99.9, -113.44]

  var result = newSeq[type(s[0])]()
  for it {.inject.} in items(s):
    if pred: result.add(it)
  result

template keepItIf*(varSeq: seq, pred: untyped) =
  ## Keeps the items in the passed sequence (must be declared as a ``var``)
  ## if they fulfilled the predicate.
  ##
  ## Unlike the `keepIf proc<#keepIf,seq[T],proc(T)>`_,
  ## the predicate needs to be an expression using
  ## the ``it`` variable for testing, like: ``keepItIf("abcxyz", it == 'x')``.
  ##
  ## See also:
  ## * `keepIf proc<#keepIf,seq[T],proc(T)>`_
  ## * `filterIt template<#filterIt.t,untyped,untyped>`_
  ##
  runnableExamples:
    var candidates = @["foo", "bar", "baz", "foobar"]
    candidates.keepItIf(it.len == 3 and it[0] == 'b')
    assert candidates == @["bar", "baz"]

  var pos = 0
  for i in 0 ..< len(varSeq):
    let it {.inject.} = varSeq[i]
    if pred:
      if pos != i:
        shallowCopy(varSeq[pos], varSeq[i])
      inc(pos)
  setLen(varSeq, pos)

proc all*[T](s: openArray[T], pred: proc(x: T): bool {.closure.}): bool =
  ## Iterates through a container and checks if every item fulfills the
  ## predicate.
  ##
  ## See also:
  ## * `allIt template<#allIt.t,untyped,untyped>`_
  ## * `any proc<#any,openArray[T],proc(T)>`_
  ##
  runnableExamples:
     let numbers = @[1, 4, 5, 8, 9, 7, 4]
     assert all(numbers, proc (x: int): bool = return x < 10) == true
     assert all(numbers, proc (x: int): bool = return x < 9) == false

  for i in s:
    if not pred(i):
      return false
  return true

template allIt*(s, pred: untyped): bool =
  ## Iterates through a container and checks if every item fulfills the
  ## predicate.
  ##
  ## Unlike the `all proc<#all,openArray[T],proc(T)>`_,
  ## the predicate needs to be an expression using
  ## the ``it`` variable for testing, like: ``allIt("abba", it == 'a')``.
  ##
  ## See also:
  ## * `all proc<#all,openArray[T],proc(T)>`_
  ## * `anyIt template<#anyIt.t,untyped,untyped>`_
  ##
  runnableExamples:
    let numbers = @[1, 4, 5, 8, 9, 7, 4]
    assert numbers.allIt(it < 10) == true
    assert numbers.allIt(it < 9) == false

  var result = true
  for it {.inject.} in items(s):
    if not pred:
      result = false
      break
  result

proc any*[T](s: openArray[T], pred: proc(x: T): bool {.closure.}): bool =
  ## Iterates through a container and checks if some item fulfills the
  ## predicate.
  ##
  ## See also:
  ## * `anyIt template<#anyIt.t,untyped,untyped>`_
  ## * `all proc<#all,openArray[T],proc(T)>`_
  ##
  runnableExamples:
    let numbers = @[1, 4, 5, 8, 9, 7, 4]
    assert any(numbers, proc (x: int): bool = return x > 8) == true
    assert any(numbers, proc (x: int): bool = return x > 9) == false

  for i in s:
    if pred(i):
      return true
  return false

template anyIt*(s, pred: untyped): bool =
  ## Iterates through a container and checks if some item fulfills the
  ## predicate.
  ##
  ## Unlike the `any proc<#any,openArray[T],proc(T)>`_,
  ## the predicate needs to be an expression using
  ## the ``it`` variable for testing, like: ``anyIt("abba", it == 'a')``.
  ##
  ## See also:
  ## * `any proc<#any,openArray[T],proc(T)>`_
  ## * `allIt template<#allIt.t,untyped,untyped>`_
  ##
  runnableExamples:
    let numbers = @[1, 4, 5, 8, 9, 7, 4]
    assert numbers.anyIt(it > 8) == true
    assert numbers.anyIt(it > 9) == false

  var result = false
  for it {.inject.} in items(s):
    if pred:
      result = true
      break
  result

template toSeq1(s: not iterator): untyped =
  # overload for typed but not iterator
  type outType = type(items(s))
  when compiles(s.len):
    block:
      evalOnceAs(s2, s, compiles((let _ = s)))
      var i = 0
      var result = newSeq[outType](s2.len)
      for it in s2:
        result[i] = it
        i += 1
      result
  else:
    var result: seq[outType] = @[]
    for it in s:
      result.add(it)
    result

template toSeq2(iter: iterator): untyped =
  # overload for iterator
  evalOnceAs(iter2, iter(), false)
  when compiles(iter2.len):
    var i = 0
    var result = newSeq[type(iter2)](iter2.len)
    for x in iter2:
      result[i] = x
      inc i
    result
  else:
    type outType = type(iter2())
    var result: seq[outType] = @[]
    when compiles(iter2()):
      evalOnceAs(iter4, iter, false)
      let iter3=iter4()
      for x in iter3():
        result.add(x)
    else:
      for x in iter2():
        result.add(x)
    result

template toSeq*(iter: untyped): untyped =
  ## Transforms any iterable (anything that can be iterated over, e.g. with
  ## a for-loop) into a sequence.
  ##
  runnableExamples:
    let
      myRange = 1..5
      mySet: set[int8] = {5'i8, 3, 1}
    assert type(myRange) is HSlice[system.int, system.int]
    assert type(mySet) is set[int8]

    let
      mySeq1 = toSeq(myRange)
      mySeq2 = toSeq(mySet)
    assert mySeq1 == @[1, 2, 3, 4, 5]
    assert mySeq2 == @[1'i8, 3, 5]

  when compiles(toSeq1(iter)):
    toSeq1(iter)
  elif compiles(toSeq2(iter)):
    toSeq2(iter)
  else:
    # overload for untyped, e.g.: `toSeq(myInlineIterator(3))`
    when compiles(iter.len):
      block:
        evalOnceAs(iter2, iter, true)
        var result = newSeq[type(iter)](iter2.len)
        var i = 0
        for x in iter2:
          result[i] = x
          inc i
        result
    else:
      var result: seq[type(iter)] = @[]
      for x in iter:
        result.add(x)
      result

template foldl*(sequence, operation: untyped): untyped =
  ## Template to fold a sequence from left to right, returning the accumulation.
  ##
  ## The sequence is required to have at least a single element. Debug versions
  ## of your program will assert in this situation but release versions will
  ## happily go ahead. If the sequence has a single element it will be returned
  ## without applying ``operation``.
  ##
  ## The ``operation`` parameter should be an expression which uses the
  ## variables ``a`` and ``b`` for each step of the fold. Since this is a left
  ## fold, for non associative binary operations like subtraction think that
  ## the sequence of numbers 1, 2 and 3 will be parenthesized as (((1) - 2) -
  ## 3).
  ##
  ## See also:
  ## * `foldl template<#foldl.t,,,>`_ with a starting parameter
  ## * `foldr template<#foldr.t,untyped,untyped>`_
  ##
  runnableExamples:
    let
      numbers = @[5, 9, 11]
      addition = foldl(numbers, a + b)
      subtraction = foldl(numbers, a - b)
      multiplication = foldl(numbers, a * b)
      words = @["nim", "is", "cool"]
      concatenation = foldl(words, a & b)
    assert addition == 25, "Addition is (((5)+9)+11)"
    assert subtraction == -15, "Subtraction is (((5)-9)-11)"
    assert multiplication == 495, "Multiplication is (((5)*9)*11)"
    assert concatenation == "nimiscool"

  let s = sequence
  assert s.len > 0, "Can't fold empty sequences"
  var result: type(s[0])
  result = s[0]
  for i in 1..<s.len:
    let
      a {.inject.} = result
      b {.inject.} = s[i]
    result = operation
  result

template foldl*(sequence, operation, first): untyped =
  ## Template to fold a sequence from left to right, returning the accumulation.
  ##
  ## This version of ``foldl`` gets a **starting parameter**. This makes it possible
  ## to accumulate the sequence into a different type than the sequence elements.
  ##
  ## The ``operation`` parameter should be an expression which uses the variables
  ## ``a`` and ``b`` for each step of the fold. The ``first`` parameter is the
  ## start value (the first ``a``) and therefor defines the type of the result.
  ##
  ## See also:
  ## * `foldr template<#foldr.t,untyped,untyped>`_
  ##
  runnableExamples:
    let
      numbers = @[0, 8, 1, 5]
      digits = foldl(numbers, a & (chr(b + ord('0'))), "")
    assert digits == "0815"

  var result: type(first)
  result = first
  for x in items(sequence):
    let
      a {.inject.} = result
      b {.inject.} = x
    result = operation
  result

template foldr*(sequence, operation: untyped): untyped =
  ## Template to fold a sequence from right to left, returning the accumulation.
  ##
  ## The sequence is required to have at least a single element. Debug versions
  ## of your program will assert in this situation but release versions will
  ## happily go ahead. If the sequence has a single element it will be returned
  ## without applying ``operation``.
  ##
  ## The ``operation`` parameter should be an expression which uses the
  ## variables ``a`` and ``b`` for each step of the fold. Since this is a right
  ## fold, for non associative binary operations like subtraction think that
  ## the sequence of numbers 1, 2 and 3 will be parenthesized as (1 - (2 -
  ## (3))).
  ##
  ## See also:
  ## * `foldl template<#foldl.t,untyped,untyped>`_
  ## * `foldl template<#foldl.t,,,>`_ with a starting parameter
  ##
  runnableExamples:
    let
      numbers = @[5, 9, 11]
      addition = foldr(numbers, a + b)
      subtraction = foldr(numbers, a - b)
      multiplication = foldr(numbers, a * b)
      words = @["nim", "is", "cool"]
      concatenation = foldr(words, a & b)
    assert addition == 25, "Addition is (5+(9+(11)))"
    assert subtraction == 7, "Subtraction is (5-(9-(11)))"
    assert multiplication == 495, "Multiplication is (5*(9*(11)))"
    assert concatenation == "nimiscool"

  let s = sequence
  assert s.len > 0, "Can't fold empty sequences"
  var result: type(s[0])
  result = sequence[s.len - 1]
  for i in countdown(s.len - 2, 0):
    let
      a {.inject.} = s[i]
      b {.inject.} = result
    result = operation
  result

template mapIt*(s: typed, op: untyped): untyped =
  ## Returns a new sequence with the results of `op` proc applied to every
  ## item in the container `s`.
  ##
  ## Since the input is not modified you can use it to
  ## transform the type of the elements in the input container.
  ##
  ## The template injects the ``it`` variable which you can use directly in an
  ## expression.
  ##
  ## See also:
  ## * `map proc<#map,openArray[T],proc(T)>`_
  ## * `applyIt template<#applyIt.t,untyped,untyped>`_ for the in-place version
  ##
  runnableExamples:
    let
      nums = @[1, 2, 3, 4]
      strings = nums.mapIt($(4 * it))
    assert strings == @["4", "8", "12", "16"]

  when defined(nimHasTypeof):
    type outType = typeof((
      block:
        var it{.inject.}: typeof(items(s), typeOfIter);
        op), typeOfProc)
  else:
    type outType = type((
      block:
        var it{.inject.}: type(items(s));
        op))
  when compiles(s.len):
    block: # using a block avoids https://github.com/nim-lang/Nim/issues/8580

      # BUG: `evalOnceAs(s2, s, false)` would lead to C compile errors
      # (`error: use of undeclared identifier`) instead of Nim compile errors
      evalOnceAs(s2, s, compiles((let _ = s)))

      var i = 0
      var result = newSeq[outType](s2.len)
      for it {.inject.} in s2:
        result[i] = op
        i += 1
      result
  else:
    var result: seq[outType] = @[]
    for it {.inject.} in s:
      result.add(op)
    result

template mapIt*(s, typ, op: untyped): untyped {.error:
  "Use 'mapIt(seq1, op)' - without specifying the type of the returned seqence".} =
  ## **Deprecated since version 0.12.0:** Use the `mapIt(seq1, op) template
  ## <#mapIt.t,typed,untyped>`_ instead.
  var result: seq[typ] = @[]
  for it {.inject.} in items(s):
    result.add(op)
  result

template applyIt*(varSeq, op: untyped) =
  ## Convenience template around the mutable ``apply`` proc to reduce typing.
  ##
  ## The template injects the ``it`` variable which you can use directly in an
  ## expression. The expression has to return the same type as the sequence you
  ## are mutating.
  ##
  ## See also:
  ## * `apply proc<#apply,openArray[T],proc(T)_2>`_
  ## * `mapIt template<#mapIt.t,typed,untyped>`_
  ##
  runnableExamples:
     var nums = @[1, 2, 3, 4]
     nums.applyIt(it * 3)
     assert nums[0] + nums[3] == 15

  for i in low(varSeq) .. high(varSeq):
    let it {.inject.} = varSeq[i]
    varSeq[i] = op


template newSeqWith*(len: int, init: untyped): untyped =
  ## Creates a new sequence of length `len`, calling `init` to initialize
  ## each value of the sequence.
  ##
  ## Useful for creating "2D" sequences - sequences containing other sequences
  ## or to populate fields of the created sequence.
  ##
  runnableExamples:
    ## Creates a seqence containing 5 bool sequences, each of length of 3.
    var seq2D = newSeqWith(5, newSeq[bool](3))
    assert seq2D.len == 5
    assert seq2D[0].len == 3
    assert seq2D[4][2] == false

    ## Creates a sequence of 20 random numbers from 1 to 10
    import random
    var seqRand = newSeqWith(20, random(10))

  var result = newSeq[type(init)](len)
  for i in 0 ..< len:
    result[i] = init
  result

proc mapLitsImpl(constructor: NimNode; op: NimNode; nested: bool;
                 filter = nnkLiterals): NimNode =
  if constructor.kind in filter:
    result = newNimNode(nnkCall, lineInfoFrom=constructor)
    result.add op
    result.add constructor
  else:
    result = copyNimNode(constructor)
    for v in constructor:
      if nested or v.kind in filter:
        result.add mapLitsImpl(v, op, nested, filter)
      else:
        result.add v

macro mapLiterals*(constructor, op: untyped;
                   nested = true): untyped =
  ## Applies ``op`` to each of the **atomic** literals like ``3``
  ## or ``"abc"`` in the specified ``constructor`` AST. This can
  ## be used to map every array element to some target type:
  ##
  ## Example:
  ##
  ## .. code-block::
  ##   let x = mapLiterals([0.1, 1.2, 2.3, 3.4], int)
  ##   doAssert x is array[4, int]
  ##
  ## Short notation for:
  ##
  ## .. code-block::
  ##   let x = [int(0.1), int(1.2), int(2.3), int(3.4)]
  ##
  ## If ``nested`` is true (which is the default), the literals are replaced
  ## everywhere in the ``constructor`` AST, otherwise only the first level
  ## is considered:
  ##
  ## .. code-block::
  ##   let a = mapLiterals((1.2, (2.3, 3.4), 4.8), int)
  ##   let b = mapLiterals((1.2, (2.3, 3.4), 4.8), int, nested=false)
  ##   assert a == (1, (2, 3), 4)
  ##   assert b == (1, (2.3, 3.4), 4)
  ##
  ##   let c = mapLiterals((1, (2, 3), 4, (5, 6)), `$`)
  ##   let d = mapLiterals((1, (2, 3), 4, (5, 6)), `$`, nested=false)
  ##   assert c == ("1", ("2", "3"), "4", ("5", "6"))
  ##   assert d == ("1", (2, 3), "4", (5, 6))
  ##
  ## There are no constraints for the ``constructor`` AST, it
  ## works for nested tuples of arrays of sets etc.
  result = mapLitsImpl(constructor, op, nested.boolVal)

iterator items*[T](xs: iterator: T): T =
  ## iterates over each element yielded by a closure iterator. This may
  ## not seem particularly useful on its own, but this allows closure
  ## iterators to be used by the the mapIt, filterIt, allIt, anyIt, etc.
  ## templates.
  for x in xs():
    yield x

when isMainModule:
  import strutils
  from algorithm import sorted

  # helper for testing double substitution side effects which are handled
  # by `evalOnceAs`
  var counter = 0
  proc identity[T](a:T):auto=
    counter.inc
    a

  block: # concat test
    let
      s1 = @[1, 2, 3]
      s2 = @[4, 5]
      s3 = @[6, 7]
      total = concat(s1, s2, s3)
    assert total == @[1, 2, 3, 4, 5, 6, 7]

  block: # count test
    let
      s1 = @[1, 2, 3, 2]
      s2 = @['a', 'b', 'x', 'a']
      a1 = [1, 2, 3, 2]
      a2 = ['a', 'b', 'x', 'a']
      r0 = count(s1, 0)
      r1 = count(s1, 1)
      r2 = count(s1, 2)
      r3 = count(s2, 'y')
      r4 = count(s2, 'x')
      r5 = count(s2, 'a')
      ar0 = count(a1, 0)
      ar1 = count(a1, 1)
      ar2 = count(a1, 2)
      ar3 = count(a2, 'y')
      ar4 = count(a2, 'x')
      ar5 = count(a2, 'a')
    assert r0 == 0
    assert r1 == 1
    assert r2 == 2
    assert r3 == 0
    assert r4 == 1
    assert r5 == 2
    assert ar0 == 0
    assert ar1 == 1
    assert ar2 == 2
    assert ar3 == 0
    assert ar4 == 1
    assert ar5 == 2

  block: # cycle tests
    let
      a = @[1, 2, 3]
      b: seq[int] = @[]
      c = [1, 2, 3]

    doAssert a.cycle(3) == @[1, 2, 3, 1, 2, 3, 1, 2, 3]
    doAssert a.cycle(0) == @[]
    #doAssert a.cycle(-1) == @[] # will not compile!
    doAssert b.cycle(3) == @[]
    doAssert c.cycle(3) == @[1, 2, 3, 1, 2, 3, 1, 2, 3]
    doAssert c.cycle(0) == @[]

  block: # repeat tests
    assert repeat(10, 5) == @[10, 10, 10, 10, 10]
    assert repeat(@[1,2,3], 2) == @[@[1,2,3], @[1,2,3]]
    assert repeat([1,2,3], 2) == @[[1,2,3], [1,2,3]]

  block: # deduplicates test
    let
      dup1 = @[1, 1, 3, 4, 2, 2, 8, 1, 4]
      dup2 = @["a", "a", "c", "d", "d"]
      dup3 = [1, 1, 3, 4, 2, 2, 8, 1, 4]
      dup4 = ["a", "a", "c", "d", "d"]
      unique1 = deduplicate(dup1)
      unique2 = deduplicate(dup2)
      unique3 = deduplicate(dup3)
      unique4 = deduplicate(dup4)
      unique5 = deduplicate(dup1.sorted, true)
      unique6 = deduplicate(dup2, true)
      unique7 = deduplicate(dup3.sorted, true)
      unique8 = deduplicate(dup4, true)
    assert unique1 == @[1, 3, 4, 2, 8]
    assert unique2 == @["a", "c", "d"]
    assert unique3 == @[1, 3, 4, 2, 8]
    assert unique4 == @["a", "c", "d"]
    assert unique5 == @[1, 2, 3, 4, 8]
    assert unique6 == @["a", "c", "d"]
    assert unique7 == @[1, 2, 3, 4, 8]
    assert unique8 == @["a", "c", "d"]

  block: # zip test
    let
      short = @[1, 2, 3]
      long = @[6, 5, 4, 3, 2, 1]
      words = @["one", "two", "three"]
      ashort = [1, 2, 3]
      along = [6, 5, 4, 3, 2, 1]
      awords = ["one", "two", "three"]
      zip1 = zip(short, long)
      zip2 = zip(short, words)
      zip3 = zip(ashort, along)
      zip4 = zip(ashort, awords)
      zip5 = zip(ashort, words)
    assert zip1 == @[(1, 6), (2, 5), (3, 4)]
    assert zip2 == @[(1, "one"), (2, "two"), (3, "three")]
    assert zip3 == @[(1, 6), (2, 5), (3, 4)]
    assert zip4 == @[(1, "one"), (2, "two"), (3, "three")]
    assert zip5 == @[(1, "one"), (2, "two"), (3, "three")]
    assert zip1[2].b == 4
    assert zip2[2].b == "three"
    assert zip3[2].b == 4
    assert zip4[2].b == "three"
    assert zip5[2].b == "three"

  block: # distribute tests
    let numbers = @[1, 2, 3, 4, 5, 6, 7]
    doAssert numbers.distribute(3) == @[@[1, 2, 3], @[4, 5], @[6, 7]]
    doAssert numbers.distribute(6)[0] == @[1, 2]
    doAssert numbers.distribute(6)[5] == @[7]
    let a = @[1, 2, 3, 4, 5, 6, 7]
    doAssert a.distribute(1, true) == @[@[1, 2, 3, 4, 5, 6, 7]]
    doAssert a.distribute(1, false) == @[@[1, 2, 3, 4, 5, 6, 7]]
    doAssert a.distribute(2, true) == @[@[1, 2, 3, 4], @[5, 6, 7]]
    doAssert a.distribute(2, false) == @[@[1, 2, 3, 4], @[5, 6, 7]]
    doAssert a.distribute(3, true) == @[@[1, 2, 3], @[4, 5], @[6, 7]]
    doAssert a.distribute(3, false) == @[@[1, 2, 3], @[4, 5, 6], @[7]]
    doAssert a.distribute(4, true) == @[@[1, 2], @[3, 4], @[5, 6], @[7]]
    doAssert a.distribute(4, false) == @[@[1, 2], @[3, 4], @[5, 6], @[7]]
    doAssert a.distribute(5, true) == @[@[1, 2], @[3, 4], @[5], @[6], @[7]]
    doAssert a.distribute(5, false) == @[@[1, 2], @[3, 4], @[5, 6], @[7], @[]]
    doAssert a.distribute(6, true) == @[@[1, 2], @[3], @[4], @[5], @[6], @[7]]
    doAssert a.distribute(6, false) == @[
      @[1, 2], @[3, 4], @[5, 6], @[7], @[], @[]]
    doAssert a.distribute(8, false) == a.distribute(8, true)
    doAssert a.distribute(90, false) == a.distribute(90, true)
    var b = @[0]
    for f in 1 .. 25: b.add(f)
    doAssert b.distribute(5, true)[4].len == 5
    doAssert b.distribute(5, false)[4].len == 2

  block: # map test
    let
      numbers = @[1, 4, 5, 8, 9, 7, 4]
      anumbers = [1, 4, 5, 8, 9, 7, 4]
      m1 = map(numbers, proc(x: int): int = 2*x)
      m2 = map(anumbers, proc(x: int): int = 2*x)
    assert m1 == @[2, 8, 10, 16, 18, 14, 8]
    assert m2 == @[2, 8, 10, 16, 18, 14, 8]

  block: # apply test
    var a = @["1", "2", "3", "4"]
    apply(a, proc(x: var string) = x &= "42")
    assert a == @["142", "242", "342", "442"]

  block: # filter proc test
    let
      colors = @["red", "yellow", "black"]
      acolors = ["red", "yellow", "black"]
      f1 = filter(colors, proc(x: string): bool = x.len < 6)
      f2 = filter(colors) do (x: string) -> bool : x.len > 5
      f3 = filter(acolors, proc(x: string): bool = x.len < 6)
      f4 = filter(acolors) do (x: string) -> bool : x.len > 5
    assert f1 == @["red", "black"]
    assert f2 == @["yellow"]
    assert f3 == @["red", "black"]
    assert f4 == @["yellow"]

  block: # filter iterator test
    let numbers = @[1, 4, 5, 8, 9, 7, 4]
    let anumbers = [1, 4, 5, 8, 9, 7, 4]
    assert toSeq(filter(numbers, proc (x: int): bool = x mod 2 == 0)) ==
      @[4, 8, 4]
    assert toSeq(filter(anumbers, proc (x: int): bool = x mod 2 == 0)) ==
      @[4, 8, 4]

  block: # keepIf test
    var floats = @[13.0, 12.5, 5.8, 2.0, 6.1, 9.9, 10.1]
    keepIf(floats, proc(x: float): bool = x > 10)
    assert floats == @[13.0, 12.5, 10.1]

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

  block: # filterIt test
    let
      temperatures = @[-272.15, -2.0, 24.5, 44.31, 99.9, -113.44]
      acceptable = filterIt(temperatures, it < 50 and it > -10)
      notAcceptable = filterIt(temperatures, it > 50 or it < -10)
    assert acceptable == @[-2.0, 24.5, 44.31]
    assert notAcceptable == @[-272.15, 99.9, -113.44]

  block: # keepItIf test
    var candidates = @["foo", "bar", "baz", "foobar"]
    keepItIf(candidates, it.len == 3 and it[0] == 'b')
    assert candidates == @["bar", "baz"]

  block: # all
    let
      numbers = @[1, 4, 5, 8, 9, 7, 4]
      anumbers = [1, 4, 5, 8, 9, 7, 4]
      len0seq : seq[int] = @[]
    assert all(numbers, proc (x: int): bool = return x < 10) == true
    assert all(numbers, proc (x: int): bool = return x < 9) == false
    assert all(len0seq, proc (x: int): bool = return false) == true
    assert all(anumbers, proc (x: int): bool = return x < 10) == true
    assert all(anumbers, proc (x: int): bool = return x < 9) == false

  block: # allIt
    let
      numbers = @[1, 4, 5, 8, 9, 7, 4]
      anumbers = [1, 4, 5, 8, 9, 7, 4]
      len0seq : seq[int] = @[]
    assert allIt(numbers, it < 10) == true
    assert allIt(numbers, it < 9) == false
    assert allIt(len0seq, false) == true
    assert allIt(anumbers, it < 10) == true
    assert allIt(anumbers, it < 9) == false

  block: # any
    let
      numbers = @[1, 4, 5, 8, 9, 7, 4]
      anumbers = [1, 4, 5, 8, 9, 7, 4]
      len0seq : seq[int] = @[]
    assert any(numbers, proc (x: int): bool = return x > 8) == true
    assert any(numbers, proc (x: int): bool = return x > 9) == false
    assert any(len0seq, proc (x: int): bool = return true) == false
    assert any(anumbers, proc (x: int): bool = return x > 8) == true
    assert any(anumbers, proc (x: int): bool = return x > 9) == false

  block: # anyIt
    let
      numbers = @[1, 4, 5, 8, 9, 7, 4]
      anumbers = [1, 4, 5, 8, 9, 7, 4]
      len0seq : seq[int] = @[]
    assert anyIt(numbers, it > 8) == true
    assert anyIt(numbers, it > 9) == false
    assert anyIt(len0seq, true) == false
    assert anyIt(anumbers, it > 8) == true
    assert anyIt(anumbers, it > 9) == false

  block: # toSeq test
    block:
      let
        numeric = @[1, 2, 3, 4, 5, 6, 7, 8, 9]
        odd_numbers = toSeq(filter(numeric) do (x: int) -> bool:
          if x mod 2 == 1:
            result = true)
      assert odd_numbers == @[1, 3, 5, 7, 9]

    block:
      doAssert [1,2].toSeq == @[1,2]
      doAssert @[1,2].toSeq == @[1,2]

      doAssert @[1,2].toSeq == @[1,2]
      doAssert toSeq(@[1,2]) == @[1,2]

    block:
      iterator myIter(seed:int):auto=
        for i in 0..<seed:
          yield i
      doAssert toSeq(myIter(2)) == @[0, 1]

    block:
      iterator myIter():auto{.inline.}=
        yield 1
        yield 2

      doAssert myIter.toSeq == @[1,2]
      doAssert toSeq(myIter) == @[1,2]

    block:
      iterator myIter():int {.closure.} =
        yield 1
        yield 2

      doAssert myIter.toSeq == @[1,2]
      doAssert toSeq(myIter) == @[1,2]

    block:
      proc myIter():auto=
        iterator ret():int{.closure.}=
          yield 1
          yield 2
        result = ret

      doAssert myIter().toSeq == @[1,2]
      doAssert toSeq(myIter()) == @[1,2]

    block:
      proc myIter(n:int):auto=
        var counter = 0
        iterator ret():int{.closure.}=
          while counter<n:
            yield counter
            counter.inc
        result = ret

      block:
        let myIter3 = myIter(3)
        doAssert myIter3.toSeq == @[0,1,2]
      block:
        let myIter3 = myIter(3)
        doAssert toSeq(myIter3) == @[0,1,2]
      block:
        # makes sure this does not hang forever
        doAssert myIter(3).toSeq == @[0,1,2]
        doAssert toSeq(myIter(3)) == @[0,1,2]

  block:
    # tests https://github.com/nim-lang/Nim/issues/7187
    counter = 0
    let ret = toSeq(@[1, 2, 3].identity().filter(proc (x: int): bool = x < 3))
    doAssert ret == @[1, 2]
    doAssert counter == 1
  block: # foldl tests
    let
      numbers = @[5, 9, 11]
      addition = foldl(numbers, a + b)
      subtraction = foldl(numbers, a - b)
      multiplication = foldl(numbers, a * b)
      words = @["nim", "is", "cool"]
      concatenation = foldl(words, a & b)
    assert addition == 25, "Addition is (((5)+9)+11)"
    assert subtraction == -15, "Subtraction is (((5)-9)-11)"
    assert multiplication == 495, "Multiplication is (((5)*9)*11)"
    assert concatenation == "nimiscool"

  block: # foldr tests
    let
      numbers = @[5, 9, 11]
      addition = foldr(numbers, a + b)
      subtraction = foldr(numbers, a - b)
      multiplication = foldr(numbers, a * b)
      words = @["nim", "is", "cool"]
      concatenation = foldr(words, a & b)
    assert addition == 25, "Addition is (5+(9+(11)))"
    assert subtraction == 7, "Subtraction is (5-(9-(11)))"
    assert multiplication == 495, "Multiplication is (5*(9*(11)))"
    assert concatenation == "nimiscool"

  block: # mapIt + applyIt test
    counter = 0
    var
      nums = @[1, 2, 3, 4]
      strings = nums.identity.mapIt($(4 * it))
    doAssert counter == 1
    nums.applyIt(it * 3)
    assert nums[0] + nums[3] == 15
    assert strings[2] == "12"

  block: # newSeqWith tests
    var seq2D = newSeqWith(4, newSeq[bool](2))
    seq2D[0][0] = true
    seq2D[1][0] = true
    seq2D[0][1] = true
    doAssert seq2D == @[@[true, true], @[true, false], @[false, false], @[false, false]]

  block: # mapLiterals tests
    let x = mapLiterals([0.1, 1.2, 2.3, 3.4], int)
    doAssert x is array[4, int]
    doAssert mapLiterals((1, ("abc"), 2), float, nested=false) == (float(1), "abc", float(2))
    doAssert mapLiterals(([1], ("abc"), 2), `$`, nested=true) == (["1"], "abc", "2")

  block: # mapIt with openArray
    counter = 0
    proc foo(x: openArray[int]): seq[int] = x.mapIt(it * 10)
    doAssert foo([identity(1),identity(2)]) == @[10, 20]
    doAssert counter == 2

  block: # mapIt with direct openArray
    proc foo1(x: openArray[int]): seq[int] = x.mapIt(it * 10)
    counter = 0
    doAssert foo1(openArray[int]([identity(1),identity(2)])) == @[10,20]
    doAssert counter == 2

    # Corner cases (openArray litterals should not be common)
    template foo2(x: openArray[int]): seq[int] = x.mapIt(it * 10)
    counter = 0
    doAssert foo2(openArray[int]([identity(1),identity(2)])) == @[10,20]
    # TODO: this fails; not sure how to fix this case
    # doAssert counter == 2

    counter = 0
    doAssert openArray[int]([identity(1), identity(2)]).mapIt(it) == @[1,2]
    # ditto
    # doAssert counter == 2

  block: # mapIt empty test, see https://github.com/nim-lang/Nim/pull/8584#pullrequestreview-144723468
    # NOTE: `[].mapIt(it)` is illegal, just as `let a = @[]` is (lacks type
    # of elements)
    doAssert: not compiles(mapIt(@[], it))
    doAssert: not compiles(mapIt([], it))
    doAssert newSeq[int](0).mapIt(it) == @[]

  block: # mapIt redifinition check, see https://github.com/nim-lang/Nim/issues/8580
    let s2 = [1,2].mapIt(it)
    doAssert s2 == @[1,2]

  block:
    counter = 0
    doAssert [1,2].identity().mapIt(it*2).mapIt(it*10) == @[20, 40]
    # https://github.com/nim-lang/Nim/issues/7187 test case
    doAssert counter == 1

  block: # mapIt with invalid RHS for `let` (#8566)
    type X = enum
      A, B
    doAssert mapIt(X, $it) == @["A", "B"]

  block:
    # bug #9093
    let inp = "a:b,c:d"

    let outp = inp.split(",").mapIt(it.split(":"))
    doAssert outp == @[@["a", "b"], @["c", "d"]]


  block:
    proc iter(len: int): auto =
      result = iterator(): int =
        for i in 0..<len:
          yield i

    doAssert: iter(3).mapIt(2*it).foldl(a + b) == 6

  when not defined(testing):
    echo "Finished doc tests"
