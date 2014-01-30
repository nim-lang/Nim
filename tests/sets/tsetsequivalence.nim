import sets
import unittest

suite "sets":
  test "equivalence":
    check toSet(@[1]) == toSet(@[1])
