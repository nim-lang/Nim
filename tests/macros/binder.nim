# example from #7889

from streams import newStringStream, readData, writeData
import experimental/quote2

macro bindme*(): untyped =
  quoteAst(newStringStream = bindSym"newStringStream", writeData = bindSym"writeData", readData = bindSym"readData"):
    var tst = "sometext"
    var ss = newStringStream("anothertext")
    writeData(ss, tst[0].addr, 2)
    discard readData(ss, tst[0].addr, 2)
