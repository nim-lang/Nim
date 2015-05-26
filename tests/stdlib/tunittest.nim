import unittest
import options
test "unittest typedescs":
  check(none(int) == none(int))
  check(none(int) != some(1))
