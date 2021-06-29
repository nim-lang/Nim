import punycode

doAssert(decode(encode("", "bücher")) == "bücher")
doAssert(decode(encode("münchen")) == "münchen")
doAssert encode("xn--", "münchen") == "xn--mnchen-3ya"
