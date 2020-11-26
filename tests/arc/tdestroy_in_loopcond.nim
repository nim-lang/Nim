discard """
  output: '''400 true'''
  cmd: "nim c --gc:orc $file"
"""

type HeapQueue*[T] = object
  data: seq[T]


proc len*[T](heap: HeapQueue[T]): int {.inline.} =
  heap.data.len

proc `[]`*[T](heap: HeapQueue[T], i: Natural): T {.inline.} =
  heap.data[i]

proc push*[T](heap: var HeapQueue[T], item: T) =
  heap.data.add(item)

proc pop*[T](heap: var HeapQueue[T]): T =
  result = heap.data.pop

proc clear*[T](heap: var HeapQueue[T]) = heap.data.setLen 0


type
  Future = ref object of RootObj
    s: string
    callme: proc()

var called = 0

proc consume(f: Future) =
  inc called

proc newFuture(s: string): Future =
  var r: Future
  r = Future(s: s, callme: proc() =
    consume r)
  result = r

var q: HeapQueue[tuple[finishAt: int64, fut: Future]]

proc sleep(f: int64): Future =
  q.push (finishAt: f, fut: newFuture("async-sleep"))

proc processTimers =
  # Pop the timers in the order in which they will expire (smaller `finishAt`).
  var count = q.len
  let t = high(int64)
  while count > 0 and t >= q[0].finishAt:
    q.pop().fut.callme()
    dec count

var futures: seq[Future]

proc main =
  for i in 1..200:
    futures.add sleep(56020904056300)
    futures.add sleep(56020804337500)
    #futures.add sleep(2.0)

    #futures.add sleep(4.0)

    processTimers()
    #q.pop()[1].callme()
    #q.pop()[1].callme()

    futures.setLen 0

  q.clear()

main()
GC_fullCollect()
echo called, " ", getOccupiedMem() < 160




when false:
  include prelude

  type
    Callback* = proc (fd: int): bool {.closure, gcsafe.}

    AsyncData = object
      readList: seq[Callback]
      writeList: seq[Callback]

    Dispatcher* = ref object of RootObj
      selector: Table[string, AsyncData]

  proc factoryA(input: string): Callback =
    var s = "abc"
    s.add input

    result = proc (fd: int): bool =
      echo s
      result = false

  proc factoryB(input: string): Callback =
    var s = newSeq[string](0)
    s.add "xyz"
    s.add input

    result = proc (fd: int): bool =
      echo s
      result = false

  proc main =
    var d = Dispatcher(selector: initTable[string, AsyncData]())
    for i in 0..1000:
      d.selector[$i] = AsyncData(readList: @[factoryA("a" & $i)], writeList: @[factoryB("b" & $i)])

    for i in 0..1000:
      let ii = $i
      let xZZ = d.selector[ii] # must be cursor!

      let rd = AsyncData().readList # move d.selector[ii].readList
      var addback = newSeq[Callback]()
      for y in rd:
        discard y(i)
        if i mod 4 == 0:
          addback.add y

      #d.selector[ii].readList = addback

      for y in xZZ.writeList:
        discard y(i)

  main()
  GC_fullCollect()
  echo formatSize getOccupiedMem()


when false:
  iterator it(): int {.closure.} =
    var i = 5
    while i != 0:
      yield i
      if i == 3:
        yield 123
      dec i

  for x in it():
    echo x
  # test(it, 5, 4, 3, 123, 2, 1)
