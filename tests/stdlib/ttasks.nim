import std/[tasks, strformat]

block:
  block:
    proc hello(x: static range[1 .. 5]) =
      echo x

    let b = toTask hello(3)
    b.invoke()
    b.invoke()

  block:
    proc hello(x: range[1 .. 5]) =
      echo x

    let b = toTask hello(3)
    b.invoke()
    b.invoke()

  block:
    proc hello(x: 1 .. 5) =
      echo x

    let b = toTask hello(3)
    b.invoke()
    b.invoke()

  block:
    proc hello(a: int or seq[string]) =
      echo a

    let x = @["1", "2", "3", "4"]
    let b = toTask hello(x)
    b.invoke()
    b.invoke()


  block:
    proc hello(a: int or string) =
      echo a

    let x = "!2"

    let b = toTask hello(x)
    b.invoke()

  block:
    proc hello(a: int or string) =
      echo a

    let x = "!2"
    let b = toTask hello(x)
    b.invoke()


  block:
    proc hello(a: int or string) =
      echo a

    let x = "!2"
    let b = toTask hello(x)
    b.invoke()

  block:
    proc hello(typ: typedesc) =
      echo typ(12)

    let b = toTask hello(int)
    b.invoke()

  block:
    proc hello(typ: typedesc) =
      echo typ(12)

    let b = toTask hello(int)
    b.invoke()

  block:
    proc hello(a: int or seq[string]) =
      echo a

    let x = @["1", "2", "3", "4"]
    let b = toTask hello(x)
    b.invoke()

  block:
    proc hello(a: int or string) =
      echo a

    let x = "!2"
    let b = toTask hello(x)
    b.invoke()


  block:
    proc hello(a: int or string) =
      echo a

    let b = toTask hello(12)
    b.invoke()

  block:
    proc hello(c: seq[int], a: int) =
      echo a
      echo c

    let x = 12
    var y = @[1, 3, 1, 4, 5, x, 1]
    let b = toTask hello(y, 12)
    b.invoke()

  block:
    proc hello(c: seq[int], a: int) =
      echo a
      echo c

    var x = 2
    let b = toTask hello(@[1, 3, 1, 4, 5, x, 1], 12)
    b.invoke()

  block:
    proc hello(c: array[7, int], a: int) =
      echo a
      echo c

    let b = toTask hello([1, 3, 1, 4, 5, 2, 1], 12)
    b.invoke()

  block:
    proc hello(c: seq[int], a: int) =
      echo a
      echo c

    let b = toTask hello(@[1, 3, 1, 4, 5, 2, 1], 12)
    b.invoke()

  block:
    proc hello(a: int, c: seq[int]) =
      echo a
      echo c

    let b = toTask hello(8, @[1, 3, 1, 4, 5, 2, 1])
    b.invoke()

    let c = toTask 8.hello(@[1, 3, 1, 4, 5, 2, 1])
    c.invoke()


  block:
    proc hello(a: int, c: openArray[seq[int]]) =
      echo a
      echo c

    let b = toTask hello(8, @[@[3], @[4], @[5], @[6], @[12], @[7]])
    b.invoke()

  block:
    proc hello(a: int, c: openArray[int]) =
      echo a
      echo c

    let b = toTask hello(8, @[3, 4, 5, 6, 12, 7])
    b.invoke()

  block:
    proc hello(a: int, c: static varargs[int]) =
      echo a
      echo c

    let b = toTask hello(8, @[3, 4, 5, 6, 12, 7])
    b.invoke()

  block:
    proc hello(a: int, c: static varargs[int]) =
      echo a
      echo c

    let b = toTask hello(8, [3, 4, 5, 6, 12, 7])
    b.invoke()

  block:
    proc hello(a: int, c: varargs[int]) =
      echo a
      echo c

    let x = 12
    let b = toTask hello(8, 3, 4, 5, 6, x, 7)
    b.invoke()

  block:
    var x = 12

    proc hello(x: ptr int) =
      echo x[]

    let b = toTask hello(addr x)
    b.invoke()

    let c = toTask x.addr.hello
    invoke(c)
  block:
    type
      Test = ref object
        id: int
    proc hello(a: int, c: static Test) =
      echo a

    let b = toTask hello(8, Test(id: 12))
    b.invoke()

  block:
    type
      Test = object
        id: int
    proc hello(a: int, c: static Test) =
      echo a

    let b = toTask hello(8, Test(id: 12))
    b.invoke()

  block:
    proc hello(a: int, c: static seq[int]) =
      echo a

    let b = toTask hello(8, @[3, 4, 5, 6, 12, 7])
    b.invoke()

  block:
    proc hello(a: int, c: static array[5, int]) =
      echo a

    let b = toTask hello(8, [3, 4, 5, 6, 12])
    b.invoke()

  block:
    var aVal = 0
    var cVal = ""

    proc hello(a: int, c: static string) =
      aVal += a
      cVal.add c

    var x = 1314
    let b = toTask hello(x, "hello")
    b.invoke()

    doAssert aVal == x
    doAssert cVal == "hello"

  block:
    var aVal = ""

    proc hello(a: static string) =
      aVal.add a
    let b = toTask hello("hello")
    b.invoke()

    doAssert aVal == "hello"

  block:
    var aVal = 0
    var cVal = ""

    proc hello(a: static int, c: static string) =
      aVal += a
      cVal.add c
    let b = toTask hello(8, "hello")
    b.invoke()

    doAssert aVal == 8
    doAssert cVal == "hello"

  block:
    var aVal = 0
    var cVal = 0

    proc hello(a: static int, c: int) =
      aVal += a
      cVal += c

    let b = toTask hello(c = 0, a = 8)
    b.invoke()

    doAssert aVal == 8
    doAssert cVal == 0

  block:
    var aVal = 0
    var cVal = 0

    proc hello(a: int, c: static int) =
      aVal += a
      cVal += c

    let b = toTask hello(c = 0, a = 8)
    b.invoke()

    doAssert aVal == 8
    doAssert cVal == 0

  block:
    var aVal = 0
    var cVal = 0

    proc hello(a: static int, c: static int) =
      aVal += a
      cVal += c

    let b = toTask hello(0, 8)
    b.invoke()

    doAssert aVal == 0
    doAssert cVal == 8

  block:
    proc hello(x: int, y: seq[string], d = 134) =
      echo fmt"{x=} {y=} {d=}"

    proc ok() =
      echo "ok"

    proc main() =
      var x = @["23456"]
      let t = toTask hello(2233, x)
      t.invoke()

    main()


  block:
    proc hello(x: int, y: seq[string], d = 134) =
      echo fmt"{x=} {y=} {d=}"

    proc ok() =
      echo "ok"

    proc main() =
      var x = @["23456"]
      let t = toTask hello(2233, x)
      t.invoke()
      t.invoke()

    main()

    var x = @["4"]
    let m = toTask hello(2233, x)
    m.invoke()

    let n = toTask ok()
    n.invoke()

  block:
    var called = 0
    block:
      proc hello() =
        inc called

      let a = toTask hello()
      invoke(a)

    doAssert called == 1

    block:
      proc hello(a: int) =
        inc called, a

      let b = toTask hello(13)
      let c = toTask hello(a = 14)
      b.invoke()
      c.invoke()

    doAssert called == 28

    block:
      proc hello(a: int, c: int) =
        inc called, a

      let b = toTask hello(c = 0, a = 8)
      b.invoke()

    doAssert called == 36
