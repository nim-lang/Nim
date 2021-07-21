discard """
cmd: "nim check --hints:off $file"
action: reject
nimout: '''
tunknown_named_parameter.nim(30, 10) Error: type mismatch: got <string, set[char], maxsplits: int literal(1)>
but expected one of:
func rsplit(s: string; sep: char; maxsplit: int = -1): seq[string]
  first type mismatch at position: 2
  required type for sep: 'char'
  but expression '{':'}' is of type: 'set[char]'
func rsplit(s: string; sep: string; maxsplit: int = -1): seq[string]
  first type mismatch at position: 2
  required type for sep: 'string'
  but expression '{':'}' is of type: 'set[char]'
func rsplit(s: string; seps: set[char] = Whitespace; maxsplit: int = -1): seq[
    string]
  first type mismatch at position: 3
  unknown named parameter: maxsplits

expression: rsplit("abc:def", {':'}, maxsplits = 1)
tunknown_named_parameter.nim(29, 8) Warning: imported and not used: 'strutils' [UnusedImport]
'''
"""


# bug #8043


import strutils
"abc:def".rsplit({':'}, maxsplits = 1)
