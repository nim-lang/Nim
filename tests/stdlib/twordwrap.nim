import std/wordwrap

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