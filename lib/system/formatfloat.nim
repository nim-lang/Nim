{.deprecated: "use std/strfloats".}

import std/strfloats

const N = 65
static:
  doAssert N > strFloatBufLen

proc writeFloatToBuffer*(buf: var array[N, char]; value: BiggestFloat): int {.deprecated: "use strfloats.toString".} =
  let buf2 = cast[ptr array[strFloatBufLen, char]](buf.addr)
  result = toString(buf2[], value)
  buf[result] = '\0'
