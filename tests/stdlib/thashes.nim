
discard """
output: '''
[Suite] hashes

[Suite] hashing

'''
"""

import unittest, hashes

suite "hashes":
  suite "hashing":
    test "0.0 and -0.0 should have the same hash value":
      var dummy = 0.0
      check hash(dummy) == hash(-dummy)
      check hash(0.0) == hash(-0.0)
      check hash(0.0f) == hash(-0.0f)
      let h1 = hash(0.0)
      const h2 = hash(0.0)
      const h3 = hash(-0.0)
      check h1 == h2
      check h1 == h3
