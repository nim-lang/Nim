import std/macros

## using a enum instead of, say, int, to make apparent potential bugs related to
## forgetting converting to NimNode via newLit, see https://github.com/nim-lang/Nim/issues/9607

type Foo* = enum kfoo0, kfoo1, kfoo2, kfoo3, kfoo4

proc myLocalPriv(): auto = kfoo1
proc myLocalPriv2(): auto = kfoo1
macro bindme2*(): untyped =
  genAst: myLocalPriv()
macro bindme3*(): untyped =
  ## myLocalPriv must be captured explicitly
  genAstOpt({kNoExposeLocalInjects}, myLocalPriv): myLocalPriv()

macro bindme4*(): untyped =
  ## calling this won't compile because `myLocalPriv` isn't captured
  genAstOpt({kNoExposeLocalInjects}): myLocalPriv()

macro bindme5UseExpose*(): untyped =
  genAst: myLocalPriv2()

macro bindme5UseExposeFalse*(): untyped =
  genAstOpt({kNoExposeLocalInjects}): myLocalPriv2()

## example from https://github.com/nim-lang/Nim/issues/7889
from std/streams import newStringStream, readData, writeData

macro bindme6UseExpose*(): untyped =
  genAst:
    var tst = "sometext"
    var ss = newStringStream("anothertext")
    writeData(ss, tst[0].addr, 2)
    discard readData(ss, tst[0].addr, 2)

macro bindme6UseExposeFalse*(): untyped =
  ## without kexposeLocalInjects, requires passing all referenced symbols
  ## which can be tedious
  genAstOpt({kNoExposeLocalInjects}, newStringStream, writeData, readData):
    var tst = "sometext"
    var ss = newStringStream("anothertext")
    writeData(ss, tst[0].addr, 2)
    discard readData(ss, tst[0].addr, 2)
