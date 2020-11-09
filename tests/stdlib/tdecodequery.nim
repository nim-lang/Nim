import uri, sequtils


block:
  const queryString = "a=1&b=0"
  const wrongQueryString = "a=1&b=2c=6"

  doAssert toSeq(decodeQuery(queryString)) == @[("a", "1"), ("b", "0")]
  doAssertRaises(UriParseError):
    discard toSeq(decodeQuery(wrongQueryString))
