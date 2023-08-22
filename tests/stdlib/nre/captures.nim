import unittest, optional_nonstrict
include nre

block: # captures
  block: # map capture names to numbers
    check(getNameToNumberTable(re("(?<v1>1(?<v2>2(?<v3>3))(?'v4'4))()")) ==
      { "v1" : 0, "v2" : 1, "v3" : 2, "v4" : 3 }.toTable())

  block: # capture bounds are correct
    let ex1 = re("([0-9])")
    check("1 23".find(ex1).matchBounds == 0 .. 0)
    check("1 23".find(ex1).captureBounds[0] == 0 .. 0)
    check("1 23".find(ex1, 1).matchBounds == 2 .. 2)
    check("1 23".find(ex1, 3).matchBounds == 3 .. 3)

    let ex2 = re("()()()()()()()()()()([0-9])")
    check("824".find(ex2).captureBounds[0] == 0 .. -1)
    check("824".find(ex2).captureBounds[10] == 0 .. 0)

    let ex3 = re("([0-9]+)")
    check("824".find(ex3).captureBounds[0] == 0 .. 2)

  block: # named captures
    let ex1 = "foobar".find(re("(?<foo>foo)(?<bar>bar)"))
    check(ex1.captures["foo"] == "foo")
    check(ex1.captures["bar"] == "bar")

    let ex2 = "foo".find(re("(?<foo>foo)(?<bar>bar)?"))
    check("foo" in ex2.captureBounds)
    check(ex2.captures["foo"] == "foo")
    check(not ("bar" in ex2.captures))
    expect KeyError:
        discard ex2.captures["bar"]

  block: # named capture bounds
    let ex1 = "foo".find(re("(?<foo>foo)(?<bar>bar)?"))
    check("foo" in ex1.captureBounds)
    check(ex1.captureBounds["foo"] == 0..2)
    check(not ("bar" in ex1.captures))
    expect KeyError:
        discard ex1.captures["bar"]

  block: # capture count
    let ex1 = re("(?<foo>foo)(?<bar>bar)?")
    check(ex1.captureCount == 2)
    check(ex1.captureNameId == {"foo" : 0, "bar" : 1}.toTable())

  block: # named capture table
    let ex1 = "foo".find(re("(?<foo>foo)(?<bar>bar)?"))
    check(ex1.captures.toTable == {"foo" : "foo"}.toTable())
    check(ex1.captureBounds.toTable == {"foo" : 0..2}.toTable())

    let ex2 = "foobar".find(re("(?<foo>foo)(?<bar>bar)?"))
    check(ex2.captures.toTable == {"foo" : "foo", "bar" : "bar"}.toTable())

  block: # capture sequence
    let ex1 = "foo".find(re("(?<foo>foo)(?<bar>bar)?"))
    check(ex1.captures.toSeq == @[some("foo"), none(string)])
    check(ex1.captureBounds.toSeq == @[some(0..2), none(Slice[int])])
    check(ex1.captures.toSeq(some("")) == @[some("foo"), some("")])

    let ex2 = "foobar".find(re("(?<foo>foo)(?<bar>bar)?"))
    check(ex2.captures.toSeq == @[some("foo"), some("bar")])

