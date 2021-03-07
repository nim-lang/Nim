## Regular Expressions for the JavaScript target.
## * https://developer.mozilla.org/en-US/docs/Web/JavaScript/Guide/Regular_Expressions

runnableExamples:
  let jsregex: RegExp = newRegExp(r"\s+", r"i")
  jsregex.compile(r"\w+", r"i")
  doAssert jsregex.test(r"nim javascript")
  doAssert jsregex.exec(r"nim javascript") == @["nim".cstring]
  doAssert jsregex.toString() == r"/\w+/i"
  jsregex.compile(r"[0-9]", r"i")
  doAssert jsregex.test(r"0123456789abcd")


when not defined(js):
  {.error: "This module only works on the JavaScript platform".}

type RegExp* {.importjs.} = object    ## Regular Expressions for JavaScript target.
  flags* {.importjs.}: cstring        ## cstring that contains the flags of the RegExp object.
  dotAll* {.importjs.}: bool          ## Whether `.` matches newlines or not.
  global* {.importjs.}: bool          ## Whether to test against all possible matches in a string, or only against the first.
  ignoreCase* {.importjs.}: bool      ## Whether to ignore case while attempting a match in a string.
  multiline* {.importjs.}: bool       ## Whether to search in strings across multiple lines.
  source* {.importjs.}: cstring       ## The text of the pattern.
  sticky* {.importjs.}: bool          ## Whether the search is sticky.
  unicode* {.importjs.}: bool         ## Whether Unicode features are enabled.
  lastIndex* {.importjs.}: cint       ## Index at which to start the next match (read/write property).
  input* {.importjs.}: cstring        ## Read-only and modified on successful match.
  lastMatch* {.importjs.}: cstring    ## Ditto.
  lastParen* {.importjs.}: cstring    ## Ditto.
  leftContext* {.importjs.}: cstring  ## Ditto.
  rightContext* {.importjs.}: cstring ## Ditto.

func newRegExp*(pattern: cstring; flags: cstring): RegExp {.importjs: "new RegExp(@)".}
  ## Creates a new RegExp object.

func compile*(self: RegExp; pattern: cstring; flags: cstring) {.importjs: "#.compile(@)".}
  ## Recompiles a regular expression during execution of a script.

func exec*(self: RegExp; pattern: cstring): seq[cstring] {.importjs: "#.exec(#)".}
  ## Executes a search for a match in its string parameter.

func test*(self: RegExp; pattern: cstring): bool {.importjs: "#.test(#)".}
  ## Tests for a match in its string parameter.

func toString*(self: RegExp): cstring {.importjs: "#.toString()".}
  ## Returns a string representing the RegExp object.
