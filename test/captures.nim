import unittest
include nre

suite "captures":
  test "map capture names to numbers":
    check(getNameToNumberTable(initRegex("(?<v1>1(?<v2>2(?<v3>3))(?'v4'4))()")) == 
      { "v1" : 0, "v2" : 1, "v3" : 2, "v4" : 3 }.toTable())

  test "capture bounds are correct":
    let ex1 = initRegex("([0-9])")
    check(ex1.exec("1 23").get.matchBounds == 0 .. 1)
    check(ex1.exec("1 23").get.captureBounds[0].get == 0 .. 1)
    check(ex1.exec("1 23", 1).get.matchBounds == 2 .. 3)
    check(ex1.exec("1 23", 3).get.matchBounds == 3 .. 4)

    let ex2 = initRegex("()()()()()()()()()()([0-9])")
    check(ex2.exec("824").get.captureBounds[0].get == 0 .. 0)
    check(ex2.exec("824").get.captureBounds[10].get == 0 .. 1)

    let ex3 = initRegex("([0-9]+)")
    check(ex3.exec("824").get.captureBounds[0].get == 0 .. 3)

  test "named captures":
    let ex1 = initRegex("(?<foo>foo)(?<bar>bar)").exec("foobar").get
    check(ex1.captures["foo"] == "foo")
    check(ex1.captures["bar"] == "bar")

    let ex2 = initRegex("(?<foo>foo)(?<bar>bar)?").exec("foo").get
    check(ex2.captures["foo"] == "foo")
    check(ex2.captures["bar"] == nil)

  test "named capture bounds":
    let ex1 = initRegex("(?<foo>foo)(?<bar>bar)?").exec("foo").get
    check(ex1.captureBounds["foo"] == Some(0..3))
    check(ex1.captureBounds["bar"] == None[Slice[int]]())

  test "capture count":
    let ex1 = initRegex("(?<foo>foo)(?<bar>bar)?")
    check(ex1.captureCount == 2)
    # Don't have sets, do this :<
    check(ex1.captureNames == @["foo", "bar"] or ex1.captureNames == @["bar", "foo"])
