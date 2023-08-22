import nre, unittest

block: # escape strings
  block: # escape strings
    check("123".escapeRe() == "123")
    check("[]".escapeRe() == r"\[\]")
    check("()".escapeRe() == r"\(\)")
