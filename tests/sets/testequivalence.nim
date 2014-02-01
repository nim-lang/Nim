import unittest
import sets

suite "sets":
  test "equivalent or subset":
    check toSet(@[1,2,3]) <= toSet(@[1,2,3,4])
    check toSet(@[1,2,3]) <= toSet(@[1,2,3])
    check(not(toSet(@[1,2,3]) <= toSet(@[1,2])))
  test "strict subset":
    check toSet(@[1,2,3]) <= toSet(@[1,2,3,4])
    check(not(toSet(@[1,2,3]) < toSet(@[1,2,3])))
    check(not(toSet(@[1,2,3]) < toSet(@[1,2])))
  test "==":
    check(not(toSet(@[1,2,3]) == toSet(@[1,2,3,4])))
    check toSet(@[1,2,3]) == toSet(@[1,2,3])
    check(not(toSet(@[1,2,3]) == toSet(@[1,2])))
