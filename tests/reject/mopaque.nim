type
  TLexer* {.final.} = object
    line*: int
    filename*: string
    buffer: cstring
