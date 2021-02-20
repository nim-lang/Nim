import unittest
include nre

block: # Test NRE initialization
  block: # correct initialization
    check(re("[0-9]+") != nil)
    check(re("(?i)[0-9]+") != nil)

  block: # options
    check(extractOptions("(*NEVER_UTF)") ==
          ("", pcre.NEVER_UTF, true))
    check(extractOptions("(*UTF8)(*ANCHORED)(*UCP)z") ==
          ("(*UTF8)(*UCP)z", pcre.ANCHORED, true))
    check(extractOptions("(*ANCHORED)(*UTF8)(*JAVASCRIPT_COMPAT)z") ==
          ("(*UTF8)z", pcre.ANCHORED or pcre.JAVASCRIPT_COMPAT, true))

    check(extractOptions("(*NO_STUDY)(") == ("(", 0, false))

    check(extractOptions("(*LIMIT_MATCH=6)(*ANCHORED)z") ==
          ("(*LIMIT_MATCH=6)z", pcre.ANCHORED, true))

  block: # incorrect options
    for s in ["CR", "(CR", "(*CR", "(*abc)", "(*abc)CR",
              "(?i)",
              "(*LIMIT_MATCH=5", "(*NO_AUTO_POSSESS=5)"]:
      let ss = s & "(*NEVER_UTF)"
      check(extractOptions(ss) == (ss, 0, true))

  block: # invalid regex
    expect(SyntaxError): discard re("[0-9")
    try:
      discard re("[0-9")
    except SyntaxError:
      let ex = SyntaxError(getCurrentException())
      check(ex.pos == 4)
      check(ex.pattern == "[0-9")
