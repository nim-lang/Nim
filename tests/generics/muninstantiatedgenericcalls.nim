import std/bitops

const
  lengths = block:
    var v: array[64, int8]
    for i in 0..<64:
      v[i] = int8((i + 7) div 7)
    v

type
  Leb128* = object

{.push checks: off.}
func len(T: type Leb128, x: SomeUnsignedInt): int8 =
  if x == 0: 1
  else: lengths[fastLog2(x)]
{.pop.}

# note private to test scoping issue:
func maxLen(T: type Leb128, I: type): int8 =
  Leb128.len(I.high)

type
  Leb128Buf*[T: SomeUnsignedInt] = object
    data*: array[maxLen(Leb128, T), byte] 
    len*: int8
