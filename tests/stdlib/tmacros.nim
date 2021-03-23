import macros

block: # bug #17454
  proc f(v: NimNode): string {.raises: [].} = $v
