
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
