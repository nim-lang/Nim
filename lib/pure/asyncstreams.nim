#
#
#            Nim's Runtime Library
#        (c) Copyright 2015 Dominik Picheta
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## Unstable API.

import asyncfutures

import deques

type
  FutureStream*[T] = ref object ## Special future that acts as
                                ## a queue. Its API is still
                                ## experimental and so is
                                ## subject to change.
    queue: Deque[T]
    finished: bool
    cb: proc () {.closure, gcsafe.}
    error*: ref Exception

proc newFutureStream*[T](fromProc = "unspecified"): FutureStream[T] =
  ## Create a new `FutureStream`. This future's callback is activated when
  ## two events occur:
  ##
  ## * New data is written into the future stream.
  ## * The future stream is completed (this means that no more data will be
  ##   written).
  ##
  ## Specifying `fromProc`, which is a string specifying the name of the proc
  ## that this future belongs to, is a good habit as it helps with debugging.
  ##
  ## **Note:** The API of FutureStream is still new and so has a higher
  ## likelihood of changing in the future.
  result = FutureStream[T](finished: false, cb: nil)
  result.queue = initDeque[T]()

proc complete*[T](future: FutureStream[T]) =
  ## Completes a `FutureStream` signalling the end of data.
  assert(future.error == nil, "Trying to complete failed stream")
  future.finished = true
  if not future.cb.isNil:
    future.cb()

proc fail*[T](future: FutureStream[T], error: ref Exception) =
  ## Completes `future` with `error`.
  assert(not future.finished)
  future.finished = true
  future.error = error
  if not future.cb.isNil:
    future.cb()

proc `callback=`*[T](future: FutureStream[T],
    cb: proc (future: FutureStream[T]) {.closure, gcsafe.}) =
  ## Sets the callback proc to be called when data was placed inside the
  ## future stream.
  ##
  ## The callback is also called when the future is completed. So you should
  ## use `finished` to check whether data is available.
  ##
  ## If the future stream already has data or is finished then `cb` will be
  ## called immediately.
  proc named() = cb(future)
  future.cb = named
  if future.queue.len > 0 or future.finished:
    callSoon(future.cb)

proc finished*[T](future: FutureStream[T]): bool =
  ## Check if a `FutureStream` is finished. `true` value means that
  ## no more data will be placed inside the stream *and* that there is
  ## no data waiting to be retrieved.
  result = future.finished and future.queue.len == 0

proc failed*[T](future: FutureStream[T]): bool =
  ## Determines whether `future` completed with an error.
  return future.error != nil

proc write*[T](future: FutureStream[T], value: T): Future[void] =
  ## Writes the specified value inside the specified future stream.
  ##
  ## This will raise `ValueError` if `future` is finished.
  result = newFuture[void]("FutureStream.put")
  if future.finished:
    let msg = "FutureStream is finished and so no longer accepts new data."
    result.fail(newException(ValueError, msg))
    return
  # TODO: Implement limiting of the streams storage to prevent it growing
  # infinitely when no reads are occurring.
  future.queue.addLast(value)
  if not future.cb.isNil: future.cb()
  result.complete()

proc read*[T](future: FutureStream[T]): owned(Future[(bool, T)]) =
  ## Returns a future that will complete when the `FutureStream` has data
  ## placed into it. The future will be completed with the oldest
  ## value stored inside the stream. The return value will also determine
  ## whether data was retrieved, `false` means that the future stream was
  ## completed and no data was retrieved.
  ##
  ## This function will remove the data that was returned from the underlying
  ## `FutureStream`.
  var resFut = newFuture[(bool, T)]("FutureStream.take")
  let savedCb = future.cb
  proc newCb(fs: FutureStream[T]) =
    # Exit early if `resFut` is already complete. (See #8994).
    if resFut.finished: return

    # We don't want this callback called again.
    #future.cb = nil

    # The return value depends on whether the FutureStream has finished.
    var res: (bool, T)
    if finished(fs):
      # Remember, this callback is called when the FutureStream is completed.
      res[0] = false
    else:
      res[0] = true
      res[1] = fs.queue.popFirst()

    if fs.failed:
      resFut.fail(fs.error)
    else:
      resFut.complete(res)

    # If the saved callback isn't nil then let's call it.
    if not savedCb.isNil:
      if fs.queue.len > 0:
        savedCb()
      else:
        future.cb = savedCb

  if future.queue.len > 0 or future.finished:
    newCb(future)
  else:
    future.callback = newCb
  return resFut

proc len*[T](future: FutureStream[T]): int =
  ## Returns the amount of data pieces inside the stream.
  future.queue.len
