import options, unittest

suite "options":
  # work around a bug in unittest
  let intNone = none(int)
  let stringNone = none(string)

  test "example":
    proc find(haystack: string, needle: char): Option[int] =
      for i, c in haystack:
        if c == needle:
          return some i

    check("abc".find('c').get() == 2)

    let result = "team".find('i')

    check result == intNone
    check result.isNone

  test "some":
    check some(6).get() == 6
    check some("a").unsafeGet() == "a"
    check some(6).isSome
    check some("a").isSome

  test "none":
    expect UnpackError:
      discard none(int).get()
    check(none(int).isNone)
    check(not none(string).isSome)

  test "equality":
    check some("a") == some("a")
    check some(7) != some(6)
    check some("a") != stringNone
    check intNone == intNone

    when compiles(some("a") == some(5)):
      check false
    when compiles(none(string) == none(int)):
      check false

  test "get with a default value":
    check( some("Correct").get("Wrong") == "Correct" )
    check( stringNone.get("Correct") == "Correct" )

  test "$":
    check( $(some("Correct")) == "Some(Correct)" )
    check( $(stringNone) == "None[string]" )

  test "map with a void result":
    var procRan = 0
    some(123).map(proc (v: int) = procRan = v)
    check procRan == 123
    intNone.map(proc (v: int) = check false)

  test "map":
    check( some(123).map(proc (v: int): int = v * 2) == some(246) )
    check( intNone.map(proc (v: int): int = v * 2).isNone )

  test "filter":
    check( some(123).filter(proc (v: int): bool = v == 123) == some(123) )
    check( some(456).filter(proc (v: int): bool = v == 123).isNone )
    check( intNone.filter(proc (v: int): bool = check false).isNone )
