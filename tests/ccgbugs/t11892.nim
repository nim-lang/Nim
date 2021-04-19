discard """
  errormsg: "symbols cannot be routine kinds"
"""

# bug #11892

proc getticks(): int64 {.inline.} =
  var lo, hi: int64

  # Notice "low" instead of lo in the inline assembly
  {.emit: """asm volatile(
    "lfence\n"
    "rdtsc\n"
    : "=a"(`low`), "=d"(`hi`)
    :
    : "memory"
  );""".}
  return (hi shl 32) or lo


echo getticks()
