import nre, unittest

suite "escape strings":
  test "escape strings":
    check("123".escapeRe() == "123")
    check("[]".escapeRe() == r"\[\]")
    check("()".escapeRe() == r"\(\)")
