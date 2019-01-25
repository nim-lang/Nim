discard """
  target: "c"
  output: '''
1 3 6 11 20 foo
foo88
23 24foo 88
18
18
99
99
99
99 99
99 99
12 99 99
12 99 99
success
@[1, 2, 5]
click at 10,20
lost focus 1
lost focus 2
registered handler for UserEvent 1
registered handler for UserEvent 2
registered handler for UserEvent 3
registered handler for UserEvent 4
asdas
processClient end
false
baro0
foo88
23 24foo 88
foo88
23 24foo 88
11
@[1, 10, 45, 120, 210, 252, 210, 120, 45, 10, 1]
'''
joinable: false
"""


block tclosure:
  proc map(n: var openarray[int], fn: proc (x: int): int {.closure}) =
    for i in 0..n.len-1: n[i] = fn(n[i])

  proc foldr(n: openarray[int], fn: proc (x, y: int): int {.closure}): int =
    for i in 0..n.len-1:
      result = fn(result, n[i])

  proc each(n: openarray[int], fn: proc(x: int) {.closure.}) =
    for i in 0..n.len-1:
      fn(n[i])

  var myData: array[0..4, int] = [0, 1, 2, 3, 4]

  proc testA() =
    var p = 0
    map(myData, proc (x: int): int =
                  result = x + 1 shl (proc (y: int): int =
                    return y + p
                  )(0)
                  inc(p))

  testA()

  myData.each do (x: int):
    write(stdout, x)
    write(stdout, " ")

  #OUT 2 4 6 8 10

  type
    ITest = tuple[
      setter: proc(v: int),
      getter: proc(): int]

  proc getInterf(): ITest =
    var shared: int

    return (setter: proc (x: int) = shared = x,
            getter: proc (): int = return shared)


  # bug #5015

  type Mutator = proc(matched: string): string {.noSideEffect, gcsafe, locks: 0.}

  proc putMutated(
      MutatorCount: static[int],
      mTable: static[array[MutatorCount, Mutator]], input: string) =
    for i in 0..<MutatorCount: echo mTable[i](input)

  proc mutator0(matched: string): string =
      "foo"

  const
    mTable = [Mutator(mutator0)]

  putMutated(1, mTable, "foo")



block tclosure0:
  when true:
    # test simple closure within dummy 'main':
    proc dummy =
      proc main2(param: int) =
        var fooB = 23
        proc outer(outerParam: string) =
          var outerVar = 88
          echo outerParam, outerVar
          proc inner() =
            block Test:
              echo fooB, " ", param, outerParam, " ", outerVar
          inner()
        outer("foo")
      main2(24)

    dummy()

  when true:
    proc outer2(x:int) : proc(y:int):int =   # curry-ed application
        return proc(y:int):int = x*y

    var fn = outer2(6)  # the closure
    echo fn(3)   # it works

    var rawP = fn.rawProc()
    var rawE = fn.rawEnv()

    # A type to cast the function pointer into a nimcall
    type TimesClosure = proc(a: int, x: pointer): int {.nimcall.}

    # Call the function with its closure
    echo cast[TimesClosure](rawP)(3, rawE)

  when true:
    proc outer =
      var x, y: int = 99
      proc innerA = echo x
      proc innerB =
        echo y
        innerA()

      innerA()
      innerB()

    outer()

  when true:
    proc indirectDep =
      var x, y: int = 99
      proc innerA = echo x, " ", y
      proc innerB =
        innerA()

      innerA()
      innerB()

    indirectDep()

  when true:
    proc needlessIndirection =
      var x, y: int = 99
      proc indirection =
        var z = 12
        proc innerA = echo z, " ", x, " ", y
        proc innerB =
          innerA()

        innerA()
        innerB()
      indirection()

    needlessIndirection()






block tclosure3:
  proc main =
    const n = 30
    for iterations in 0..50_000:
      var s: seq[proc(): string {.closure.}] = @[]
      for i in 0 .. n-1:
        (proc () =
          let ii = i
          s.add(proc(): string = return $(ii*ii)))()
      for i in 0 .. n-1:
        let val = s[i]()
        if val != $(i*i): echo "bug  ", val

      if getOccupiedMem() > 5000_000: quit("still a leak!")
    echo "success"

  main()



import json, tables, sequtils
block tclosure4:
  proc run(json_params: OrderedTable) =
    let json_elems = json_params["files"].elems
    # These fail compilation.
    var files = map(json_elems, proc (x: JsonNode): string = x.str)
    #var files = json_elems.map do (x: JsonNode) -> string: x.str

  let text = """{"files": ["a", "b", "c"]}"""
  run((text.parseJson).fields)



import hashes, math
block tclosurebug2:
  type
    TSlotEnum = enum seEmpty, seFilled, seDeleted
    TKeyValuePair[A, B] = tuple[slot: TSlotEnum, key: A, val: B]
    TKeyValuePairSeq[A, B] = seq[TKeyValuePair[A, B]]

    TOrderedKeyValuePair[A, B] = tuple[
      slot: TSlotEnum, next: int, key: A, val: B]
    TOrderedKeyValuePairSeq[A, B] = seq[TOrderedKeyValuePair[A, B]]
    OrderedTable[A, B] = object ## table that remembers insertion order
      data: TOrderedKeyValuePairSeq[A, B]
      counter, first, last: int

  const
    growthFactor = 2

  proc mustRehash(length, counter: int): bool {.inline.} =
    assert(length > counter)
    result = (length * 2 < counter * 3) or (length - counter < 4)

  proc nextTry(h, maxHash: Hash): Hash {.inline.} =
    result = ((5 * h) + 1) and maxHash

  template rawGetImpl() {.dirty.} =
    var h: Hash = hash(key) and high(t.data) # start with real hash value
    while t.data[h].slot != seEmpty:
      if t.data[h].key == key and t.data[h].slot == seFilled:
        return h
      h = nextTry(h, high(t.data))
    result = -1

  template rawInsertImpl() {.dirty.} =
    var h: Hash = hash(key) and high(data)
    while data[h].slot == seFilled:
      h = nextTry(h, high(data))
    data[h].key = key
    data[h].val = val
    data[h].slot = seFilled

  template addImpl() {.dirty.} =
    if mustRehash(len(t.data), t.counter): enlarge(t)
    rawInsert(t, t.data, key, val)
    inc(t.counter)

  template putImpl() {.dirty.} =
    var index = rawGet(t, key)
    if index >= 0:
      t.data[index].val = val
    else:
      addImpl()

  proc len[A, B](t: OrderedTable[A, B]): int {.inline.} =
    ## returns the number of keys in `t`.
    result = t.counter

  template forAllOrderedPairs(yieldStmt: untyped) {.dirty.} =
    var h = t.first
    while h >= 0:
      var nxt = t.data[h].next
      if t.data[h].slot == seFilled: yieldStmt
      h = nxt

  iterator pairs[A, B](t: OrderedTable[A, B]): tuple[key: A, val: B] =
    ## iterates over any (key, value) pair in the table `t` in insertion
    ## order.
    forAllOrderedPairs:
      yield (t.data[h].key, t.data[h].val)

  iterator mpairs[A, B](t: var OrderedTable[A, B]): tuple[key: A, val: var B] =
    ## iterates over any (key, value) pair in the table `t` in insertion
    ## order. The values can be modified.
    forAllOrderedPairs:
      yield (t.data[h].key, t.data[h].val)

  iterator keys[A, B](t: OrderedTable[A, B]): A =
    ## iterates over any key in the table `t` in insertion order.
    forAllOrderedPairs:
      yield t.data[h].key

  iterator values[A, B](t: OrderedTable[A, B]): B =
    ## iterates over any value in the table `t` in insertion order.
    forAllOrderedPairs:
      yield t.data[h].val

  iterator mvalues[A, B](t: var OrderedTable[A, B]): var B =
    ## iterates over any value in the table `t` in insertion order. The values
    ## can be modified.
    forAllOrderedPairs:
      yield t.data[h].val

  proc rawGet[A, B](t: OrderedTable[A, B], key: A): int =
    rawGetImpl()

  proc `[]`[A, B](t: OrderedTable[A, B], key: A): B =
    ## retrieves the value at ``t[key]``. If `key` is not in `t`,
    ## default empty value for the type `B` is returned
    ## and no exception is raised. One can check with ``hasKey`` whether the key
    ## exists.
    var index = rawGet(t, key)
    if index >= 0: result = t.data[index].val

  proc mget[A, B](t: var OrderedTable[A, B], key: A): var B =
    ## retrieves the value at ``t[key]``. The value can be modified.
    ## If `key` is not in `t`, the ``EInvalidKey`` exception is raised.
    var index = rawGet(t, key)
    if index >= 0: result = t.data[index].val
    else: raise newException(KeyError, "key not found: " & $key)

  proc hasKey[A, B](t: OrderedTable[A, B], key: A): bool =
    ## returns true iff `key` is in the table `t`.
    result = rawGet(t, key) >= 0

  proc rawInsert[A, B](t: var OrderedTable[A, B],
                      data: var TOrderedKeyValuePairSeq[A, B],
                      key: A, val: B) =
    rawInsertImpl()
    data[h].next = -1
    if t.first < 0: t.first = h
    if t.last >= 0: data[t.last].next = h
    t.last = h

  proc enlarge[A, B](t: var OrderedTable[A, B]) =
    var n: TOrderedKeyValuePairSeq[A, B]
    newSeq(n, len(t.data) * growthFactor)
    var h = t.first
    t.first = -1
    t.last = -1
    while h >= 0:
      var nxt = t.data[h].next
      if t.data[h].slot == seFilled:
        rawInsert(t, n, t.data[h].key, t.data[h].val)
      h = nxt
    swap(t.data, n)

  proc `[]=`[A, B](t: var OrderedTable[A, B], key: A, val: B) =
    ## puts a (key, value)-pair into `t`.
    putImpl()

  proc add[A, B](t: var OrderedTable[A, B], key: A, val: B) =
    ## puts a new (key, value)-pair into `t` even if ``t[key]`` already exists.
    addImpl()

  proc iniOrderedTable[A, B](initialSize=64): OrderedTable[A, B] =
    ## creates a new ordered hash table that is empty. `initialSize` needs to be
    ## a power of two.
    assert isPowerOfTwo(initialSize)
    result.counter = 0
    result.first = -1
    result.last = -1
    newSeq(result.data, initialSize)

  proc toOrderedTable[A, B](pairs: openarray[tuple[key: A,
                            val: B]]): OrderedTable[A, B] =
    ## creates a new ordered hash table that contains the given `pairs`.
    result = iniOrderedTable[A, B](nextPowerOfTwo(pairs.len+10))
    for key, val in items(pairs): result[key] = val

  proc sort[A, B](t: var OrderedTable[A,B],
                  cmp: proc (x, y: tuple[key: A, val: B]): int {.closure.}) =
    ## sorts the ordered table so that the entry with the highest counter comes
    ## first. This is destructive (with the advantage of being efficient)!
    ## You must not modify `t` afterwards!
    ## You can use the iterators `pairs`,  `keys`, and `values` to iterate over
    ## `t` in the sorted order.

    # we use shellsort here; fast enough and simple
    var h = 1
    while true:
      h = 3 * h + 1
      if h >= high(t.data): break
    while true:
      h = h div 3
      for i in countup(h, high(t.data)):
        var j = i
        #echo(t.data.len, " ", j, " - ", h)
        #echo(repr(t.data[j-h]))
        proc rawCmp(x, y: TOrderedKeyValuePair[A, B]): int =
          if x.slot in {seEmpty, seDeleted} and y.slot in {seEmpty, seDeleted}:
            return 0
          elif x.slot in {seEmpty, seDeleted}:
            return -1
          elif y.slot in {seEmpty, seDeleted}:
            return 1
          else:
            let item1 = (x.key, x.val)
            let item2 = (y.key, y.val)
            return cmp(item1, item2)

        while rawCmp(t.data[j-h], t.data[j]) <= 0:
          swap(t.data[j], t.data[j-h])
          j = j-h
          if j < h: break
      if h == 1: break



import sugar
block inference3304:
  type
    List[T] = ref object
      val: T

  proc foo[T](l: List[T]): seq[int] =
    @[1,2,3,5].filter(x => x != l.val)

  echo(foo(List[int](val: 3)))



block tcodegenerr1923:
  type
    Foo[M] = proc() : M

  proc bar[M](f : Foo[M]) =
    discard f()

  proc baz() : int = 42

  bar(baz)



block doNotation:
  type
    Button = object
    Event = object
      x, y: int

  proc onClick(x: Button, handler: proc(x: Event)) =
    handler(Event(x: 10, y: 20))

  proc onFocusLost(x: Button, handler: proc()) =
    handler()

  proc onUserEvent(x: Button, eventName: string, handler: proc) =
    echo "registered handler for ", eventName

  var b = Button()

  b.onClick do (e: Event):
    echo "click at ", e.x, ",", e.y

  b.onFocusLost:
    echo "lost focus 1"

  b.onFocusLost do:
    echo "lost focus 2"

  b.onUserEvent("UserEvent 1") do:
    discard

  b.onUserEvent "UserEvent 2":
    discard

  b.onUserEvent("UserEvent 3"):
    discard

  b.onUserEvent("UserEvent 4", () => echo "event 4")



import tables
block fib50:
  proc memoize(f: proc (a: int64): int64): proc (a: int64): int64 =
      var previous = initTable[int64, int64]()
      return proc(i: int64): int64 =
          if not previous.hasKey i:
              previous[i] = f(i)
          return previous[i]

  var fib: proc(a: int64): int64

  fib = memoize(proc (i: int64): int64 =
      if i == 0 or i == 1:
          return 1
      return fib(i-1) + fib(i-2)
  )

  doAssert fib(50) == 20365011074



block tflatmap:
  # bug #3995
  type
    RNG = tuple[]
    Rand[A] = (RNG) -> (A, RNG)

  proc nextInt(r: RNG): (int, RNG) =
    (1, ())

  proc flatMap[A,B](f: Rand[A], g: A -> Rand[B]): Rand[B] =
    (rng: RNG) => (
      let (a, rng2) = f(rng);
      let g1 = g(a);
      g1(rng2)
    )

  proc map[A,B](s: Rand[A], f: A -> B): Rand[B] =
    let g: A -> Rand[B] = (a: A) => ((rng: RNG) => (f(a), rng))
    flatMap(s, g)

  let f = nextInt.map(i => i - i mod 2)



block tforum:
  type
    PAsyncHttpServer = ref object
      value: string
    PFutureBase = ref object
      callback: proc () {.closure.}
      value: string
      failed: bool

  proc accept(server: PAsyncHttpServer): PFutureBase =
    new(result)
    result.callback = proc () =
      discard
    server.value = "hahaha"

  proc processClient(): PFutureBase =
    new(result)

  proc serve(server: PAsyncHttpServer): PFutureBase =
    iterator serveIter(): PFutureBase {.closure.} =
      echo server.value
      while true:
        var acceptAddrFut = server.accept()
        yield acceptAddrFut
        var fut = acceptAddrFut.value

        var f = processClient()
        f.callback =
          proc () =
            echo("processClient end")
            echo(f.failed)
        yield f
    var x = serveIter
    for i in 0 .. 1:
      result = x()
      result.callback()

  discard serve(PAsyncHttpServer(value: "asdas"))



block futclosure2138:
  proc any[T](list: varargs[T], pred: (T) -> bool): bool =
    for item in list:
        if pred(item):
            result = true
            break

  proc contains(s: string, words: varargs[string]): bool =
    any(words, (word) => s.contains(word))



block tinterf:
  type
    ITest = tuple[
      setter: proc(v: int) {.closure.},
      getter1: proc(): int {.closure.},
      getter2: proc(): int {.closure.}]

  proc getInterf(): ITest =
    var shared1, shared2: int

    return (setter: proc (x: int) =
              shared1 = x
              shared2 = x + 10,
            getter1: proc (): int = result = shared1,
            getter2: proc (): int = return shared2)

  var i = getInterf()
  i.setter(56)

  doAssert i.getter1() == 56
  doAssert i.getter2() == 66



block tjester:
  type
    Future[T] = ref object
      data: T
      callback: proc () {.closure.}

  proc cbOuter(response: string) {.discardable.} =
    iterator cbIter(): Future[int] {.closure.} =
      for i in 0..7:
        proc foo(): int =
          iterator fooIter(): Future[int] {.closure.} =
            echo response, i
            yield Future[int](data: 17)
          var iterVar = fooIter
          iterVar().data
        yield Future[int](data: foo())

    var iterVar2 = cbIter
    proc cb2() {.closure.} =
      try:
        if not finished(iterVar2):
          let next = iterVar2()
          if next != nil:
            next.callback = cb2
      except:
        echo "WTF"
    cb2()

  cbOuter "baro"



block tnamedparamanonproc:
  type
    PButton = ref object
    TButtonClicked = proc(button: PButton) {.nimcall.}

  proc newButton(onClick: TButtonClicked) =
    discard

  proc main() =
    newButton(onClick = proc(b: PButton) =
      var requestomat = 12
      )

  main()



block tnestedclosure:
  proc main(param: int) =
    var foo = 23
    proc outer(outerParam: string) =
      var outerVar = 88
      echo outerParam, outerVar
      proc inner() =
        block Test:
          echo foo, " ", param, outerParam, " ", outerVar
      inner()
    outer("foo")

  # test simple closure within dummy 'main':
  proc dummy =
    proc main2(param: int) =
      var fooB = 23
      proc outer(outerParam: string) =
        var outerVar = 88
        echo outerParam, outerVar
        proc inner() =
          block Test:
            echo fooB, " ", param, outerParam, " ", outerVar
        inner()
      outer("foo")
    main2(24)

  dummy()

  main(24)

  # Jester + async triggered this bug:
  proc cbOuter() =
    var response = "hohoho"
    block:
      proc cbIter() =
        block:
          proc fooIter() =
            doAssert response == "hohoho"
          fooIter()
      cbIter()
  cbOuter()



block tnestedproc:
  proc p(x, y: int): int =
    result = x + y

  echo p((proc (): int =
            var x = 7
            return x)(),
         (proc (): int = return 4)())



block tnoclosure:
  proc pascal(n: int) =
    var row = @[1]
    for r in 1..n:
      row = zip(row & @[0], @[0] & row).mapIt(it[0] + it[1])
    echo row
  pascal(10)
