discard """
  matrix: "--mm:refc; --mm:orc"
  output: '''
tjson_sumtype: OK
'''
"""

# ported from Nimony's tests/nimony/object/tjson_sumtype.nim
## JSON value model and a tiny recursive-descent parser, exercising Nimony sum types
## (`case` / `of Branch(...)` patterns).

import std/[parseutils, strutils]

type
  Json* = ref object
    case
    of JNull:
      nilPad: bool ## payload-free null; kept for object layout
    of JBool:
      b: bool
    of JInt:
      n: int64
    of JString:
      s: string
    of JArray:
      elems: seq[Json]
    of JObject:
      pairs: seq[tuple[key: string, val: Json]]

proc skipWs(s: string; i: var int) =
  while i < s.len and s[i] in Whitespace:
    inc i

proc parseJson(s: string; i: var int): Json

proc parseStrLit(s: string; i: var int): string =
  assert s[i] == '"'
  inc i
  result = ""
  while i < s.len:
    let c = s[i]
    if c == '"':
      inc i
      return
    if c == '\\':
      inc i
      if i >= s.len:
        quit "bad escape in string"
      case s[i]
      of '"', '\\', '/':
        result.add s[i]
      of 'b':
        result.add '\b'
      of 'f':
        result.add '\f'
      of 'n':
        result.add '\l'
      of 'r':
        result.add '\r'
      of 't':
        result.add '\t'
      else:
        quit "unsupported escape in string"
      inc i
    else:
      result.add c
      inc i
  quit "unterminated string"

proc parseArr(s: string; i: var int): Json =
  assert s[i] == '['
  inc i
  skipWs s, i
  var xs = default(seq[Json])
  if i < s.len and s[i] == ']':
    inc i
    return JArray(elems: xs)
  while true:
    skipWs s, i
    xs.add parseJson(s, i)
    skipWs s, i
    if i >= s.len:
      quit "unterminated array"
    if s[i] == ']':
      inc i
      break
    if s[i] != ',':
      quit "expected `,` or `]` in array"
    inc i
  result = JArray(elems: xs)

proc parseObj(s: string; i: var int): Json =
  assert s[i] == '{'
  inc i
  skipWs s, i
  var ps = default(seq[tuple[key: string, val: Json]])
  if i < s.len and s[i] == '}':
    inc i
    return JObject(pairs: ps)
  while true:
    skipWs s, i
    if i >= s.len or s[i] != '"':
      quit "expected string key in object"
    let k = parseStrLit(s, i)
    skipWs s, i
    if i >= s.len or s[i] != ':':
      quit "expected `:` after object key"
    inc i
    skipWs s, i
    let v = parseJson(s, i)
    ps.add((key: k, val: v))
    skipWs s, i
    if i >= s.len:
      quit "unterminated object"
    if s[i] == '}':
      inc i
      break
    if s[i] != ',':
      quit "expected `,` or `}` in object"
    inc i
  result = JObject(pairs: ps)

proc parseJson(s: string; i: var int): Json =
  skipWs s, i
  if i >= s.len:
    quit "unexpected end in json"
  case s[i]
  of 'n':
    if s.continuesWith("null", i):
      inc i, 4
      return JNull(nilPad: false)
    quit "expected null"
  of 't':
    if s.continuesWith("true", i):
      inc i, 4
      return JBool(b: true)
    quit "expected true"
  of 'f':
    if s.continuesWith("false", i):
      inc i, 5
      return JBool(b: false)
    quit "expected false"
  of '"':
    result = JString(s: parseStrLit(s, i))
  of '[':
    result = parseArr(s, i)
  of '{':
    result = parseObj(s, i)
  of '-', '0'..'9':
    var x = default(BiggestInt)
    let n = parseBiggestInt(s.toOpenArray(i, s.high), x)
    if n == 0:
      quit "expected number"
    i += n
    result = JInt(n: int64(x))
  else:
    quit "unexpected char in json"

proc intAt(j: Json): int64 =
  case j
  of JInt(n):
    result = n
  else:
    quit "not an int"

proc strAt(j: Json): string =
  case j
  of JString(s):
    result = s
  else:
    quit "not a string"

proc lenArr(j: Json): int =
  case j
  of JArray(elems):
    result = elems.len
  else:
    quit "not an array"

proc elemAt(j: Json; idx: int): Json =
  case j
  of JArray(elems):
    result = elems[idx]
  else:
    quit "not an array"

proc lookup(j: Json; key: string): Json =
  # No `result = default(Json)` to open with: `Json` is a not-nil ref and has
  # no default. Every path below either returns a value or quits.
  case j
  of JObject(pairs):
    var p = 0
    while p < pairs.len:
      if pairs[p].key == key:
        result = pairs[p].val
        return
      inc p
    quit "key not in object"
  else:
    quit "not an object"

proc parseJsonAll(s: string): Json =
  var i = 0
  result = parseJson(s, i)
  skipWs s, i
  if i != s.len:
    quit "trailing junk in json"

proc main() =
  let j0 = parseJsonAll("null")
  case j0
  of JNull(nilPad):
    assert not nilPad
  else:
    assert false

  let j1 = parseJsonAll("42")
  assert intAt(j1) == 42

  let j2 = parseJsonAll("\"ab\\\"c\"")
  assert strAt(j2) == "ab\"c"

  let j3 = parseJsonAll("[1,2,3]")
  assert lenArr(j3) == 3
  assert intAt(elemAt(j3, 0)) == 1
  assert intAt(elemAt(j3, 2)) == 3

  let j4 = parseJsonAll("{\"a\":7,\"b\":{\"c\":9}}")
  assert intAt(lookup(j4, "a")) == 7
  let inner = lookup(j4, "b")
  assert intAt(lookup(inner, "c")) == 9

  echo "tjson_sumtype: OK"

main()
