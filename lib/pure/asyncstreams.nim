import asyncfutures

import deques

type
  FutureStream*[T] = ref object   ## Special future that acts as
                                  ## a queue. Its API is still
                                  ## experimental and so is
                                  ## subject to change.
    values: Deque[T]
    readers: Deque[Future[(bool, T)]]
    finished: bool

proc newFutureStream*[T](fromProc = "unspecified"): FutureStream[T] =
  ## Create a new ``FutureStream``. This future's callback is activated when
  ## two events occur:
  ##
  ## * New data is written into the future stream.
  ## * The future stream is completed (this means that no more data will be
  ##   written).
  ##
  ## Specifying ``fromProc``, which is a string specifying the name of the proc
  ## that this future belongs to, is a good habit as it helps with debugging.
  ##
  ## **Note:** The API of FutureStream is still new and so has a higher
  ## likelihood of changing in the future.
  FutureStream[T](
    finished: false,
    values: initDeque[T](),
    readers: initDeque[Future[(bool, T)]]())

proc wakeReaders[T](future: FutureStream[T]) =
  ## Wake pending readers, if possible.
  while future.values.len > 0 and future.readers.len > 0:
    let rf = future.readers.popFirst
    rf.complete((true, future.values.popFirst))
  while future.finished and future.readers.len > 0:
    var res: (bool, T)
    let rf = future.readers.popFirst
    rf.complete(res)

proc complete*[T](future: FutureStream[T]) =
  ## Completes a ``FutureStream`` signalling the end of data.
  future.finished = true
  wakeReaders(future)

proc finished*[T](future: FutureStream[T]): bool =
  ## Check if a ``FutureStream`` is finished. ``true`` value means that
  ## no more data will be placed inside the stream _and_ that there is
  ## no data waiting to be retrieved.
  result = future.finished and future.values.len == 0

proc write*[T](future: FutureStream[T], value: T): Future[void] =
  ## Writes the specified value inside the specified future stream.
  ##
  ## This will raise ``ValueError`` if ``future`` is finished.
  result = newFuture[void]("FutureStream.put")
  if future.finished:
    let msg = "FutureStream is finished and so no longer accepts new data."
    result.fail(newException(ValueError, msg))
    return
  # TODO: Implement limiting of the streams storage to prevent it growing
  # infinitely when no reads are occuring.
  future.values.addLast(value)
  if future.readers.len > 0:
    wakeReaders(future)
  result.complete()

proc read*[T](future: FutureStream[T]): Future[(bool, T)] =
  ## Returns a future that will complete when the ``FutureStream`` has data
  ## placed into it. The future will be completed with the oldest
  ## value stored inside the stream. The return value will also determine
  ## whether data was retrieved, ``false`` means that the future stream was
  ## completed and no data was retrieved.
  ##
  ## This function will remove the data that was returned from the underlying
  ## ``FutureStream``.
  result = newFuture[(bool, T)]("FutureStream.read")
  future.readers.addLast(result)
  wakeReaders(future)

proc len*[T](future: FutureStream[T]): int =
  ## Returns the amount of data pieces inside the stream.
  future.values.len
