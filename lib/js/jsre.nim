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

func match*(self: RegExp; pattern: cstring): bool {.importjs: "#.test(#)".}
  ## Tests for a substring match in its string parameter.

func toCstring*(self: RegExp): cstring {.importjs: "#.toString()".}
  ## Returns a string representing the RegExp object.

func `$`*(self: RegExp): string = $toCstring(self)

func test*(self: RegExp; pattern: cstring): bool {.importjs: "#.test(#)", deprecated: "Use match instead".}

func toString*(self: RegExp): cstring {.importjs: "#.toString()", deprecated: "Use toCstring instead".}


runnableExamples:
  let jsregex: RegExp = newRegExp(r"\s+", r"i")
  jsregex.compile(r"\w+", r"i")
  assert jsregex.match(r"nim javascript")
  assert jsregex.exec(r"nim javascript") == @["nim".cstring]
  assert jsregex.toCstring() == r"/\w+/i"
  jsregex.compile(r"[0-9]", r"i")
  assert jsregex.match(r"0123456789abcd")
  assert $jsregex == "/[0-9]/i"
