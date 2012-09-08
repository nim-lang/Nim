import unittest
import hashes

suite "hashes":
  suite "hashing":
    test "0.0 and -0.0 should have the same hash value":
      check hash(0.0) == hash(-0.0)