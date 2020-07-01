## Regular Expressions for the JavaScript target.
## * https://developer.mozilla.org/en-US/docs/Web/JavaScript/Guide/Regular_Expressions

type RegExp* {.importjs.} = object    ## Regular Expressions for JavaScript target.
  flags* {.importjs.}: cstring        ## cstring that contains the flags of the RegExp object.
  dotAll* {.importjs.}: bool          ## Whether ``.`` matches newlines or not.
  global* {.importjs.}: bool          ## Whether to test the regular expression against all possible matches in a string, or only against the first.
  ignoreCase* {.importjs.}: bool      ## Whether to ignore case while attempting a match in a string.
  multiline* {.importjs.}: bool       ## Whether or not to search in strings across multiple lines.
  source* {.importjs.}: cstring       ## The text of the pattern.
  sticky* {.importjs.}: bool          ## Whether or not the search is sticky.
  unicode* {.importjs.}: bool         ## Whether or not Unicode features are enabled.
  lastIndex* {.importjs.}: cint       ## The lastIndex is a read/write integer property of regular expression instances that specifies the index at which to start the next match.
  input* {.importjs.}: cstring        ## The value of the input property is modified whenever the searched string on the regular expression is changed and that string is matching.
  lastMatch* {.importjs.}: cstring    ## The value of the lastMatch property is read-only and modified whenever a successful match is made.
  lastParen* {.importjs.}: cstring    ## The value of the lastParen property is read-only and modified whenever a successful match is made.
  leftContext* {.importjs.}: cstring  ## The value of the leftContext property is read-only and modified whenever a successful match is made.
  rightContext* {.importjs.}: cstring ## The value of the rightContext property is read-only and modified whenever a successful match is made.

func newRegExp*(pattern: cstring; flags: cstring): RegExp {.importjs: "(new RegExp(@))".}
  ## Creates a new RegExp object.

func compile*(self: RegExp; pattern: cstring; flags: cstring) {.importjs: "#.compile(@)".}
  ## Recompiles a regular expression during execution of a script.

func exec*(self: RegExp; pattern: cstring): seq[cstring] {.importjs: "#.exec(#)".}
  ## Executes a search for a match in its string parameter.

func test*(self: RegExp; pattern: cstring): bool {.importjs: "#.test(#)".}
  ## Tests for a match in its string parameter.

func toString*(self: RegExp): cstring {.importjs: "#.toString()".}
  ## Returns a string representing the RegExp object.

runnableExamples:
  let jsregex: RegExp = newRegExp(r"\s+".cstring, "i".cstring)
  jsregex.compile(r"\w+".cstring, "i".cstring)
  doAssert jsregex.test(r"nim javascript".cstring) == true
  doAssert jsregex.exec(r"nim javascript".cstring) == @["nim".cstring]
  doAssert jsregex.toString() == r"/\w+/i".cstring
  jsregex.compile(r"[0-9]".cstring, "i".cstring)
  doAssert jsregex.test(r"0123456789abcd".cstring) == true
