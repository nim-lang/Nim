from std/streams import newStringStream, readData, writeData
import std/macros

macro bindme*(): untyped =
  genAst(newStringStream, writeData, readData) do:
    var tst = "sometext"
    var ss = newStringStream("anothertext")
    writeData(ss, tst[0].addr, 2)
    discard readData(ss, tst[0].addr, 2)
