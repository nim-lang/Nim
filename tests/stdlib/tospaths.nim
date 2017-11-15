import ospaths, unittest

test "splitPathComponents":
  check splitPathComponents("").len == 0
  check splitPathComponents("/").len == 0
  check splitPathComponents("foo") == @["foo"]
  check splitPathComponents("/foo") == @["foo"]
  check splitPathComponents("foo/bar") == @["foo", "bar"]
  check splitPathComponents("/foo/bar") == @["foo", "bar"]
  check splitPathComponents("foo/bar/") == @["foo", "bar"]
  check splitPathComponents("/foo/bar/") == @["foo", "bar"]
