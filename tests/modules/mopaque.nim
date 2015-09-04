type
  TLexer* {.final.} = object
    line*: int
    filename*: string
    buffer: cstring

proc noProcVar*(): int = 18
