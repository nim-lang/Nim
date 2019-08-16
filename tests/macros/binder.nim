# example from #7889

from streams import newStringStream, readData, writeData
import macros

macro bindme*(): untyped =
  let newStringStream = bindSym"newStringStream"
  let writeData = bindSym"writeData"
  let readData = bindSym"readData"
  result = quoteAst(newStringStream, writeData, readData):
    var tst = "sometext"
    var ss = newStringStream("anothertext")
    writeData(ss, tst[0].addr, 2)
    discard readData(ss, tst[0].addr, 2)
