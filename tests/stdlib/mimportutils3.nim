var count = 0

proc mimportutils3_fn1*(): int {.exportc.} =
  count.inc
  count
