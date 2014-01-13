# Test the sizeof proc

type
  TMyRecord {.final.} = object
    x, y: int
    b: bool
    r: float
    s: string

write(stdout, sizeof(TMyRecord))
