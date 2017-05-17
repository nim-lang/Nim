import nativesockets, unittest

suite "nativesockets":
  test "getHostname":
    let hostname = getHostname()
    check hostname.len > 0
    check hostname.len < 64

