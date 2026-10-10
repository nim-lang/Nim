discard """
  errormsg: "type mismatch"
  line: 21
"""

# bug #25152
type
  Content = object
    content_id: int
  ContentId = distinct int

type
  HasPrimaryKey = concept
    proc getIdType(b: typedesc[Self]): typedesc

proc getIdType(T: typedesc[Content]): typedesc[ContentId] = ContentId

proc wasd[T: HasPrimaryKey](c: T, col: T.getIdType()): T = c

let a = Content(content_id: 1)
discard wasd(a, ContentId(2))
