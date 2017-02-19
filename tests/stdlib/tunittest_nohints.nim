discard """
  nimout: "compile start\ncompile end"
"""

import unittest

static:
  echo "compile start"

suite "suite, tests only":
  test "test 1":
   check true
  test "test 2":
    check false

suite "suite with setup/teardown":
  setup: discard
  teardown: discard
  test "test 1":
   check true
  test "test 2":
    check false

static:
  echo "compile end"
