discard """
  action: "reject"

"""

import strutils, sugar, nre

proc my_replace*(s: string, r: Regex, by: string | (proc (match: string): string)): string =
  nre.replace(s, r, by)

discard my_replace("abcde", re"[bcd]", match => match.to_upper) == "aBCDe"
discard my_replace("abcde", re"[bcd]", (match: string) => match.to_upper) == "aBCDe"
