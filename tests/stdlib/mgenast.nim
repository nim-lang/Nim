import std/genasts
import std/macros

# Using a enum instead of, say, int, to make apparent potential bugs related to
# forgetting converting to NimNode via newLit, see bug #9607

type Foo* = enum kfoo0, kfoo1, kfoo2, kfoo3, kfoo4

proc myLocalPriv(): auto = kfoo1
proc myLocalPriv2(): auto = kfoo1
macro bindme2*(): untyped =
  genAst: myLocalPriv()
macro bindme3*(): untyped =
  ## myLocalPriv must be captured explicitly
  genAstOpt({kDirtyTemplate}, myLocalPriv): myLocalPriv()

macro bindme4*(): untyped =
  ## calling this won't compile because `myLocalPriv` isn't captured
  genAstOpt({kDirtyTemplate}): myLocalPriv()

macro bindme5UseExpose*(): untyped =
  genAst: myLocalPriv2()

macro bindme5UseExposeFalse*(): untyped =
  genAstOpt({kDirtyTemplate}): myLocalPriv2()

# example from bug #7889
from std/streams import newStringStream, readData, writeData

macro bindme6UseExpose*(): untyped =
  genAst:
    var tst = "sometext"
    var ss = newStringStream("anothertext")
    writeData(ss, tst[0].addr, 2)
    discard readData(ss, tst[0].addr, 2)

macro bindme6UseExposeFalse*(): untyped =
  ## with `kDirtyTemplate`, requires passing all referenced symbols
  ## which can be tedious
  genAstOpt({kDirtyTemplate}, newStringStream, writeData, readData):
    var tst = "sometext"
    var ss = newStringStream("anothertext")
    writeData(ss, tst[0].addr, 2)
    discard readData(ss, tst[0].addr, 2)


proc locafun1(): auto = "in locafun1"
proc locafun2(): auto = "in locafun2"
# locafun3 in caller scope only
macro mixinExample*(): untyped =
  genAst:
    mixin locafun1
    (locafun1(), locafun2(), locafun3())
