import std/strutils # toHex

when defined(js):
  type
    # JS target does not do well with 64 bits as integers are always represented
    # as doubles, so we only have 52 bits of perfect accuracy. That's why we represent
    # a single uint64 as a combination of a high and low uint32.
    CompatUint64* {.packed.} = tuple
      lo: uint32
      hi: uint32

  # >>> 0 discards all bits above the 32nd
  proc forceUnsigned*(x: uint32): uint32 {.importjs: "# >>> 0".}
  proc forceUnsigned*(x: uint64): uint32 {.importjs: "# >>> 0".}

  converter fromUint64*(x: uint64): CompatUint64 =
    when nimvm:
      (lo: uint32(x and 0xFFFFFFFF'u64), hi: uint32(x shr 32))
    else:
      when defined(js):
        if x > 0xFFFFFFFF'u64:
          # We must not create integers higher than this from JS, or we may loose
          # information. Technically we can go as high as 0xFFFFF_FFFFFFFF
          # (52 bits), but as we have no need to do so for now, we can make things
          # simple.
          doAssert false

        (lo: forceUnsigned x, hi: 0)
      else:
        (lo: forceUnsigned x, hi: forceUnsigned(x shr 32))

  converter fromUint8*(x: uint8): CompatUint64 =
    (lo: uint32(x), hi: 0)

  converter toUint64*(x: CompatUint64): uint64 =
    when defined(js):
      doAssert x.hi == 0

    uint64(x.hi) shl 32 or x.lo

  converter toChar*(x: CompatUint64): char =
    char(x.lo and 0xFF)


  func `xor`*(a, b: CompatUint64): CompatUint64 {.inline.} = (forceUnsigned a.lo xor forceUnsigned b.lo, forceUnsigned a.hi xor forceUnsigned b.hi)
  func `and`*(a, b: CompatUint64): CompatUint64 {.inline.} = (forceUnsigned a.lo and forceUnsigned b.lo, forceUnsigned a.hi and forceUnsigned b.hi)
  func `or`*(a, b: CompatUint64): CompatUint64 {.inline.} = (forceUnsigned a.lo or forceUnsigned b.lo, forceUnsigned a.hi or forceUnsigned b.hi)
  func `not`*(a: CompatUint64): CompatUint64 {.inline.} = (forceUnsigned(not a.lo), forceUnsigned(not a.hi))

  proc `+`*(a, b: CompatUint64): CompatUint64 {.inline.} =
    # We can dip into the 33 bits.
    let nhi = uint64(a.hi) + b.hi
    let nlo = uint64(a.lo) + uint64(b.lo)

    # N.B. JavaScript allows *numeric* comparisons above 0xFFFF_FFFF up to 52 bits
    #      of integral precision, but as soon as you start operating with bitwise
    #      operators, everything from the 32nd bit upwards is truncated. So this
    #      *must* be `> 0xffff_ffff` as the intuitive `and 0x1_0000_0000` will
    #      switch to fixed 32 bit bitwise operation and always yield `false`.
    let carry = if (nlo > 0xffff_ffff'u64): 1'u else: 0'u

    (forceUnsigned nlo, forceUnsigned (nhi + carry))

  proc inc*(a: var CompatUint64; b: CompatUint64) {.inline.} =
    a = a + b

  proc `shl`*(a: CompatUint64; offset: int): CompatUint64 =
    if offset == 0:
      # Annoying wrapping behaviour when "a.hi shl (32 - offset)" turns into "<< 32"
      # which JS interprets as "do exactly nothing"
      return a

    if offset < 32:
      (forceUnsigned(a.lo shl offset),
       forceUnsigned((a.hi shl offset) or (a.lo shr (32 - offset))))
    else:
      (0,
      forceUnsigned(a.lo shl (offset - 32)))

  proc `shr`*(a: CompatUint64; offset: int): CompatUint64 =
    if offset == 0:
      # Annoying wrapping behaviour when "a.hi shl (32 - offset)" turns into "<< 32"
      # which JS interprets as "do exactly nothing"
      return a

    if offset < 32:
      let bitmask = forceUnsigned(uint32(a.hi shl (32 - offset)) and 0xFFFFFFFF'u32)

      result = (
        forceUnsigned((a.lo shr offset) or bitmask),
        forceUnsigned(a.hi shr offset))
    else:
      result = (forceUnsigned a.hi shr (offset - 32), 0)

  func rotateLeftBits*(a: CompatUint64; offset: int): CompatUint64 =
    if offset < 32:
      (forceUnsigned ((a.lo shl offset) or (a.hi shr (32 - offset))),
       forceUnsigned ((a.hi shl offset) or (a.lo shr (32 - offset))))
    else:
      (forceUnsigned ((a.hi shl (offset - 32)) or (forceUnsigned (a.lo shr (64 - offset)))),
       forceUnsigned ((a.lo shl (offset - 32)) or (forceUnsigned (a.hi shr (64 - offset)))))

  func rotateRightBits*(a: CompatUint64; offset: int): CompatUint64 =
    if offset < 32:
      (forceUnsigned ((a.lo shr offset) or (forceUnsigned (a.hi shl (32 - offset)))),
       forceUnsigned ((a.hi shr offset) or (forceUnsigned (a.lo shl (32 - offset)))))
    else:
      (forceUnsigned ((a.hi shr (offset - 32)) or (forceUnsigned (a.lo shl (64 - offset)))),
       forceUnsigned ((a.lo shr (offset - 32)) or (forceUnsigned (a.hi shl (64 - offset)))))
else:
  type
    CompatUint64* = uint64

func `$`*[n: static[int]](digest: array[n, char]): string =
  ## Transforms a message digest into its canonical lower-hex-string form.
  result = newStringOfCap(n * 2)

  for octet in digest:
    result &= octet.uint32.toHex(2)

  result = result.toLowerAscii()
