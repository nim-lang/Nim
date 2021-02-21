import httpcore, strutils

block:
  block HttpCode:
    doAssert $Http418 == "418 I'm a teapot"
    doAssert Http418.is4xx() == true
    doAssert Http418.is2xx() == false

  block headers:
    var h = newHttpHeaders()
    doAssert h.len == 0
    h.add("Cookie", "foo")
    doAssert h.len == 1
    doAssert h.hasKey("cooKIE")
    doAssert h["Cookie"] == "foo"
    doAssert h["cookie"] == "foo"
    h["cookie"] = @["bar", "x"]
    doAssert h["Cookie"] == "bar"
    doAssert h["Cookie", 1] == "x"
    doAssert h["Cookie"].contains("BaR") == true
    doAssert h["Cookie"].contains("X") == true
    doAssert "baR" in h["cookiE"]
    h.del("coOKie")
    doAssert h.len == 0

    # Test that header constructor works with repeated values
    let h1 = newHttpHeaders({"a": "1", "a": "2", "A": "3"})

    doAssert seq[string](h1["a"]).join(",") == "1,2,3"

  block test_cookies_with_comma:
    doAssert parseHeader("cookie: foo, bar") ==  ("cookie", @["foo, bar"])
    doAssert parseHeader("cookie: foo, bar, prologue") == ("cookie", @["foo, bar, prologue"])
    doAssert parseHeader("cookie: foo, bar, prologue, starlight") == ("cookie", @["foo, bar, prologue, starlight"])

    doAssert parseHeader("cookie:   foo, bar") ==  ("cookie", @["foo, bar"])
    doAssert parseHeader("cookie:  foo, bar, prologue") == ("cookie", @["foo, bar, prologue"])
    doAssert parseHeader("cookie:   foo, bar, prologue, starlight") == ("cookie", @["foo, bar, prologue, starlight"])

    doAssert parseHeader("Cookie: foo, bar") == (key: "Cookie", value: @["foo, bar"])
    doAssert parseHeader("Cookie: foo, bar, prologue") == (key: "Cookie", value: @["foo, bar, prologue"])
    doAssert parseHeader("Cookie: foo, bar, prologue, starlight") == (key: "Cookie", value: @["foo, bar, prologue, starlight"])

    doAssert parseHeader("Accept: foo, bar") == (key: "Accept", value: @["foo", "bar"])
    doAssert parseHeader("Accept: foo, bar, prologue") == (key: "Accept", value: @["foo", "bar", "prologue"])
    doAssert parseHeader("Accept: foo, bar, prologue, starlight") == (key: "Accept", value: @["foo", "bar", "prologue", "starlight"])

  block add_empty_sequence_to_HTTP_headers:
    block:
      var headers = newHttpHeaders()
      headers["empty"] = @[]

      doAssert not headers.hasKey("empty")

    block:
      var headers = newHttpHeaders()
      headers["existing"] = "true"
      headers["existing"] = @[]

      doAssert not headers.hasKey("existing")

    block:
      var headers = newHttpHeaders()
      headers["existing"] = @["true"]
      headers["existing"] = @[]

      doAssert not headers.hasKey("existing")

    block:
      var headers = newHttpHeaders()
      headers["existing"] = @[]
      headers["existing"] = @["true"]
      doAssert headers.hasKey("existing")

block:
  var test = newHttpHeaders()
  test["Connection"] = @["Upgrade", "Close"]
  doAssert test["Connection", 0] == "Upgrade"
  doAssert test["Connection", 1] == "Close"
  test.add("Connection", "Test")
  doAssert test["Connection", 2] == "Test"
  doAssert "upgrade" in test["Connection"]

  # Bug #5344.
  doAssert parseHeader("foobar: ") == ("foobar", @[""])
  let (key, value) = parseHeader("foobar: ")
  test = newHttpHeaders()
  test[key] = value
  doAssert test["foobar"] == ""

  doAssert parseHeader("foobar:") == ("foobar", @[""])

  block: # test title case
    var testTitleCase = newHttpHeaders(titleCase=true)
    testTitleCase.add("content-length", "1")
    doAssert testTitleCase.hasKey("Content-Length")
    for key, val in testTitleCase:
        doAssert key == "Content-Length"
