discard """
outputsub: ""
"""

import net, nativesockets
import unittest

suite "getPrimaryIPAddr":
  test "localhost v4":
    check getPrimaryIPAddr(parseIpAddress("127.0.0.1")) == parseIpAddress("127.0.0.1")

  test "localhost v6":
    check getPrimaryIPAddr(parseIpAddress("::1")) == parseIpAddress("::1")

  test "v4":
    check getPrimaryIPAddr() != parseIpAddress("127.0.0.1")
