discard """
  matrix: "--backend:c --mm:refc; --backend:c --mm:orc; --backend:c --mm:orc --strings:sso; --backend:cpp --mm:refc; --backend:cpp --mm:orc; --backend:js --mm:refc; --backend:js --mm:orc"
"""

from std/sequtils import toSeq, map
from std/sugar import `=>`
import std/assertions

const hasNativeSso = defined(nimsso) and
  (defined(gcArc) or defined(gcAtomicArc) or defined(gcOrc) or defined(gcYrc))

proc tester[T](x: T) =
  let test = toSeq(0..4).map(i => newSeq[int]())
  doAssert $test == "@[@[], @[], @[], @[], @[]]"

when not hasNativeSso:
  func reverse*(a: string): string =
    result = a
    for i in 0 ..< a.len div 2:
      let j = result.len - i - 1
      swap(result[i], result[j])

proc main() =
  block: # ..
    const
      characters = "abcdefghijklmnopqrstuvwxyz"
      numbers = "1234567890"

    # test "slice of length == len(characters)":
    # replace characters completely by numbers
    var s: string
    s = characters
    s[0..^1] = numbers
    doAssert s == numbers

    # test "slice of length > len(numbers)":
    # replace characters by slice of same length
    s = characters
    s[1..16] = numbers
    doAssert s == "a1234567890rstuvwxyz"

    # test "slice of length == len(numbers)":
    # replace characters by slice of same length
    s = characters
    s[1..10] = numbers
    doAssert s == "a1234567890lmnopqrstuvwxyz"

    # test "slice of length < len(numbers)":
    # replace slice of length. and insert remaining chars
    s = characters
    s[1..4] = numbers
    doAssert s == "a1234567890fghijklmnopqrstuvwxyz"

    # test "slice of length == 1":
    # replace first character. and insert remaining 9 chars
    s = characters
    s[1..1] = numbers
    doAssert s == "a1234567890cdefghijklmnopqrstuvwxyz"

    # test "slice of length == 0":
    # insert chars at slice start index
    s = characters
    s[2..1] = numbers
    doAssert s == "ab1234567890cdefghijklmnopqrstuvwxyz"

    # test "slice of negative length":
    # same as slice of zero length
    s = characters
    s[2..0] = numbers
    doAssert s == "ab1234567890cdefghijklmnopqrstuvwxyz"

    when nimvm:
      discard
    else:
      # bug #6223
      doAssertRaises(IndexDefect):
        discard s[0..999]

  block: # ==, cmp
    let world = "hello\0world"
    let earth = "hello\0earth"
    let short = "hello\0"
    let hello = "hello"
    let goodbye = "goodbye"

    doAssert world == world
    doAssert world != earth
    doAssert world != short
    doAssert world != hello
    doAssert world != goodbye

    doAssert cmp(world, world) == 0
    doAssert cmp(world, earth) > 0
    doAssert cmp(world, short) > 0
    doAssert cmp(world, hello) > 0
    doAssert cmp(world, goodbye) > 0

  block: # bug #7816
    tester(1)

  when not hasNativeSso:
    block: # bug #14497, reverse
      doAssert reverse("hello") == "olleh"

  block: # len, high
    var a = "ab\0cd"
    doAssert a.len == 5
    doAssert a.high == a.len - 1

    when not (hasNativeSso and defined(cpp)):
      let b = a.cstring
      block: # bug #16405
        when defined(js):
          when nimvm: doAssert b.len == 2
          else: doAssert b.len == 5
        else: doAssert b.len == 2
      doAssert b.high == b.len - 1

    doAssert "".len == 0
    doAssert "".high == -1
    when not (hasNativeSso and defined(cpp)):
      doAssert "".cstring.len == 0
      doAssert "".cstring.high == -1

    block: # bug #16674
      var c: cstring = nil
      doAssert c.len == 0
      doAssert c.high == -1

  block: # setLen, setLenUninit
    when hasNativeSso:
      const
        alwaysAvail = sizeof(uint) - 1
        payloadSize = sizeof(uint) + sizeof(pointer) - 2
        longStringDataOffset = 3 * sizeof(int)

      template rawSlenOf(s: string): int =
        int(cast[ptr byte](unsafeAddr s)[])

      template inlineDataOf(s: string): ptr UncheckedArray[char] =
        cast[ptr UncheckedArray[char]](cast[uint](unsafeAddr s) + 1'u)

      template longDataOf(s: string): ptr UncheckedArray[char] =
        let ssPtr = cast[ptr tuple[bytes: uint, more: pointer]](unsafeAddr s)
        cast[ptr UncheckedArray[char]](
          cast[uint](ssPtr.more) + uint(longStringDataOffset))

    proc checkStrInternals(s: string; expectedLen: int) =
      doAssert s.len == expectedLen, "expected " & $expectedLen & ", got " & $s.len
      when nimvm:
        discard
      else:
        when hasNativeSso and not defined(js) and not defined(nimscript):
          # SSO
          let rawSlen = rawSlenOf(s)
          if rawSlen > payloadSize:
            doAssert rawSlen == 255
            let data = longDataOf(s)
            doAssert data[expectedLen] == '\0'
          else:
            doAssert rawSlen == expectedLen
            let data = inlineDataOf(s)
            doAssert data[expectedLen] == '\0'
            if expectedLen < alwaysAvail:
              for i in expectedLen + 1 ..< alwaysAvail:
                doAssert data[i] == '\0'
        elif defined(UncheckedArray): # skip JS
          # string V2
          let cs = s.cstring
          let arr = cast[ptr UncheckedArray[char]](unsafeAddr cs[0])
          doAssert arr[expectedLen] == '\0'

    proc makeStr(n: int): string =
      result = newStringOfCap(n)
      for i in 0..<n:
        result.add char(ord('a') + i mod 26)

    proc checkSetLenUninit(oldLen, newLen: int; cmpAfter = -1) =
      var s = makeStr(oldLen)
      let prefixLen = min(oldLen, newLen)
      let prefix = makeStr(prefixLen)
      s.setLenUninit(newLen)
      s.checkStrInternals(newLen)
      doAssert s[0..<prefixLen] == prefix
      if newLen <= oldLen:
        doAssert s == prefix
      if cmpAfter >= 0:
        doAssert s < makeStr(cmpAfter)

    const numbers = "1234567890"
    block setLen:
      # Trim to zero and grow past the old end. Must keep the prefix and zero the tail.
      var s = numbers
      s.setLen(0)
      s.checkStrInternals(0)
      doAssert s == ""

      s = numbers
      s.setLen(numbers.len + 1)
      s.checkStrInternals(numbers.len + 1)
      doAssert s[0..numbers.high] == numbers
      doAssert s[numbers.len] == '\0'

    block setLenUninit:
      # Shared baseline for both SSO and V2: noop, shrink, grow.
      checkSetLenUninit(numbers.len, numbers.len)
      checkSetLenUninit(numbers.len, 5)
      checkSetLenUninit(numbers.len, 11)

      when hasNativeSso:
        const
          shortLen = alwaysAvail
          medLen = payloadSize
          longLen = payloadSize + 8

        # Staying short and verify short-compare padding after shrink.
        checkSetLenUninit(shortLen, shortLen - 1, shortLen)
        checkSetLenUninit(shortLen - 2, shortLen - 1)
        checkSetLenUninit(shortLen, 0)

        # Cross the short/medium boundary in both directions.
        checkSetLenUninit(medLen, medLen - 1)
        checkSetLenUninit(medLen, alwaysAvail - 1, alwaysAvail)
        checkSetLenUninit(alwaysAvail, medLen)

        # Cross the inline/long boundary in both directions and cover long growth.
        checkSetLenUninit(longLen, longLen - 2)
        checkSetLenUninit(longLen, medLen - 1)
        checkSetLenUninit(longLen, alwaysAvail - 1, alwaysAvail)
        checkSetLenUninit(medLen, longLen)
        checkSetLenUninit(longLen, longLen + 10)
        checkSetLenUninit(longLen, 0)

        when not defined(js) and not defined(nimscript):
          # shared long strings must not mutate the original when grown
          let src = makeStr(longLen)
          var orig = src
          var copy = orig
          copy.setLenUninit(longLen + 4)
          copy.checkStrInternals(longLen + 4)
          doAssert orig == src
          doAssert copy[0..<longLen] == src

static: main()
main()
