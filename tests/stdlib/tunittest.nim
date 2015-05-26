import unittest


proc doThings(spuds: var int): int =
  spuds = 24
  return 99
test "#964":
  var spuds = 0
  check doThings(spuds) == 99
  check spuds == 24


from strutils import toUpper
test "#1384":
  check(@["hello", "world"].map(toUpper) == @["HELLO", "WORLD"])


import options
test "unittest typedescs":
  check(none(int) == none(int))
  check(none(int) != some(1))
