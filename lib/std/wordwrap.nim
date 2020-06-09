#
#
#            Nim's Runtime Library
#        (c) Copyright 2018 Nim contributors
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## This module contains an algorithm to wordwrap a Unicode string.

import strutils, unicode

proc olen(s: string; start, lastExclusive: int): int =
  var i = start
  result = 0
  while i < lastExclusive:
    inc result
    let L = graphemeLen(s, i)
    inc i, L

proc wrapWords*(s: string, maxLineWidth = 80,
               splitLongWords = true,
               seps: set[char] = Whitespace,
               newLine = "\n"): string {.noSideEffect.} =
  ## Word wraps `s`.
  runnableExamples:
    doAssert "12345678901234567890".wrapWords() == "12345678901234567890"
    doAssert "123456789012345678901234567890".wrapWords(20) == "12345678901234567890\n1234567890"
    doAssert "Hello Bob. Hello John.".wrapWords(13, false) == "Hello Bob.\nHello John."
    doAssert "Hello Bob. Hello John.".wrapWords(13, true, {';'}) == "Hello Bob. He\nllo John."
  result = newStringOfCap(s.len + s.len shr 6)
  var spaceLeft = maxLineWidth
  var lastSep = ""

  var i = 0
  while true:
    var j = i
    let isSep = j < s.len and s[j] in seps
    while j < s.len and (s[j] in seps) == isSep: inc(j)
    if j <= i: break
    #yield (substr(s, i, j-1), isSep)
    if isSep:
      lastSep.setLen 0
      for k in i..<j:
        if s[k] notin {'\L', '\C'}: lastSep.add s[k]
      if lastSep.len == 0:
        lastSep.add ' '
        dec spaceLeft
      else:
        spaceLeft = spaceLeft - olen(lastSep, 0, lastSep.len)
    else:
      let wlen = olen(s, i, j)
      if wlen > spaceLeft:
        if splitLongWords and wlen > maxLineWidth:
          var k = 0
          while k < j - i:
            if spaceLeft <= 0:
              spaceLeft = maxLineWidth
              result.add newLine
            dec spaceLeft
            let L = graphemeLen(s, k+i)
            for m in 0 ..< L: result.add s[i+k+m]
            inc k, L
        else:
          spaceLeft = maxLineWidth - wlen
          result.add(newLine)
          for k in i..<j: result.add(s[k])
      else:
        spaceLeft = spaceLeft - wlen
        result.add(lastSep)
        for k in i..<j: result.add(s[k])
        #lastSep.setLen(0)
    i = j

when isMainModule:

  when true:
    let
      inp = """ this is a long text --  muchlongerthan10chars and here
                 it goes"""
      outp = " this is a\nlong text\n--\nmuchlongerthan10chars\nand here\nit goes"
    doAssert wrapWords(inp, 10, false) == outp

    let
      longInp = """ThisIsOneVeryLongStringWhichWeWillSplitIntoEightSeparatePartsNow"""
      longOutp = "ThisIsOn\neVeryLon\ngStringW\nhichWeWi\nllSplitI\nntoEight\nSeparate\nPartsNow"
    doAssert wrapWords(longInp, 8, true) == longOutp

  # test we don't break Umlauts into invalid bytes:
  let fies = "äöüöäöüöäöüöäöüööäöüöäößßßßüöäößßßßßß"
  let fiesRes = "ä\nö\nü\nö\nä\nö\nü\nö\nä\nö\nü\nö\nä\nö\nü\nö\nö\nä\nö\nü\nö\nä\nö\nß\nß\nß\nß\nü\nö\nä\nö\nß\nß\nß\nß\nß\nß"
  doAssert wrapWords(fies, 1, true) == fiesRes

  let longlongword = """abc uitdaeröägfßhydüäpydqfü,träpydqgpmüdträpydföägpydörztdüöäfguiaeowäzjdtrüöäp psnrtuiydrözenrüöäpyfdqazpesnrtulocjtüö
äzydgyqgfqfgprtnwjlcydkqgfüöezmäzydydqüüöäpdtrnvwfhgckdumböäpydfgtdgfhtdrntdrntydfogiayqfguiatrnydrntüöärtniaoeydfgaoeiqfglwcßqfgxvlcwgtfhiaoen
rsüöäapmböäptdrniaoydfglckqfhouenrtsüöäptrniaoeyqfgulocfqclgwxßqflgcwßqfxglcwrniatrnmüböäpmöäbpümöäbpüöämpbaoestnriaesnrtdiaesrtdniaesdrtnaetdr
iaoenvlcyfglwckßqfgvwkßqgfvlwkßqfgvlwckßqvlwkgfUIαοιαοιαχολωχσωχνωκψρχκψρτιεαοσηζϵηζιοεννκεωνιαλωσωκνκψρκγτφγτχκγτεκργτιχνκιωχσιλωσλωχξλξλξωχωχ
ξχλωωχαοεοιαεοαεοιαεοαεοιαοεσναοεκνρκψγκψφϵιηαααοε"""
  let longlongwordRes = """
abc uitdaeröägfßhydüäpydqfü,träpydqgpmüdträpydföägpydörztdüöäfguiaeowäzjdtrüöäp
psnrtuiydrözenrüöäpyfdqazpesnrtulocjtüöäzydgyqgfqfgprtnwjlcydkqgfüöezmäzydydqüü
öäpdtrnvwfhgckdumböäpydfgtdgfhtdrntdrntydfogiayqfguiatrnydrntüöärtniaoeydfgaoeiq
fglwcßqfgxvlcwgtfhiaoenrsüöäapmböäptdrniaoydfglckqfhouenrtsüöäptrniaoeyqfgulocf
qclgwxßqflgcwßqfxglcwrniatrnmüböäpmöäbpümöäbpüöämpbaoestnriaesnrtdiaesrtdniaesdr
tnaetdriaoenvlcyfglwckßqfgvwkßqgfvlwkßqfgvlwckßqvlwkgfUIαοιαοιαχολωχσωχνωκψρχκψ
ρτιεαοσηζϵηζιοεννκεωνιαλωσωκνκψρκγτφγτχκγτεκργτιχνκιωχσιλωσλωχξλξλξωχωχ
ξχλωωχαοεοιαεοαεοιαεοαεοιαοεσναοεκνρκψγκψφϵιηαααοε"""
  doAssert wrapWords(longlongword) == longlongwordRes

  # bug #14579
  const input60 = """
This string is wrapped to 60 characters. If we call
wrapwords on it it will be re-wrapped to 80 characters.
"""
  const input60Res = """This string is wrapped to 60 characters. If we call wrapwords on it it will be
re-wrapped to 80 characters."""
  doAssert wrapWords(input60) == input60Res
