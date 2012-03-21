import unittest

proc concat(a, b): string =
  result = $a & $b

test "if proc param types are not supplied, the params are assumed to be generic":
  check concat(1, "test") == "1test"
  check concat(1, 20) == "120"
  check concat("foo", "bar") == "foobar"

test "explicit param types can still be specified":
  check concat[cstring, cstring]("x", "y") == "xy"

