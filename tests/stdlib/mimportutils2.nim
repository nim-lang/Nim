var count = 0

proc mimportutils2_fn1*(): int {.exportc.} =
  count.inc
  count

proc mimportutils2_fn2(): int {.exportc.} =
  count.inc
  count
