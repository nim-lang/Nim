discard """
  action: run
"""

import asyncdispatch, os

proc wrap(fut: Future[void]): Future[void] =
  result = newFuture[void]("wrap")
  let retFuture = result
  fut.addCallback proc () =
    if fut.failed:
      retFuture.fail(fut.error)
    else:
      retFuture.complete()

block:
  let root = newFuture[void]("root")
  let wrapped = wrap(wrap(wrap(root)))
  let completedBeforeDeadline = withTimeout(wrapped, 20)

  # Completion has happened at the bottom of the future chain, but its
  # callbacks cannot propagate until control reaches the dispatcher.
  root.complete()
  sleep(40)

  doAssert waitFor(completedBeforeDeadline)

block:
  var callbackRan = false
  sleepAsync(0).addCallback proc () = callbackRan = true
  poll(0)
  doAssert callbackRan
