discard """
  disabled: "true"
"""

# Unittest uses lambdalifting at compile-time which we disable for the JS
# codegen! So this cannot and will not work for quite some time.

import unittest

suite "Bacon":
  test ">:)":
    check(true == true)
