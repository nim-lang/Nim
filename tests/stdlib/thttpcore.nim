discard """
output: "[Suite] httpcore"
"""

import unittest

import httpcore

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
