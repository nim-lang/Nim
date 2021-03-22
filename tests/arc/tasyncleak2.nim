discard """
  output: "success"
  cmd: "nim c --gc:orc $file"
"""

# issue #15076
import deques, strutils, asyncdispatch

proc doNothing(): Future[void] =
  #[
  var
    :env
    :env_1
  try:
    `=destroy`(:env)
    internalNew(:env)
    `=sink`(:env.retFuture1, newFuture("doNothing"))

    `=destroy_1`(:env_1)
    internalNew(:env_1)
    `=`(:env_1.:up, :env)
    `=sink_1`(:env.nameIterVar2, (doNothingIter, :env_1))

    (doNothingNimAsyncContinue, :env)()
    return `=_1`(result, :env.retFuture1)
  finally:
    `=destroy`(:env)
  ]#

  var retFuture = newFuture[void]("doNothing")
  iterator doNothingIter(): FutureBase {.closure.} =
    # inspected ARC code: looks correct!
    block:
      var qqq = initDeque[string]()
      for i in 0 .. 1000:
        qqq.addLast($i)
    complete(retFuture) # env.up.retFuture1

  var nameIterVar = doNothingIter  # iter_Env -> retFuture ->

  proc doNothingNimAsyncContinue() {.closure.} =
    # inspected ARC code: looks correct
    if not nameIterVar.finished:
      var next_gensym0 = nameIterVar()
      while (not next_gensym0.isNil) and next_gensym0.finished:
        next_gensym0 = nameIterVar()
        if nameIterVar.finished:
          break
      if next_gensym0 != nil:
        {.gcsafe.}:
          next_gensym0.addCallback cast[proc () {.closure, gcsafe.}](doNothingNimAsyncContinue)

  doNothingNimAsyncContinue()
  return retFuture

proc main(): Future[void] =
  template await[T](f_gensym12: Future[T]): auto {.used.} =
    var internalTmpFuture_gensym12: FutureBase = f_gensym12
    yield internalTmpFuture_gensym12
    (cast[typeof(f_gensym12)](internalTmpFuture_gensym12)).read()

  var retFuture = newFuture[void]("main")
  iterator mainIter(): FutureBase {.closure.} =
    block:
      for x in 0 .. 1000:
        await doNothing()
    complete(retFuture)

  var nameIterVar_gensym11 = mainIter
  proc mainNimAsyncContinue() {.closure.} =
    if not nameIterVar_gensym11.finished:
      var next_gensym11 = unown nameIterVar_gensym11()
      while (not next_gensym11.isNil) and next_gensym11.finished:
        next_gensym11 = unown nameIterVar_gensym11()
        if nameIterVar_gensym11.finished:
          break
      if next_gensym11 != nil:
        {.gcsafe.}:
          next_gensym11.addCallback cast[proc () {.closure, gcsafe.}](mainNimAsyncContinue)

  mainNimAsyncContinue()
  return retFuture

for i in 0..9:
  waitFor main()
  GC_fullCollect()
  doAssert getOccupiedMem() < 1024
echo "success"
