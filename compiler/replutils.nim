
import std/strutils

const
  LineContinuationOprs = {'+', '-', '*', '/', '\\', '<', '>', '!', '?', '^',
                          '|', '%', '&', '$', '@', '~', ','}
  AdditionalLineContinuationOprs = {'#', ':', '='}
  LineContinuationTokens = [
    "let", "var", "const", "type",  # section
    "object", "tuple",
    # from ./layouter.oprSet
    "div", "mod", "shl", "shr", "in", "notin", "is",
    "isnot", "not", "of", "as", "from", "..", "and", "or", "xor", 
  ]  # must be all `nimIdentNormalized`-ed


proc endsWith*(x: string, s: set[char]): bool =
  var i = x.len-1
  while i >= 0 and x[i] == ' ': dec(i)
  if i >= 0 and x[i] in s:
    result = true
  else:
    result = false

proc eqIdent(a, bNormalized: string): bool =
  a.nimIdentNormalize == bNormalized

proc endsWithIdent(s, subs: string): bool =
  let le = subs.len
  if le > s.len: return false
  s[^le .. ^1].eqIdent subs

proc continuesWithIdent(s, subs: string, start: int): bool =
  s.substr(start, start+subs.high).eqIdent subs

proc endsWithIdent(s, subs: string, endIdx: var int): bool =
  endIdx.dec subs.len
  result = s.continuesWithIdent(subs, endIdx+1)

proc containsObjectOf(x: string): bool =
  const sep = ' '
  var idx = x.rfind(sep)
  if idx == -1: return
  template eatWord(word) =  
    while x[idx] == sep: idx.dec
    result = x.endsWithIdent(word, idx)
    if not result: return
  eatWord "of"
  eatWord "object"
  result = true

proc endsWithLineContinuationToken(x: string): bool =
  result = false
  for tok in LineContinuationTokens:
    if x.endsWithIdent(tok):
      return true
  result = x.containsObjectOf

proc endsWithOpr*(x: string): bool =
  result = x.endsWith(LineContinuationOprs)

proc continueLine*(line: string, inTripleString: bool): bool {.inline.} =
  result = inTripleString or line.len > 0 and (
        line[0] == ' ' or
        line.endsWith(LineContinuationOprs+AdditionalLineContinuationOprs) or
        line.endsWithLineContinuationToken()
      )

proc countTriples*(s: string): int =
  result = 0
  var i = 0
  while i+2 < s.len:
    if s[i] == '"' and s[i+1] == '"' and s[i+2] == '"':
      inc result
      inc i, 2
    inc i
