import unittest

suite "Trivial tests":
  test "Passing test":
    check 1 == 1

  test "Failing test":
    check 1 == 2
