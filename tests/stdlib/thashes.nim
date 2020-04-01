
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

    test "VM and runtime should make the same hash value (hashIdentity)":
      const hi123 = hashIdentity(123)
      check hashIdentity(123) == hi123

    test "VM and runtime should make the same hash value (hashWangYi1)":
      const wy123 = hashWangYi1(123)
      check hashWangYi1(123) == wy123

    test "hashIdentity value incorrect at 456":
      check hashIdentity(456) == 456

    test "hashWangYi1 value incorrect at 456":
      when Hash.sizeof < 8:
        check hashWangYi1(456) == 1293320666
      else:
        check hashWangYi1(456) == -6421749900419628582
