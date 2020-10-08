discard """
output: "[Suite] httpcore"
"""

import unittest

import httpcore, strutils

suite "httpcore":

  test "HttpCode":
    assert $Http418 == "418 I'm a teapot"
    assert Http418.is4xx() == true
    assert Http418.is2xx() == false

  test "headers":
    var h = newHttpHeaders()
    assert h.len == 0
    h.add("Cookie", "foo")
    assert h.len == 1
    assert h.hasKey("cooKIE")
    assert h["Cookie"] == "foo"
    assert h["cookie"] == "foo"
    h["cookie"] = @["bar", "x"]
    assert h["Cookie"] == "bar"
    assert h["Cookie", 1] == "x"
    assert h["Cookie"].contains("BaR") == true
    assert h["Cookie"].contains("X") == true
    assert "baR" in h["cookiE"]
    h.del("coOKie")
    assert h.len == 0

    # Test that header constructor works with repeated values
    let h1 = newHttpHeaders({"a": "1", "a": "2", "A": "3"})

    assert seq[string](h1["a"]).join(",") == "1,2,3"

  test "test cookies with comma":
    doAssert parseHeader("cookie: foo, bar") ==  ("cookie", @["foo, bar"])
    doAssert parseHeader("cookie: foo, bar, prologue") == ("cookie", @["foo, bar, prologue"])
    doAssert parseHeader("cookie: foo, bar, prologue, starlight") == ("cookie", @["foo, bar, prologue, starlight"])

    doAssert parseHeader("cookie:   foo, bar") ==  ("cookie", @["foo, bar"])
    doAssert parseHeader("cookie:  foo, bar, prologue") == ("cookie", @["foo, bar, prologue"])
    doAssert parseHeader("cookie:   foo, bar, prologue, starlight") == ("cookie", @["foo, bar, prologue, starlight"])

    doAssert parseHeader("Cookie: foo, bar") == (key: "Cookie", value: @["foo, bar"])
    doAssert parseHeader("Cookie: foo, bar, prologue") == (key: "Cookie", value: @["foo, bar, prologue"])
    doAssert parseHeader("Cookie: foo, bar, prologue, starlight") == (key: "Cookie", value: @["foo, bar, prologue, starlight"])

    doAssert parseHeader("Accept: foo, bar") == (key: "Accept", value: @["foo", "bar"])
    doAssert parseHeader("Accept: foo, bar, prologue") == (key: "Accept", value: @["foo", "bar", "prologue"])
    doAssert parseHeader("Accept: foo, bar, prologue, starlight") == (key: "Accept", value: @["foo", "bar", "prologue", "starlight"])
