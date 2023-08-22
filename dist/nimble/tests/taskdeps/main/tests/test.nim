import unittest2

when defined(useDevelop):
  echo "Using custom file"
  import unittest2/customFile

suite "Test":
  test "Foo":
    check true
