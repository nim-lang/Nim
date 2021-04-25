## Regular Expressions for the JavaScript target.
## * https://developer.mozilla.org/en-US/docs/Web/JavaScript/Guide/Regular_Expressions
when not defined(js):
  {.error: "This module only works on the JavaScript platform".}

type RegExp* = ref object of JsRoot
  ## Regular Expressions for JavaScript target.
  ## See https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/RegExp
  flags*: cstring        ## cstring that contains the flags of the RegExp object.
  dotAll*: bool          ## Whether `.` matches newlines or not.
  global*: bool          ## Whether to test against all possible matches in a string, or only against the first.
  ignoreCase*: bool      ## Whether to ignore case while attempting a match in a string.
  multiline*: bool       ## Whether to search in strings across multiple lines.
  source*: cstring       ## The text of the pattern.
  sticky*: bool          ## Whether the search is sticky.
  unicode*: bool         ## Whether Unicode features are enabled.
  lastIndex*: cint       ## Index at which to start the next match (read/write property).
  input*: cstring        ## Read-only and modified on successful match.
  lastMatch*: cstring    ## Ditto.
  lastParen*: cstring    ## Ditto.
  leftContext*: cstring  ## Ditto.
  rightContext*: cstring ## Ditto.


func newRegExp*(pattern: cstring; flags: cstring): RegExp {.importjs: "new RegExp(@)".}
  ## Creates a new RegExp object.

func newRegExp*(pattern: cstring): RegExp {.importjs: "new RegExp(@)".}

func compile*(self: RegExp; pattern: cstring; flags: cstring) {.importjs: "#.compile(@)".}
  ## Recompiles a regular expression during execution of a script.

func exec*(self: RegExp; pattern: cstring): seq[cstring] {.importjs: "#.exec(#)".}
  ## Executes a search for a match in its string parameter.

func toCstring*(self: RegExp): cstring {.importjs: "#.toString()".}
  ## Returns a string representing the RegExp object.

func `$`*(self: RegExp): string = $toCstring(self)

func test*(self: RegExp; pattern: cstring): bool {.importjs: "#.test(#)", deprecated: "Use contains instead".}

func toString*(self: RegExp): cstring {.importjs: "#.toString()", deprecated: "Use toCstring instead".}

func contains*(pattern: cstring; self: RegExp): bool =
  ## Tests for a substring match in its string parameter.
  runnableExamples:
    let jsregex: RegExp = newRegExp(r"bc$", r"i")
    assert jsregex in r"abc"
    assert jsregex notin r"abcd"
    assert "xabc".contains jsregex
  asm "`result` = `self`.test(`pattern`);"

template groups*(self: RegExp; pattern: cstring; groups: varargs[var cstring]) =
  ## Named capture groups.
  ## Similar to `var [a, b, c] = regex.exec(pattern).slice(1);` in JavaScript.
  runnableExamples:
    const isoRe = "([2000-2021]{4})-([01-12]{2})-([01-31]{2})T([00-59]{2}):([00-59]{2}):([00-59]{2})".cstring

    block:
      let rex = newRegExp(isoRe)
      var year, month, day, hour, minute, second: cstring
      rex.groups "2021-02-31T12:59:30.666", year, month, day, hour, minute, second
      assert year == "2021" and month == "02" and day == "31"
      assert hour == "12" and minute == "59" and second == "30"

    block:
      let rex = newRegExp(isoRe)
      var year, month, day, hour, minute, second: cstring
      # "second" is missing, no bug, no index error.
      rex.groups "2021-02-31T12:59:30.666", year, month, day, hour, minute
      assert year == "2021" and month == "02" and day == "31"
      assert hour == "12" and minute == "59"
      assert second  == cstring.default

    block:
      let rex = newRegExp(isoRe)
      var year, month, day, hour, minute, second, offByOne: cstring
      # "offByOne" is an extra argument, no bug, no index error.
      rex.groups "2021-02-31T12:59:30.666", year, month, day, hour, minute, second, offByOne
      assert offByOne == cstring.default

  doAssert groups.len > 0, "groups must not be empty varargs[var cstring]"
  {.emit: [groups, " = ", self, ".exec('", pattern, "').slice(1);"] .}


runnableExamples:
  let jsregex: RegExp = newRegExp(r"\s+", r"i")
  jsregex.compile(r"\w+", r"i")
  assert "nim javascript".contains jsregex
  assert jsregex.exec(r"nim javascript") == @["nim".cstring]
  assert jsregex.toCstring() == r"/\w+/i"
  jsregex.compile(r"[0-9]", r"i")
  assert "0123456789abcd".contains jsregex
  assert $jsregex == "/[0-9]/i"
