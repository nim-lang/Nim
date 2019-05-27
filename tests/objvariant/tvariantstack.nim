discard """
output: "came here"
"""
#BUG
type
  TAnyKind = enum
    nkInt,
    nkFloat,
    nkString
  PAny = ref TAny
  TAny = object
    case kind: TAnyKind
    of nkInt: intVal: int
    of nkFloat: floatVal: float
    of nkString: strVal: string

  TStack* = object
    list*: seq[TAny]

proc newStack(): TStack =
  result.list = @[]

proc push(Stack: var TStack, item: TAny) =
  var nSeq: seq[TAny] = @[item]
  for i in items(Stack.list):
    nSeq.add(i)
  Stack.list = nSeq

proc pop(Stack: var TStack): TAny =
  result = Stack.list[0]
  Stack.list.delete(0)

var stack = newStack()

var s = TAny(kind: nkString, strVal: "test")

stack.push(s)

var nr = TAny(kind: nkInt, intVal: 78)

stack.push(nr)

var t = stack.pop()
echo "came here"


# another regression:
type
  LexerToken* = enum
    ltYamlDirective, ltYamlVersion, ltTagDirective, ltTagShorthand,
    ltTagUri, ltUnknownDirective, ltUnknownDirectiveParams, ltEmptyLine,
    ltDirectivesEnd, ltDocumentEnd, ltStreamEnd, ltIndentation, ltQuotedScalar,
    ltScalarPart, ltBlockScalarHeader, ltBlockScalar, ltSeqItemInd, ltMapKeyInd,
    ltMapValInd, ltBraceOpen, ltBraceClose, ltBracketOpen, ltBracketClose,
    ltComma, ltLiteralTag, ltTagHandle, ltAnchor, ltAlias

const tokensWithValue =
    {ltScalarPart, ltQuotedScalar, ltYamlVersion, ltTagShorthand, ltTagUri,
     ltUnknownDirective, ltUnknownDirectiveParams, ltLiteralTag, ltAnchor,
     ltAlias, ltBlockScalar}

type
  TokenWithValue = object
    case kind: LexerToken
    of tokensWithValue:
      value: string
    of ltIndentation:
      indentation: int
    of ltTagHandle:
      handle, suffix: string
    else: discard

proc sp(v: string): TokenWithValue =
  # test.nim(27, 17) Error: a case selecting discriminator 'kind' with value 'ltScalarPart' appears in the object construction, but the field(s) 'value' are in conflict with this value.
  TokenWithValue(kind: ltScalarPart, value: v)

let a = sp("test")
