import tables
import jsontypes

proc newJString*(s: string): JsonNode =
  ## Creates a new `JString JsonNode`.
  result = JsonNode(kind: JString, str: s)

proc newJInt*(n: BiggestInt): JsonNode =
  ## Creates a new `JInt JsonNode`.
  result = JsonNode(kind: JInt, num: n)

proc newJFloat*(n: float): JsonNode =
  ## Creates a new `JFloat JsonNode`.
  result = JsonNode(kind: JFloat, fnum: n)

proc newJBool*(b: bool): JsonNode =
  ## Creates a new `JBool JsonNode`.
  result = JsonNode(kind: JBool, bval: b)

proc newJNull*(): JsonNode =
  ## Creates a new `JNull JsonNode`.
  result = JsonNode(kind: JNull)

proc newJObject*(): JsonNode =
  ## Creates a new `JObject JsonNode`
  result = JsonNode(kind: JObject, fields: initOrderedTable[string, JsonNode](2))

proc newJArray*(): JsonNode =
  ## Creates a new `JArray JsonNode`
  result = JsonNode(kind: JArray, elems: @[])
