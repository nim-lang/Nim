# bug #1986 found by gdmoore

proc test(): int64 =
  return 0xdeadbeef.int64

const items = [
  (var1: test(), var2: 100'u32),
  (var1: test(), var2: 192'u32)
]

