discard """
  output: '''emptyemptyempty'''
  cmd: '''nim c --gc:arc $file'''
"""

# bug #15039

import lists

type
  Token = ref object of RootObj
    children: DoublyLinkedList[Token]

  Paragraph = ref object of Token

method `$`(token: Token): string {.base.} =
  result = "empty"

method `$`(token: Paragraph): string =
  if token.children.head == nil:
    result = ""
  else:
    for c in token.children:
      result.add $c

proc parseLeafBlockInlines(token: Token) =
  token.children.append(Token())
  token.children.append(Token()) # <-- this one AAA

  var emNode = newDoublyLinkedNode(Token())
  var i = 0

  var it = token.children.head
  while it != nil:
    var nxt = it.next  # this is not a cursor, it takes over ownership.
    var childNode = it
    if i == 0:
      childNode.next = emNode # frees the object allocated in line 29 marked with AAA
    elif i == 1:
      emNode.next = childNode  #
    it = nxt # incref on freed data, 'nxt' is freed
    inc i

proc parse() =
  var token = Token()
  token.children.append Paragraph()
  parseLeafBlockInlines(token.children.head.value)
  for children in token.children:
    echo children

parse()
