import std/[uri, sequtils]


block:
  doAssert toSeq(decodeQuery("a=1&b=0")) == @[("a", "1"), ("b", "0")]
  doAssertRaises(UriParseError):
    discard toSeq(decodeQuery("a=1&b=2c=6"))
