import unittest
import nre

suite "Test NRE initialization":
  test "correct intialization":
    check(re("[0-9]+") != nil)
    check(re("[0-9]+", "i") != nil)

  test "correct options":
    expect(SyntaxError):  # ValueError would be bad
      discard re("[0-9]+",
        "89AEfimNsUWXxY<any><anycrlf><cr><crlf><lf><bsr_anycrlf><bsr_unicode><js><no_study>")

  test "incorrect options":
    expect(KeyError): discard re("[0-9]+", "a")
    expect(KeyError): discard re("[0-9]+", "<does_not_exist>")

  test "invalid regex":
    expect(SyntaxError): discard re("[0-9")
    try:
      discard re("[0-9")
    except SyntaxError:
      let ex = SyntaxError(getCurrentException())
      check(ex.pos == 4)
      check(ex.pattern == "[0-9")

