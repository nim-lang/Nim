# Test the sizeof proc

import
  io

type
  TMyRecord = record
    x, y: int
    b: bool
    r: float
    s: string

write(stdout, sizeof(TMyRecord))
