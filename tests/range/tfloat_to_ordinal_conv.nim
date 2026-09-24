discard """
  targets: "c cpp"
"""

# The compile time range check must not depend on the host's float to integer
# conversion: `1e100.int64` is undefined behaviour, x86 produces `low(int64)`
# whereas arm64 saturates to `high(int64)`, so the compiler used to accept or
# reject these conversions depending on the machine it ran on.

import std/assertions

static:
  doAssert not compiles(int64(1e100))
  doAssert not compiles(uint64(1e100))
  doAssert not compiles(int64(9223372036854775808.0)) # 2^63, one past high(int64)
  doAssert not compiles(uint64(18446744073709551616.0)) # 2^64

# fits `uint64` but not `int64`:
doAssert uint64(1e19) == 10000000000000000000'u64
doAssert int64(-9223372036854775808.0) == low(int64)
doAssert int8(-128.9) == -128'i8
