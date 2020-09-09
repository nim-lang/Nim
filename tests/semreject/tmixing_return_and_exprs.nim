discard """
  errormsg: "expression 'len(src) shl 1' is of type 'int' and has to be used (or discarded)"
  line: 19
"""

# bug #15280

type
  HexFlags* {.pure.} = enum
    LowerCase,  ## Produce lowercase hexadecimal characters
    PadOdd,     ## Pads odd strings
    SkipSpaces, ## Skips all the whitespace characters inside of string
    SkipPrefix  ## Skips `0x` and `x` prefixes at the begining of string


proc bytesToHex*(src: openarray[byte], dst: var openarray[char],
                 flags: set[HexFlags]): int =
  if len(dst) == 0:
    (len(src) shl 1)
  else:
    var halflast = false
    let dstlen = len(dst)
    var srclen = len(src)

    if dstlen < (srclen shl 1):
      if (dstlen and 1) == 1:
        srclen = (dstlen - 1) shr 1
        halflast = true
      else:
        srclen = (dstlen shr 1)

    let lowercase = (HexFlags.LowerCase in flags)

    var k = 0
    for i in 0 ..< srclen:
      let x = int(src[i])
      inc(k, 2)

    if halflast:
      let x = int(src[srclen])
      inc(k)

    return k

