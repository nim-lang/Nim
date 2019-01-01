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

proc olen(s: string): int =
  var i = 0
  result = 0
  while i < s.len:
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
  for word, isSep in tokenize(s, seps):
    let wlen = olen(word)
    if isSep:
      lastSep = word
      spaceLeft = spaceLeft - wlen
    elif wlen > spaceLeft:
      if splitLongWords and wlen > maxLineWidth:
        var i = 0
        while i < word.len:
          if spaceLeft <= 0:
            spaceLeft = maxLineWidth
            result.add newLine
          dec spaceLeft
          let L = graphemeLen(word, i)
          for j in 0 ..< L: result.add word[i+j]
          inc i, L
      else:
        spaceLeft = maxLineWidth - wlen
        result.add(newLine)
        result.add(word)
    else:
      spaceLeft = spaceLeft - wlen
      result.add(lastSep)
      result.add(word)
      lastSep.setLen(0)

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

