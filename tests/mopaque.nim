type
  TLexer* = record
    line*: int
    filename*: string
    buffer: cstring
