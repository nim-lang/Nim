discard """
  cmd: "nim c -r --warningAsError[ProveInit]:on $file"
"""

import std/[sequtils, times]

proc parseMyDates(line: string): DateTime =
    result = parse(line, "yyyy-MM-dd")

var dateStrings = @["2018-12-01", "2018-12-02", "2018-12-03"]
var parsed = dateStrings.map(parseMyDates)
discard parsed
