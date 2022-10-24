import tables

type
  JsonNodeKind* = enum ## possible JSON node types
    JNull,
    JBool,
    JInt,
    JFloat,
    JString,
    JObject,
    JArray

  JsonNode* = ref JsonNodeObj ## JSON node
  JsonNodeObj* {.acyclic.} = object
    isUnquoted: bool # the JString was a number-like token and
                     # so shouldn't be quoted
    case kind*: JsonNodeKind
    of JString:
      str*: string
    of JInt:
      num*: BiggestInt
    of JFloat:
      fnum*: float
    of JBool:
      bval*: bool
    of JNull:
      nil
    of JObject:
      fields*: OrderedTable[string, JsonNode]
    of JArray:
      elems*: seq[JsonNode]

proc isUnquoted*(s: JsonNode): bool {.inline.} =
  result = s.isUnquoted

proc `isUnquoted=`*(s: JsonNode, v: bool) {.inline.} =
  s.isUnquoted = v

proc newJRawNumber*(s: string): JsonNode =
  ## Creates a "raw JS number", that is a number that does not
  ## fit into Nim's `BiggestInt` field. This is really a `JString`
  ## with the additional information that it should be converted back
  ## to the string representation without the quotes.
  result = JsonNode(kind: JString, str: s, isUnquoted: true)
