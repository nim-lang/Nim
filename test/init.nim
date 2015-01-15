import unittest
include nre

suite "Test NRE initialization":
  test "correct intialization":
    check(initRegex("[0-9]+") != nil)
    check(initRegex("[0-9]+", "iS") != nil)

  test "correct options":
    expect(SyntaxError):  # ValueError would be bad
      discard initRegex("[0-9]+",
        "89AEfimNsUWXxY<any><anycrlf><cr><crlf><lf><bsr_anycrlf><bsr_unicode><js>")

  test "incorrect options":
    expect(KeyError): discard initRegex("[0-9]+", "a")
    expect(KeyError): discard initRegex("[0-9]+", "<does_not_exist>")

  test "invalid regex":
    expect(SyntaxError): discard initRegex("[0-9")
    try:
      discard initRegex("[0-9")
    except SyntaxError:
      let ex = SyntaxError(getCurrentException())
      check(ex.pos == 4)
      check(ex.pattern == "[0-9")

