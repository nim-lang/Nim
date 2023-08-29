discard """
  joinable: false
"""

{.warningAsError[ProveInit]:on.}
template main() =
  proc fn(): var int =
    discard
  discard fn()
doAssert not compiles(main())

# bug #9901
import std/[sequtils, times]
proc parseMyDates(line: string): DateTime =
  result = parse(line, "yyyy-MM-dd")
var dateStrings = @["2018-12-01", "2018-12-02", "2018-12-03"]
var parsed = dateStrings.map(parseMyDates)
discard parsed
