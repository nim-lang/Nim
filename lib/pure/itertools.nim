#
#            Nim's Runtime Library
#     (c) Copyright 2023, 2025      Jason Beetham
#     (c) Copyright 2023, 2025-2026 Kirill Ildyukov
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## itertools
## =========
##
## **iterools** provides a set of templates for composable pipelines
## enabling powerful, expressive and concise syntax for common operations
## such as filtering, mapping, accumulation, and element retrieval, based on
## Nim's **inline iterators**. These templates offer a declarative, more readable
## and, arguably, less error-prone alternative to writing manual imperative loops.
##
## If you have used `map`, `filter`, and `reduce` in Python, Rust, Haskell,
## or Scala, `itertools` gives you a similar familiar syntax inspired by the
## functional programming paradigm in Nim: *write a chain of operations in one
## readable expression instead of several nested loops and temporary variables*.
##
## - *no intermediate sequences* allocated between chain elements.
## - *works on anything that can be iterated over*, including custom types and
##   not just `seqs`. As long as there's *some* iterator provided, you're set.
## - *collect to any container*: `seq`, `HashSet`, `string`, or
##   a custom type.
## - *easily extendable*: write your own iterator adapters/consumers and they
##   will compose.
##
runnableExamples:
  import std/[strutils, options, tables, sets]

  # Find the first element in a sequence of transformed numbers above 35.
  # Note using `Slice[int].items` instead of `CountUp` (also supported).
  doAssert (-25..25).items.mapIt(it * 10 div 7).findIt(it > 35) == none(int)

  # Filter philosophers by country, compose sentences, join to a string.
  let philosophers = {
    "Plato": "Greece", "Aristotle": "Greece", "Socrates": "Greece",
    "Confucius": "China", "Descartes": "France"}

  const Phrase = "$1 is a famous philosopher from $2."
  let facts = philosophers.items()
                .filterIt(it[1] != "Greece")
                .mapIt([it[0], it[1]])
                .mapIt(Phrase % it)
                .foldIt("", acc & it & '\n')
  doAssert facts == """
Confucius is a famous philosopher from China.
Descartes is a famous philosopher from France.
"""

  # Filter expensive stocks, uppercase names, collect into a HashSet.
  let stocks: Table[string, tuple[symbol: string, price: float]] = {
    "Pineapple": (symbol: "PAPL",  price: 148.32),
    "Foogle":    (symbol: "FOOGL", price: 2750.62),
    "Visla":     (symbol: "VSLA",  price: 609.89),
    "Mehzon":    (symbol: "MHZN",  price: 3271.92),
    "Picohard":  (symbol: "PCHD",  price: 265.51),
  }.toTable()

  let shoutExpensive = stocks.pairs()
                       .mapIt((name: it[0], price: it[1].price))
                       .filterIt(it.price > 1000.0)
                       .mapIt(it.name).map(toUpperAscii)
                       .collect(HashSet[string])
  doAssert shoutExpensive == ["FOOGLE", "MEHZON"].toHashSet()

## Relation to `sequtils`
## ------------------------
##
## `sequtils<sequtils.html>`_ and `itertools` cover similar ground but differ
## in some important ways.
##
## - *Laziness.* Every `sequtils` step that returns a sequence - `map`,
##   `filter`, and the `...It` template variants - allocates immediately.
##   `itertools` adaptors simply construct an iterator, allocation is deferred
##    to the terminal consumer.
##
## - *Typing discipline.* `sequtils` `...It` templates accept `typed` or
##   `untyped` container parameters and work by injecting an `it` variable
##   via textual substitution - a deliberately loose mechanism, but it limits
##   the range of things they can ve applied to. `itertools` templates take
##   `iterable[T]`, so any existing iterator fits and type errors are
##   caught precisely at the point of misuse.
##
## When `sequtils` may be preferable:
##
## * A single one-shot transform on an existing `seq` needs no lazy pipeline.
## * You need `zip`, `unzip`, `deduplicate` which are not (yet) in `itertools`
##
## Adaptors and consumers
## ----------------------
##
## **Adaptors** return a new iterable and can be chained indefinitely:
## `map<#map.t,iterable[T],proc(T)>`_, `mapIt`_, `filter`_, `filterIt`_, `skip`_, `skipWhile`_,
## `skipWhileIt`_, `take`_, `takeWhile`_, `takeWhileIt`_, `stepBy`_,
## `enumerate`_, `group`_, `flatten`_.
##
## **Consumers** drive evaluation and return a plain value:
## `collect<#collect.t,iterable[T],Natural>`_,
## `fold<#fold.t,iterable[T],U,proc(sinkU,T)>`_, `foldIt`_, `sum`_, `product`_, `count`_,
## `min`_, `max`_, `any`_, `anyIt`_, `all`_, `allIt`_,
## `find<#find.t,iterable[T],proc(T)>`_, `findIt<findIt.t,iterable[T]>`_,
## `position<#position.t,iterable[T],proc(T)>`_,
## `positionIt<#positionIt.t,iterable[T],untyped>`_, `nth`_.
##
## Adaptor templates named `...It` inject the `it` symbol in the inner
## scope for the current element. `foldIt` also injects `acc` for the
## running accumulator.
##
## Common patterns
## ---------------
##
## **Collecting into a non-`seq` container**
##
runnableExamples:
  import std/[sets, strutils]
  let upper = ["hello", "world"].items
                .mapIt(it.toUpperAscii)
                .collect(HashSet[string])
  doAssert upper == ["HELLO", "WORLD"].toHashSet()

## **Short-circuiting search across a large range**
##
runnableExamples:
  import std/options
  # stops at 11, never produces elements up to 1_000_000
  doAssert (1..1_000_000).items.findIt(it * it > 100) == some(11)

## **Finding the index of the first match**
##
runnableExamples:
  import std/options
  doAssert ["a", "bb", "ccc"].items.positionIt(it.len > 1) == some(1)

## **Folding into a string**
##
runnableExamples:
  let joined = ["foo", "bar", "baz"].items
                 .filterIt(it != "bar")
                 .foldIt("", acc & it & " ")
  doAssert joined == "foo baz "

## **Grouping elements into fixed-width tuples**
##
## .. Note:: If the element count is not divisible by the group size, the
##    trailing incomplete tuple is silently discarded.
##
runnableExamples:
  doAssert (1..6).items.group(2).collect() == @[(1, 2), (3, 4), (5, 6)]
  # 5 is dropped — cannot form a complete pair:
  doAssert (1..5).items.group(2).collect() == @[(1, 2), (3, 4)]

## **Flattening nested collections**
##
runnableExamples:
  doAssert [@[1, 2], @[3], @[4, 5]].items.flatten().collect() == @[1, 2, 3, 4, 5]

## **Iterating a table**
##
## `Table.pairs` is a valid iterable entry point:
##
runnableExamples:
  import std/[tables, algorithm]
  let t = {"a": 1, "b": 2, "c": 3}.toTable
  let big = t.pairs.filterIt(it[1] > 1).mapIt(it[0]).collect()
  doAssert big.sorted == @["b", "c"]

## Gotchas
## -------
##
## #. Iterators can only be consumed once. Unlike a `seq`, an iterator has no
##    rewind. If you need to traverse the same data more than once,
##    `collect<collect.t,iterable[T],Natural>`_ to a `seq` first and restart
##    from `.items`.
##
## #. `foldIt`_ expects an expression, not a statement. The argument must
##    evaluate to the new accumulated value, which is assigned back to `acc`
##    each iteration. For in-place mutation of `acc` use the
##    `fold<#fold.t,iterable[T],U,proc(varU,T)>`_ overload that takes a
##    `proc(acc: var U; it: T)` instead.
##
## #. Closure iterators are not accepted by `iterable[T]`. A value of type
##    `iterator(): T {.closure.}` does not satisfy the `iterable[T]` type.
##    Only direct inline-iterator calls - including `.items`, `.pairs`, and
##    named iterators such as `countUp` or `split` - work as pipeline sources.
##    If you hold a closure iterator value, wrap it in a helper inline iterator
##    that yields from it to use itertools.
##
## See also
## --------
##
## * `sequtils module<sequtils.html>`_ for eager sequence operations including
##   `zip`, `unzip`, `distribute`, `deduplicate`, `concat`, etc.
## * `sugar module<sugar.html>`_ for the `collect` macro and arrow lambdas (`=>`)
## * `algorithm module<algorithm.html>`_ for sorting and binary search
## * `tables module<tables.html>`_ and `sets module<sets.html>`_ for common
##   target container types accepted by `collect`


import std/[macros, genasts, options]

macro genIter*[T](iter: iterable[T], body: varargs[untyped]): untyped =
  ## Macro for generating templates wrapping iterators.
  ## Takes in optional amount of block statements.
  ## With one block it's assumed to be the body.
  ## With two blocks the first is pre iterator ran code and the second is the body.
  ## With three blocks the last is the post iterator ran code, the second is the body, the first is the pre iterator ran code.

  if body.len == 0:
    error("Expected 1 or 2 arguments passed.", body)
  if body.len > 3:
    error("Too many arguments provided.", body)

  let
    iter =
      if iter.kind != nnkCall:
        iter[^1]
      else:
        iter

    pre =
      case body.len
      of 2, 3:
        body[0]
      else:
        newStmtList()

    post =
      case body.len
      of 3:
        body[^1]
      else:
        newStmtList()

    body =
      case body.len
      of 1:
        body[0]
      of 2, 3:
        body[1]
      else:
        newStmtList()

  result = genast(name = genSym(nskIterator, "name"), call = iter, pre, post, body):
    iterator name(): auto =
      pre
      for it {.inject.} in call:
        body
      post
    name()

type
  Comparable* = concept
    proc `<`(x, y: Self): bool
  Summable* = concept # Additive?
    proc `+`(a, b: Self): Self
  Multipliable* = concept # Multiplicative?
    proc `*`(a, b: Self): Self
  Iterable*[T] = concept
    iterator items(a: Self): T

  Addable*[T] = concept
    proc add(x: var Self; a: T)
  Includable*[T] = concept
    proc incl(x: var Self; a: T)
  Pushable*[T] = concept
    proc push(x: var Self; a: T)

  Growable*[T] = Addable[T] | Includable[T] | Pushable[T]
    ## Matches any mutable container that supports adding elements via
    ## `add`, `incl` or `push`.

  AssociativeContainer*[K, V] = concept
    ## Matches any mutable container that supports key-value assignment via
    ## `[]=`. This includes `Table[K, V]`, `TableRef[K, V]`,
    ## `OrderedTable[K, V]`, `strtabs.StringTableRef`
    ## (with `K = string`, `V = string`), and any user-defined type that
    ## provides a matching `[]=` operator.
    proc `[]=`(x: var Self; key: K; val: V)

#--------------------------------------------------------------------------
# Adaptors
#--------------------------------------------------------------------------

when defined(nimdoc):
  template map*[T; Y](iter: iterable[T]; fn: proc(x: T): Y): untyped =
    ## Transforms elements of the iterator using a mapping function.
    ##
    ## `map` applies the mapping function to each element of the input
    ## iterator, yielding the returned values of that function.
    ##
    runnableExamples:
      let nums = [1, 2, 3, 4, 5]
      assert nums.items.map(proc(x: int): int = x * x).collect() == @[1, 4, 9, 16, 25]
else:
  template map*[T; Y](iter: iterable[T]; fn: proc(x: T): Y): untyped =
    genIter(iter):
      yield fn(it)

when defined(nimdoc):
  template map*[T; Y](iter: iterable[T]; fn: proc(x: T): Y {.inline.}): untyped =
    ## `map<#map.t,iterable[T],proc(T)>`_ overload that allows using inline
    ## procs for the mapping function.
else:
  template map*[T; Y](iter: iterable[T]; fn: proc(x: T): Y {.inline.}): untyped =
    genIter(iter):
      yield fn(it)

when defined(nimdoc):
  template mapIt*[T](iter: iterable[T]; expr: untyped): untyped =
    ## Transforms elements of the iterator using an expression.
    ##
    ## `mapIt` applies the expression `expr` to each element of the input
    ## iterator, yielding the results of the evaluation.
    ##
    runnableExamples:
      let nums = [1, 2, 3, 4, 5]
      assert nums.items.mapIt(it * 2).collect() == @[2, 4, 6, 8, 10]
else:
  template mapIt*[T](iter: iterable[T]; expr: untyped): untyped =
    genIter(iter):
      yield expr

when defined(nimdoc):
  template filter*[T](iter: iterable[T]; pred: proc(x: T): bool): untyped =
    ## Filters elements of the iterator using a predicate function.
    ##
    ## `filter` yields only the elements of the input iterator for which the
    ## predicate function `pred` returns `true`.
    ##
    runnableExamples:
      let nums = [1, 2, 3, 4, 5]
      assert nums.items.filter(proc(x: int): bool = x mod 2 == 0).collect() == @[2, 4]
else:
  template filter*[T](iter: iterable[T]; pred: proc(x: T): bool): untyped =
    genIter(iter):
      if pred(it):
        yield it

when defined(nimdoc):
  template filterIt*[T](iter: iterable[T]; expr: untyped): untyped =
    ## Filters elements of the iterator based on a specified condition.
    ##
    ## `filterIt` yields only the elements of the input iterator for which the
    ## specified expression `expr` evaluates to `true`.
    ##
    runnableExamples:
      let nums = [1, 2, 3, 4, 5]
      assert nums.items.filterIt(it mod 2 == 0).collect() == @[2, 4]
else:
  template filterIt*[T](iter: iterable[T]; expr: untyped): untyped =
    genIter(iter):
      if expr:
        yield it

macro genTuple(typ: untyped; amount: static int): untyped =
  result = nnkPar.newTree()
  for _ in 0..<amount:
    result.add typ

proc set(t: var tuple; ind: int; val: auto) =
  var i = 0
  for field in t.fields:
    if i == ind:
      field = val
    inc i

when defined(nimdoc):
  template group*[T](iter: iterable[T]; amount: static Positive): untyped =
    ## Groups elements of the iterator into tuples of a specified size.
    ##
    ## `group` yields tuples with `amount` elements until all elements from the
    ## input iterator are exhausted.
    ##
    ## .. Note:: If the iterator can't fully fill the tuple, tailing elements are
    ##   discarded
    ##
    runnableExamples:
      let nums = [1, 2, 3, 4, 5, 6]
      assert nums.items.group(3).collect() == @[(1, 2, 3), (4, 5, 6)]
else:
  template group*[T](iter: iterable[T]; amount: static Positive): untyped =
    genIter(iter):
      var
        val: genTuple(T, amount)
        ind = 0
    do:
      val.set(ind mod amount, it)
      if ind mod amount == amount - 1:
        yield val
      inc ind

when defined(nimdoc):
  template skip*[T](iter: iterable[T]; amount: Natural): untyped =
    ## Modifies the iterator to skip a specified number of elements
    ## and yield the rest.
    ##
    ## .. Note:: If the input iterator has fewer than `amount` elements, the
    ## resulting iterator will not produce any elements.
    ##
    runnableExamples:
      let nums = [1, 2, 3, 4, 5]
      assert nums.items.skip(2).collect() == @[3, 4, 5]
else:
  template skip*[T](iter: iterable[T]; amount: Natural): untyped =
    genIter(iter):
      var counter = 0
    do:
      if counter >= amount:
        yield it
      inc counter

when defined(nimdoc):
  template skipWhileIt*[T](iter: iterable[T]; expr: untyped): untyped =
    ## Skips elements of the iterator while the specified expression evaluates to
    ## `true`. Once `expr` returns `false`, all subsequent elements are yielded.
    ##
    runnableExamples:
      let nums = [1, 2, 3, 4, 5]
      assert nums.items.skipWhileIt(it < 3).collect() == @[3, 4, 5]
else:
  template skipWhileIt*[T](iter: iterable[T]; expr: untyped): untyped =
    genIter(iter):
      var skipping = true
    do:
      if skipping:
        skipping = expr
        if skipping:
          continue
      yield it

when defined(nimdoc):
  template skipWhile*[T](iter: iterable[T]; pred: proc(x: T): bool): untyped =
    ## Skips elements of the iterator while the specified predicate function
    ## returns `true`. Once `pred` returns `false`, all subsequent elements
    ## are yielded.
    ##
    runnableExamples:
      let nums = [1, 2, 3, 4, 5]
      assert nums.items.skipWhile(proc(x: int): bool = x < 3).collect() == @[3, 4, 5]
else:
  template skipWhile*[T](iter: iterable[T]; pred: proc(x: T): bool): untyped =
    skipWhileIt(iter, pred(it))

when defined(nimdoc):
  template take*[T](iter: iterable[T]; amount: Natural): untyped =
    ## Modifies the iterator to yield no more than the specified number of elements.
    ##
    ## .. Note:: If the input iterator contains fewer elements than the specified
    ## `amount`, only that number of elements will be yielded.
    ##
    runnableExamples:
      let nums = [1, 2, 3, 4, 5]
      assert nums.items.take(3).collect() == @[1, 2, 3]
else:
  template take*[T](iter: iterable[T]; amount: Natural): untyped =
    genIter(iter):
      var counter = 0
    do:
      if counter >= amount:
        break
      yield it
      inc counter

when defined(nimdoc):
  template takeWhileIt*[T](iter: iterable[T]; expr: untyped): untyped =
    ## Modifies the iterator to yield elements as long as the specified expression
    ## evaluates to `true`.
    ##
    runnableExamples:
      let nums = [1, 2, 3, 4, 5]
      assert nums.items.takeWhileIt(it < 4).collect() == @[1, 2, 3]
else:
  template takeWhileIt*[T](iter: iterable[T]; expr: untyped): untyped =
    genIter(iter):
      if not expr:
        break
      yield it

when defined(nimdoc):
  template takeWhile*[T](iter: iterable[T]; pred: proc(x: T): bool): untyped =
    ## Modifies the iterator to yield elements as long as the specified predicate
    ## function returns `true`.
    ##
    runnableExamples:
      let nums = [1, 2, 3, 4, 5]
      assert nums.items.takeWhile(proc(x: int): bool = x < 4).collect() == @[1, 2, 3]
else:
  template takeWhile*[T](iter: iterable[T]; pred: proc(x: T): bool): untyped =
    takeWhileIt(iter, pred(it))

when defined(nimdoc):
  template stepBy*[T](iter: iterable[T]; step: Positive): untyped =
    ## Modifies the iterator to yield elements stepping by a specified amount.
    ##
    ## The first element is always yielded, regardless of the step given.
    ##
    runnableExamples:
      let nums = [1, 2, 3, 4, 5, 6, 7, 8, 9]
      assert nums.items.stepBy(2).collect() == @[1, 3, 5, 7, 9]
else:
  template stepBy*[T](iter: iterable[T]; step: Positive): untyped =
    genIter(iter):
      var count = step
    do:
      if count == step:
        yield it
        count = 0
      inc count

when defined nimdoc:
  template enumerate*[T](iter: iterable[T]): untyped =
    ## Modifies the iterator to provide the current iteration count and value.
    ##
    ## `enumerate` takes an iterable and yields tuples of (count, element)
    ## of type `(int, T)`.
    ##
    ## .. Note:: The count starts from 0 for the first element.
    ##
    runnableExamples:
      let letters = ["Alpha", "Beta", "Gamma"]
      assert letters.items.enumerate().collect() == @[(0, "Alpha"), (1, "Beta"), (2, "Gamma")]
else:
  template enumerate*[T](iter: iterable[T]): untyped =
    genIter(iter):
      var count = 0
    do:
      yield (count, it)
      inc count

when defined(nimdoc):
  template flatten*[T: Iterable](iter: iterable[T]): untyped =
    ## Flattens nested iterables into a single iterator.
    ##
    ## `flatten` is useful in situations when the initial iterator yields
    ## containers or iterators and it's required to iterate over the elements of
    ## each of them consecutively.
    ##
    runnableExamples:
      let nested = [@[1, 2, 3], @[4, 5], @[6]]
      let flattened = nested.items.flatten().collect()
      assert flattened == @[1, 2, 3, 4, 5, 6]
else:
  template flatten*[T: Iterable](iter: iterable[T]): untyped =
    genIter(iter):
      for inner in it:
        yield inner


#--------------------------------------------------------------------------
# Consumers
#--------------------------------------------------------------------------

template collect*[T](iter: iterable[T]; capacityHint: Natural = 1): seq[T] =
  ## Collects the elements of the iterator into a new sequence.
  ##
  ## For collecting into the user-specified type of container, see
  ## `collect<#collect.t,iterable[T],typedesc[C]>`_.
  ##
  ## .. Note:: `capacityHint` is optional and can be used to provide an initial
  ##   capacity for the sequence.
  ##
  runnableExamples:
    let nums = [1, 2, 3, 4, 5]
    let plusOne = nums.items.mapIt(it + 1).collect()
    assert plusOne == @[2, 3, 4, 5, 6]
  var val = newSeqOfCap[T](capacityHint)
  for x in iter:
    val.add x
  val

template collect*[T; C: Growable[T]](iter: iterable[T]; toType: typeDesc[C]): C =
  ## Collects the elements of the iterator into a new container.
  ##
  ## `collect` creates a new collection and fills it with the first available
  ## proc of `add`, `incl` or `push`. The resulting collection is returned.
  ##
  ## .. Note:: The type `C` should be compatible with the elements in the iterator.
  ##   If `C` is a reference type, a new instance is created. Otherwise, the
  ##   default value of `C` is used.
  ##
  runnableExamples:
    let nums = [1, 2, 3, 4, 5]
    let minusOne = nums.items.mapIt(it - 1).collect(seq[int])
    doAssert minusOne == @[0, 1, 2, 3, 4]

    import std/stats
    let rs = [10.0, 20.0, 30.0].items.collect(RunningStat)
    doAssert rs.sum == 60.0
    doAssert rs.mean == 20.0
  var acc = when C is ref:
      new C
    else:
      default C
  for x in iter:
    when acc is Addable:
      acc.add x
    elif acc is Includable:
      acc.incl x
    elif acc is Pushable:
      acc.push x
  acc

template collect*[K, V; C: AssociativeContainer[K, V]](
    iter: iterable[(K, V)]; toType: typedesc[C]): C =
  ## Collects a `(key, value)` iterator into an associative container.
  ##
  ## Each element yielded by `iter` must be a 2-tuple `(K, V)`.
  ## A fresh instance of `C` is created and populated by assigning each
  ## tuple as `container[key] = value`.
  ##
  ## `C` must satisfy `AssociativeContainer[K, V]<#AssociativeContainer>`_,
  ## meaning it provides ``proc \`[]=\`(c: var C; key: K; val: V)``.
  ## All standard library table types qualify.
  ##
  runnableExamples:
    import std/[tables, strutils]

    # Collect (word, length) pairs into a Table.
    let wordLens = ["one", "two", "three"].items
                     .mapIt((it, it.len))
                     .collect(Table[string, int])
    doAssert wordLens["three"] == 5

    # Build a reverse-lookup table from an enum.
    type Color = enum Red, Green, Blue
    let byName = [Red, Green, Blue].items
                   .mapIt(($it, it))
                   .collect(Table[string, Color])
    doAssert byName["Green"] == Green

    # Collect into an OrderedTable, preserving insertion order.
    import std/algorithm
    let ordered = [(3, "c"), (1, "a"), (2, "b")].items
                    .collect(OrderedTable[int, string])
    doAssert ordered.values.collect() == @["c", "a", "b"]

  var acc = when C is ref: new C else: default(C)
  for (k, v) in iter:
    acc[k]=v
  acc

template fold*[T, U](iter: iterable[T]; init: U; fn: proc(acc: sink U; it: T): U): U =
  ## Accumulates the values of the iterator using an accumulation function `fn`.
  ## This operation is also commonly known as "reduce" and is useful for
  ## producing a single value from a collection.
  ##
  ## `fold` takes an iterable of elements, an initial value `init`, and an
  ## accumulation function `fn`. `acc` is assignerd the return value of `fn`
  ## each iteration. The final value of `acc` is returned.
  ##
  ## .. Note:: `fold` loops through every element of the iterator and thus will not
  ##   terminate for infinite iterators.
  ##
  runnableExamples:
    let nums = [1, 2, 3, 4, 5]
    var sum = nums.items.fold(0, proc(acc: sink int; it: int): int = acc + it)
    assert sum == 15
  var acc: U = init
  for it in iter:
    acc = fn(acc, it)
  acc

template fold*[T, U](iter: iterable[T]; init: U; fn: proc(acc: var U; it: T)): U =
  ## Accumulates the values of the iterator using an accumulation function `fn`.
  ##
  ## See `fold<#fold.t,iterable[T],U,proc(sinkU,T)>`_ for general description.
  ## This version of `fold` requires an accumulation function that
  ## takes the current accumulated value as a var parameter for in-place
  ## modification.
  ##
  runnableExamples:
    let nums = [1, 2, 3, 4, 5]
    var product = nums.items.fold(1, proc(acc: var int; it: int) = acc *= it)
    assert product == 120
  var acc: U = init
  for it in iter:
    fn(acc, it)
  acc

template foldIt*[T, U](iter: iterable[T]; init: U; expr: untyped): U =
  ## Accumulates the values of the iterator using an expression.
  ##
  ## `foldIt` takes an iterable of elements, an initial value `init`, and an
  ## expression that updates tje value of the accumulating variable `acc`
  ## each iteration. The final value of `acc` is returned.
  ##
  ## .. Note:: `expr` should assign the updated accumulated value to the `acc` variable.
  ##
  runnableExamples:
    let nums = [1, 2, 3, 4, 5]
    var sum = nums.items.foldIt(1, acc + it)
    assert sum == 16
  block:
    var acc {.inject.}: U = init
    for it {.inject.} in iter:
      acc = expr
    acc

template selectByCmp[T: Comparable](iter: iterable[T]; expr: untyped): T =
  var
    requiresInit = true
    acc {.inject.}: T
  for it {.inject.} in iter:
    if unlikely(requiresInit):
      acc = it
      requiresInit = false
    if expr:
      acc = it
  acc

template min*[T: Comparable](iter: iterable[T]): T =
  ## Finds the minimum element in the iterator.
  ##
  ## `min` takes an iterable of elements that support comparison (satisfy the
  ## `Comparable` concept) and returns the minimal element.
  ##
  runnableExamples:
    let nums = [5, 2, 8, 1, 9]
    assert nums.items.min() == 1
  selectByCmp(iter, it < acc)

template max*[T: Comparable](iter: iterable[T]): T =
  ## Finds the maximum element in the iterator.
  ##
  ## `max` takes an iterable of elements that support comparison (satisfy the
  ## `Comparable`_ concept) and returns the maximal element.
  ##
  runnableExamples:
    let nums = [5, 2, 8, 1, 9]
    assert nums.items.max() == 9
  selectByCmp(iter, acc < it)

template count*[T](iter: iterable[T]): Natural =
  ## Counts the number of yielded elements in the iterator.
  ##
  ## .. Note:: The count iterates through and discards all elements of the iterator.
  ##
  runnableExamples:
    let nums = [1, 2, 3, 4, 5]
    assert nums.items.count() == 5
  iter.foldIt(0, acc+1)

template sum*[T: Summable](iter: iterable[T]): T =
  ## Calculates the sum of all yielded elements in the iterator.
  ##
  ## `sum` takes an iterable of elements that support addition
  ## (satisfy the `Summable`_ concept) and returns their sum.
  ##
  ## .. Note:: An empty iterator returns the default value for the type `T`.
  ##
  runnableExamples:
    let nums = [1, 2, 3, 4, 5]
    assert nums.items.sum() == 15
  iter.foldIt(default(typeOf(T)), acc + it)

template product*[T: Multipliable](iter: iterable[T]): T =
  ## Calculates the product of all elements in the iterator.
  ##
  ## `product` takes an iterable of elements that support multiplication
  ## (satisfy the `Multipliable`_ concept) and returns their product.
  ##
  ## .. Note:: An empty iterator returns the default value for the type `T`.
  ##
  runnableExamples:
    let nums = [1, 2, 3, 4, 5]
    assert nums.items.product() == 120
  var
    requiresInit = true
    acc: T
  for it in iter:
    if unlikely(requiresInit):
      acc = it
      requiresInit = false
      continue
    acc = acc * it
  acc

template anyIt*[T](iter: iterable[T]; expr: untyped): bool =
  ## Checks at least for one element of the iterator the `expr`
  ## expression evaluates to `true`.
  ##
  ## `anyIt` is short-circuiting; it will stop
  ## as soon as it encounters `true`. An empty iterator returns `false`.
  ##
  runnableExamples:
    let nums = [1, 2, 3, 4, 5]
    assert nums.items.anyIt(it > 3)
    assert "".items.anyIt(it is char) == false
  var result = false
  for it {.inject.} in iter:
    if expr:
      result = true
      break
  result

template any*[T](iter: iterable[T]; pred: proc(x: T): bool): bool =
  ## Checks if for at least one element of the iterator the specified predicate
  ## function `pred` returns `true`.
  ##
  ## `any` is short-circuiting; it will stop
  ## as soon as `pred` returns `true`. An empty iterator returns `false`.
  ##
  runnableExamples:
    let nums = @[1, 2, 3, 4, 5]
    assert nums.items.any(proc(x: int): bool = x > 3) == true
  anyIt(iter, pred(it))

template allIt*[T](iter: iterable[T]; expr: untyped): bool =
  ## Checks if for every iteration the expression evaluates to `true`.
  ##
  ## `allIt` is short-circuiting; it will stop
  ## as soon as it encounters `false`. An empty iterator returns `true`.
  ##
  runnableExamples:
    let nums = [1, 2, 3, 4, 5]
    assert nums.items.allIt(it < 10) == true
    assert "".items.allIt(it == '!') == true
  var result = true
  for it {.inject.} in iter:
    if not (expr):
      result = false
      break
  result

template all*[T](iter: iterable[T]; pred: proc(x: T): bool): bool =
  ## Checks if for every iteration the specified predicate function returns
  ## true.
  ##
  ## `all` is short-circuiting; it will stop as soon as `pred`
  ##  returns `false`. An empty iterator returns `true`.
  ##
  runnableExamples:
    let nums = [1, 2, 3, 4, 5]
    assert nums.items.all(proc(x: int): bool = x < 10) == true
    assert "".items.all(proc(x: char): bool = x == '!') == true
  allIt(iter, pred(it))

template findIt*[T](iter: iterable[T]; expr: untyped): Option[T] =
  ## Searches for the first element in the iterator for which the specified
  ## expression evaluates to `true`. `none` is returned if such an element is
  ## not found (every expression evaluates to `false`).
  ##
  ## If you need the index of the element, see
  ## `positionIt<#positionIt.t,iterable[T],untyped>`_.
  ##
  ## .. Note:: `findIt` is short-circuiting; it will stop
  ##   iterating as soon as expression `expr` returns true.
  ##
  runnableExamples:
    import std/options
    let nums = [1, 2, 3, 4, 5]
    assert nums.items.findIt(it == 3) == some(3)
  var result = none(typeOf(T))
  for it {.inject.} in iter:
    if expr:
      result = some(it)
      break
  result


template positionIt*[T](iter: iterable[T]; expr: untyped): Option[int] =
  ## Searches for the index of the first element in the iterator for which the
  ## specified expression evaluates to `true`. `none` is returned if such an
  ## element is not found (every expression evaluates to `false`).
  ##
  ## If you need to find the element itself, see
  ## `findIt<#findIt.t,iterable[T],untyped>`_.
  ##
  ## .. Note:: `positionIt` is short-circuiting; it will stop
  ##   iterating as soon as expression `expr` evaluates to true.
  ##
  runnableExamples:
    import std/options
    let nums = [1, 2, 3, 4, 5]
    assert nums.items.positionIt(it == 3) == some(2)
  var
    position = none(int)
    counter = 0
  for it {.inject.} in iter:
    if expr:
      position = some(counter)
      break
    inc(counter)
  position

template position*[T](iter: iterable[T]; pred: proc(x: T): bool): Option[int] =
  ## Searches for the index of the first element in the iterator for which the
  ## specified predicate function returns `true`. `none` is returned if such an
  ## element is not found (every predicate returns `false`).
  ##
  ## If you need to find the element itself, see
  ## `find<#find.t,iterable[T],proc(T)>`_.
  ##
  ## .. Note:: `position` is short-circuiting; it will stop
  ##   iterating as soon as the predicate returns `true`.
  ##
  runnableExamples:
    import std/options
    let nums = [1, 2, 3, 4, 5]
    assert nums.items.position(proc(x: int): bool = x == 3) == some(2)
  positionIt(iter, pred(it))

template find*[T](iter: iterable[T]; pred: proc(x: T): bool): Option[T] =
  ## Searches for the first element in the iterator that satisfies the specified
  ## predicate function. If no element satisfies the predicate, `none` is returned.
  ##
  ## If you need the index of the element, see
  ## `position<#position.t,iterable[T],proc(T)>`_.
  ##
  ## .. Note:: `find` is short-circuiting; it will stop
  ##   iterating as soon as `pred` evaluates to true.
  ##
  runnableExamples:
    import std/options
    let nums = @[1, 2, 3, 4, 5]
    assert nums.items.find(proc(x: int): bool = x > 3) == some(4)
  findIt(iter, pred(it))


template nth*[T](iter: iterable[T]; n: Natural): Option[T] =
  ## Returns the nth element of the iterator.
  ## If `n` is greater than or equal to the number of iterator elements, returns
  ## `none`.
  ##
  ## Like most indexing operations, the count starts from zero, so
  ## `nth(0)` returns the first value, `nth(1)` the second, and so on.
  ##
  ## .. Note:: This adaptor consumes the iterator and discards all of
  ##   the preceding elements.
  ##
  runnableExamples:
    import std/options

    let nums = [1, 2, 3, 4, 5]
    let thirdElement = nums.items.nth(2)
    assert thirdElement == some(3)
    let sixthElement = nums.items.nth(5)
    assert sixthElement.isNone()
  var
    result = none(typeOf(T))
    counter = 0
  for it in iter:
    if counter == n:
      result = some(it)
      break
    inc counter
  result
