const digitsTable* = "0001020304050607080910111213141516171819" &
    "2021222324252627282930313233343536373839" &
    "4041424344454647484950515253545556575859" &
    "6061626364656667686970717273747576777879" &
    "8081828384858687888990919293949596979899"
  # Inspired by https://engineering.fb.com/2013/03/15/developer-tools/three-optimization-tips-for-c
  # Generates:
  # .. code-block:: nim
  #   var res = ""
  #   for i in 0 .. 99:
  #     if i < 10:
  #       res.add "0" & $i
  #     else:
  #       res.add $i
  #   doAssert res == digitsTable


func digits10*(num: uint64): int {.noinline.} =
  if num < 10'u64:
    result = 1
  elif num < 100'u64:
    result = 2
  elif num < 1_000'u64:
    result = 3
  elif num < 10_000'u64:
    result = 4
  elif num < 100_000'u64:
    result = 5
  elif num < 1_000_000'u64:
    result = 6
  elif num < 10_000_000'u64:
    result = 7
  elif num < 100_000_000'u64:
    result = 8
  elif num < 1_000_000_000'u64:
    result = 9
  elif num < 10_000_000_000'u64:
    result = 10
  elif num < 100_000_000_000'u64:
    result = 11
  elif num < 1_000_000_000_000'u64:
    result = 12
  else:
    result = 12 + digits10(num div 1_000_000_000_000'u64)