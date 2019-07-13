import std/macros

## using a enum instead of, say, int, to make apparent potential bugs related to
## forgetting converting to NimNode via newLit, see https://github.com/nim-lang/Nim/issues/9607

type Foo* = enum kfoo0, kfoo1, kfoo2, kfoo3, kfoo4

proc myLocalPriv(): auto = kfoo1
proc myLocalPriv2(): auto = kfoo1
macro bindme2*(): untyped =
  genAst({}) do: myLocalPriv()
macro bindme3*(): untyped =
  ## myLocalPriv must be captured explicitly
  genAst({kNoExposeLocalInjects}, myLocalPriv) do: myLocalPriv()

macro bindme4*(): untyped =
  ## calling this won't compile because `myLocalPriv` isn't captured
  genAst({kNoExposeLocalInjects}) do: myLocalPriv()

macro bindme5UseExpose*(): untyped =
  genAst({}) do: myLocalPriv2()

macro bindme5UseExposeFalse*(): untyped =
  genAst({kNoExposeLocalInjects}) do: myLocalPriv2()

## example from https://github.com/nim-lang/Nim/issues/7889
from std/streams import newStringStream, readData, writeData

macro bindme6UseExpose*(): untyped =
  genAst({}) do:
    var tst = "sometext"
    var ss = newStringStream("anothertext")
    writeData(ss, tst[0].addr, 2)
    discard readData(ss, tst[0].addr, 2)

macro bindme6UseExposeFalse*(): untyped =
  ## without kexposeLocalInjects, requires passing all referenced symbols
  ## which can be tedious
  genAst({kNoExposeLocalInjects}, newStringStream, writeData, readData) do:
    var tst = "sometext"
    var ss = newStringStream("anothertext")
    writeData(ss, tst[0].addr, 2)
    discard readData(ss, tst[0].addr, 2)
