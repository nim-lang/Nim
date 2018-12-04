#
#
#            Nim's Runtime Library
#        (c) Copyright 2012 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## `Actor`:idx: support for Nim. An actor is implemented as a thread with
## a channel as its inbox. This module requires the ``--threads:on``
## command line switch.
##
## Example:
##
## .. code-block:: nim
##
##      var
##        a: ActorPool[int, void]
##      createActorPool(a)
##      for i in 0 ..< 300:
##        a.spawn(i, proc (x: int) {.thread.} = echo x)
##      a.join()
##
## **Note**: This whole module is deprecated. Use `threadpool` and ``spawn``
## instead.

{.deprecated.}

from os import sleep

type
  Task*[In, Out] = object{.pure, final.} ## a task
    when Out isnot void:
      receiver*: ptr Channel[Out] ## the receiver channel of the response
    action*: proc (x: In): Out {.thread.} ## action to execute;
                                            ## sometimes useful
    shutDown*: bool ## set to tell an actor to shut-down
    data*: In ## the data to process

  Actor[In, Out] = object{.pure, final.}
    i: Channel[Task[In, Out]]
    t: Thread[ptr Actor[In, Out]]

  PActor*[In, Out] = ptr Actor[In, Out] ## an actor

proc spawn*[In, Out](action: proc(
    self: PActor[In, Out]){.thread.}): PActor[In, Out] =
  ## creates an actor; that is a thread with an inbox. The caller MUST call
  ## ``join`` because that also frees the actor's associated resources.
  result = cast[PActor[In, Out]](allocShared0(sizeof(result[])))
  open(result.i)
  createThread(result.t, action, result)

proc inbox*[In, Out](self: PActor[In, Out]): ptr Channel[In] =
  ## gets a pointer to the associated inbox of the actor `self`.
  result = addr(self.i)

proc running*[In, Out](a: PActor[In, Out]): bool =
  ## returns true if the actor `a` is running.
  result = running(a.t)

proc ready*[In, Out](a: PActor[In, Out]): bool =
  ## returns true if the actor `a` is ready to process new messages.
  result = ready(a.i)

proc join*[In, Out](a: PActor[In, Out]) =
  ## joins an actor.
  joinThread(a.t)
  close(a.i)
  deallocShared(a)

proc recv*[In, Out](a: PActor[In, Out]): Task[In, Out] =
  ## receives a task from `a`'s inbox.
  result = recv(a.i)

proc send*[In, Out, X, Y](receiver: PActor[In, Out], msg: In,
                            sender: PActor[X, Y]) =
  ## sends a message to `a`'s inbox.
  var t: Task[In, Out]
  t.receiver = addr(sender.i)
  shallowCopy(t.data, msg)
  send(receiver.i, t)

proc send*[In, Out](receiver: PActor[In, Out], msg: In,
                      sender: ptr Channel[Out] = nil) =
  ## sends a message to `receiver`'s inbox.
  var t: Task[In, Out]
  t.receiver = sender
  shallowCopy(t.data, msg)
  send(receiver.i, t)

proc sendShutdown*[In, Out](receiver: PActor[In, Out]) =
  ## send a shutdown message to `receiver`.
  var t: Task[In, Out]
  t.shutdown = true
  send(receiver.i, t)

proc reply*[In, Out](t: Task[In, Out], m: Out) =
  ## sends a message to io's output message box.
  when Out is void:
    {.error: "you cannot reply to a void outbox".}
  assert t.receiver != nil
  send(t.receiver[], m)


# ----------------- actor pools ----------------------------------------------

type
  ActorPool*[In, Out] = object{.pure, final.}  ## an actor pool
    actors: seq[PActor[In, Out]]
    when Out isnot void:
      outputs: Channel[Out]

proc `^`*[T](f: ptr Channel[T]): T =
  ## alias for 'recv'.
  result = recv(f[])

proc poolWorker[In, Out](self: PActor[In, Out]) {.thread.} =
  while true:
    var m = self.recv
    if m.shutDown: break
    when Out is void:
      m.action(m.data)
    else:
      send(m.receiver[], m.action(m.data))
      #self.reply()

proc createActorPool*[In, Out](a: var ActorPool[In, Out], poolSize = 4) =
  ## creates an actor pool.
  newSeq(a.actors, poolSize)
  when Out isnot void:
    open(a.outputs)
  for i in 0 ..< a.actors.len:
    a.actors[i] = spawn(poolWorker[In, Out])

proc sync*[In, Out](a: var ActorPool[In, Out], polling=50) =
  ## waits for every actor of `a` to finish with its work. Currently this is
  ## implemented as polling every `polling` ms and has a slight chance
  ## of failing since we check for every actor to be in `ready` state and not
  ## for messages still in ether. This will change in a later
  ## version, however.
  var allReadyCount = 0
  while true:
    var wait = false
    for i in 0..high(a.actors):
      if not a.actors[i].i.ready:
        wait = true
        allReadyCount = 0
        break
    if not wait:
      # it's possible that some actor sent a message to some other actor but
      # both appeared to be non-working as the message takes some time to
      # arrive. We assume that this won't take longer than `polling` and
      # simply attempt a second time and declare victory then. ;-)
      inc allReadyCount
      if allReadyCount > 1: break
    sleep(polling)

proc terminate*[In, Out](a: var ActorPool[In, Out]) =
  ## terminates each actor in the actor pool `a` and frees the
  ## resources attached to `a`.
  var t: Task[In, Out]
  t.shutdown = true
  for i in 0..<a.actors.len: send(a.actors[i].i, t)
  for i in 0..<a.actors.len: join(a.actors[i])
  when Out isnot void:
    close(a.outputs)
  a.actors = @[]

proc join*[In, Out](a: var ActorPool[In, Out]) =
  ## short-cut for `sync` and then `terminate`.
  sync(a)
  terminate(a)

template setupTask =
  t.action = action
  shallowCopy(t.data, input)

template schedule =
  # extremely simple scheduler: We always try the first thread first, so that
  # it remains 'hot' ;-). Round-robin hurts for keeping threads hot.
  for i in 0..high(p.actors):
    if p.actors[i].i.ready:
      p.actors[i].i.send(t)
      return
  # no thread ready :-( --> send message to the thread which has the least
  # messages pending:
  var minIdx = -1
  var minVal = high(int)
  for i in 0..high(p.actors):
    var curr = p.actors[i].i.peek
    if curr == 0:
      # ok, is ready now:
      p.actors[i].i.send(t)
      return
    if curr < minVal and curr >= 0:
      minVal = curr
      minIdx = i
  if minIdx >= 0:
    p.actors[minIdx].i.send(t)
  else:
    raise newException(DeadThreadError, "cannot send message; thread died")

proc spawn*[In, Out](p: var ActorPool[In, Out], input: In,
                       action: proc (input: In): Out {.thread.}
                       ): ptr Channel[Out] =
  ## uses the actor pool to run ``action(input)`` concurrently.
  ## `spawn` is guaranteed to not block.
  var t: Task[In, Out]
  setupTask()
  result = addr(p.outputs)
  t.receiver = result
  schedule()

proc spawn*[In](p: var ActorPool[In, void], input: In,
                 action: proc (input: In) {.thread.}) =
  ## uses the actor pool to run ``action(input)`` concurrently.
  ## `spawn` is guaranteed to not block.
  var t: Task[In, void]
  setupTask()
  schedule()

when not defined(testing) and isMainModule:
  var
    a: ActorPool[int, void]
  createActorPool(a)
  for i in 0 ..< 300:
    a.spawn(i, proc (x: int) {.thread.} = echo x)

  when false:
    proc treeDepth(n: PNode): int {.thread.} =
      var x = a.spawn(treeDepth, n.le)
      var y = a.spawn(treeDepth, n.ri)
      result = max(^x, ^y) + 1

  a.join()


