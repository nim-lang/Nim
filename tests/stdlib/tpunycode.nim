import punycode

assert(decode(encode("", "bücher")) == "bücher")
assert(decode(encode("münchen")) == "münchen")
assert encode("xn--", "münchen") == "xn--mnchen-3ya"
