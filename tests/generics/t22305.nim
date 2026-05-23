discard """
  joinable: false
"""

import asyncdispatch, options

proc recv*[T](tc: ptr Channel[T]): Future[T] {.async.} =
  discard

type SharedBuf = object

type WorkProc[A, B] = proc(a: A): Option[B] {.nimcall.}

proc worker[TArg](p: TArg) {.thread, nimcall.} =
  discard

proc readFilesThread() =
  type TArg[A, B] =
    tuple[r: ptr Channel[Option[A]], w: ptr Channel[Option[B]], p: WorkProc[A, B]]

  var readThread: Thread[TArg[int, SharedBuf]]

proc readFilesAd() {.async.} =
  var readChan: Channel[Option[int]]

  type TArg[A, B] =
    tuple[r: ptr Channel[Option[A]], w: ptr Channel[Option[B]], p: WorkProc[A, B]]

  var readThread: Thread[TArg[int, SharedBuf]]
  let test = await (addr readChan).recv()

  joinThread(readThread)

waitFor readFilesAd()

type
  SharedPtr[T] = object
    p: ptr T

proc `=destroy`[T](self: var SharedPtr[T]) =
  discard

type
  SomethingObj[T] = object
  Something[T] = SharedPtr[SomethingObj[T]]

proc useSomething() =
  # discard Something[int]() # When you uncomment this line, it will compile successfully.
  discard Something[float]()

proc fn() =
  let thing = Something[int]()
  proc closure() =
    discard thing
  closure()

fn()