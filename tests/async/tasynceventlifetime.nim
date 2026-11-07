discard """
  targets: "c cpp"
  matrix: "--mm:refc; --mm:arc; --mm:orc; --mm:yrc"
  joinable: false
  disabled: "posix"
"""

import std/asyncdispatch
import masynceventlifetime

block: # Idle cancellation releases its callback after native retirement.
  var destroyed = 0
  let ev = newAsyncEvent()
  watch(ev, addr destroyed, proc(fd: AsyncFD): bool =
    doAssert false, "unregistered callback")
  ev.unregister()
  ev.close()
  when defined(windows):
    doAssert hasPendingOperations()
  retireAll()
  checkDestroyed(destroyed, 1)

when defined(windows):
  import std/[winlean, importutils, monotimes, times]
  when defined(nimPreviewSlimSystem):
    import std/typedthreads

  type Packet = object
    bytes: DWORD
    key: ULONG_PTR
    overlapped: POVERLAPPED

  proc takePacket(): Packet =
    # Wait for the native wait thread to post, without running the Nim callback.
    doAssert getQueuedCompletionStatus(getIoHandler(getGlobalDispatcher()),
      addr result.bytes, addr result.key, addr result.overlapped, 5000) != 0
    doAssert result.overlapped != nil

  proc putPacket(packet: Packet) =
    doAssert postQueuedCompletionStatus(getIoHandler(getGlobalDispatcher()),
      packet.bytes, packet.key, packet.overlapped)

  proc queuePackets(ev: AsyncEvent; count: int) =
    # Taking each packet before triggering again proves the auto-reset event
    # consumed that signal. No coalesced signals or sleep-based re-arm guess.
    var packets: seq[Packet]
    for i in 0 ..< count:
      ev.trigger()
      packets.add(takePacket())
    for packet in packets:
      putPacket(packet)

  proc waitUntil(called: var bool) =
    let deadline = getMonoTime() + initDuration(seconds = 5)
    while not called:
      doAssert getMonoTime() < deadline, "event callback did not complete"
      poll(100)

  block: # A live registration survives repeated delivery and collection.
    var destroyed = 0
    var calls = 0
    let ev = newAsyncEvent()
    watch(ev, addr destroyed, proc(fd: AsyncFD): bool =
      inc calls
      false)
    for expected in 1 .. 4:
      queuePackets(ev, 1)
      poll(0)
      doAssert calls == expected
      checkDestroyed(destroyed, 0)
    ev.unregister()
    ev.close()
    retireAll()
    checkDestroyed(destroyed, 1)

  block: # Native retirement does not free a callback still on the stack.
    var destroyed = 0
    let ev = newAsyncEvent()
    watch(ev, addr destroyed, proc(fd: AsyncFD): bool =
      ev.close()
      putPacket(takePacket()) # Await and consume the retirement packet only.
      poll(0)
      checkDestroyed(destroyed, 0)
      false)
    queuePackets(ev, 1)
    poll(0)
    retireAll()
    checkDestroyed(destroyed, 1)

  for count in [1, 8]:
    block: # Closing the event cannot invalidate already-posted notifications.
      var destroyed = 0
      let ev = newAsyncEvent()
      watch(ev, addr destroyed, proc(fd: AsyncFD): bool =
        doAssert false, "closed callback")
      queuePackets(ev, count)
      ev.unregister()
      ev.close()
      checkDestroyed(destroyed, 0)
      for i in 0 ..< count:
        poll(0)
      retireAll()
      checkDestroyed(destroyed, 1)

    block: # Old notifications cannot call or remove a replacement registration.
      var destroyed = 0
      var called = false
      let ev = newAsyncEvent()
      watch(ev, addr destroyed, proc(fd: AsyncFD): bool =
        doAssert false, "replaced callback")
      queuePackets(ev, count)
      ev.unregister()
      ev.addEvent(proc(fd: AsyncFD): bool =
        called = true
        true)
      for i in 0 ..< count:
        poll(0)
      doAssert not called
      ev.trigger()
      waitUntil(called)
      doAssert called
      ev.close()
      retireAll()
      checkDestroyed(destroyed, 1)

    for remove in [false, true]:
      block: # Closing inside the callback is safe for either return value.
        var destroyed = 0
        var calls = 0
        let ev = newAsyncEvent()
        watch(ev, addr destroyed, proc(fd: AsyncFD): bool =
          inc calls
          ev.unregister()
          ev.close()
          remove)
        queuePackets(ev, count)
        for i in 0 ..< count:
          poll(0)
        doAssert calls == 1
        retireAll()
        checkDestroyed(destroyed, 1)

    block: # Returning true removes the registration and retires every packet.
      var destroyed = 0
      var calls = 0
      let ev = newAsyncEvent()
      watch(ev, addr destroyed, proc(fd: AsyncFD): bool =
        inc calls
        true)
      queuePackets(ev, count)
      for i in 0 ..< count:
        poll(0)
      doAssert calls == 1
      ev.close()
      retireAll()
      checkDestroyed(destroyed, 1)

    block: # A callback can replace itself even when it returns true.
      var destroyed = 0
      var called = false
      let ev = newAsyncEvent()
      watch(ev, addr destroyed, proc(fd: AsyncFD): bool =
        ev.unregister()
        ev.addEvent(proc(fd: AsyncFD): bool =
          called = true
          true)
        ev.trigger()
        true)
      queuePackets(ev, count)
      for i in 0 ..< count:
        poll(0)
      doAssert not called
      waitUntil(called)
      doAssert called
      ev.close()
      retireAll()
      checkDestroyed(destroyed, 1)

    block: # Raising after close still releases the consumed notification.
      var destroyed = 0
      var raised = false
      let ev = newAsyncEvent()
      watch(ev, addr destroyed, proc(fd: AsyncFD): bool =
        ev.unregister()
        ev.close()
        raise newException(ValueError, "event callback"))
      queuePackets(ev, count)
      try:
        poll(0)
      except ValueError as error:
        doAssert error.msg == "event callback"
        raised = true
      doAssert raised
      for i in 1 ..< count:
        poll(0)
      retireAll()
      checkDestroyed(destroyed, 1)

  block: # close also cancels a still-registered event.
    var destroyed = 0
    let ev = newAsyncEvent()
    watch(ev, addr destroyed, proc(fd: AsyncFD): bool =
      doAssert false, "closed callback")
    ev.close()
    doAssert hasPendingOperations()
    retireAll()
    checkDestroyed(destroyed, 1)

  block: # Retirement remains pollable after the last live handle is removed.
    var destroyed = 0
    let ev = newAsyncEvent()
    watch(ev, addr destroyed, proc(fd: AsyncFD): bool =
      doAssert false, "retired callback")
    queuePackets(ev, 8)
    ev.unregister()
    ev.close()
    doAssert hasPendingOperations()
    retireAll()
    checkDestroyed(destroyed, 1)

  block: # Unregistering may race a wait callback that is still posting.
    for _ in 0 ..< 200:
      var destroyed = 0
      let ev = newAsyncEvent()
      watch(ev, addr destroyed, proc(fd: AsyncFD): bool =
        false)
      ev.trigger()
      # Native completion and queued-packet retirement must both precede
      # release, including when the native callback has not posted yet.
      ev.unregister()
      ev.close()
      retireAll()
      checkDestroyed(destroyed, 1)

  block: # Raising must not retire a registration that is still active.
    var destroyed = 0
    var calls = 0
    let ev = newAsyncEvent()
    watch(ev, addr destroyed, proc(fd: AsyncFD): bool =
      inc calls
      raise newException(ValueError, "live callback"))
    for expected in 1 .. 2:
      queuePackets(ev, 1)
      var raised = false
      try:
        poll(0)
      except ValueError as error:
        doAssert error.msg == "live callback"
        raised = true
      doAssert raised
      doAssert calls == expected
      doAssert hasPendingOperations()
      checkDestroyed(destroyed, 0)
    ev.close()
    retireAll()
    checkDestroyed(destroyed, 1)

  block: # close without unregister also retires already-posted packets.
    var destroyed = 0
    let ev = newAsyncEvent()
    watch(ev, addr destroyed, proc(fd: AsyncFD): bool =
      doAssert false, "closed callback")
    queuePackets(ev, 8)
    ev.close()
    retireAll()
    checkDestroyed(destroyed, 1)

  block: # Replacing the global dispatcher cannot redirect retirement credit.
    let owner = getGlobalDispatcher()
    let replacement = newDispatcher()
    var destroyed = 0
    let ev = newAsyncEvent()
    watch(ev, addr destroyed, proc(fd: AsyncFD): bool =
      doAssert false, "retired callback")
    queuePackets(ev, 8)
    setGlobalDispatcher(replacement)
    try:
      ev.close()
      doAssert not hasPendingOperations()
    finally:
      setGlobalDispatcher(owner)
    doAssert hasPendingOperations()
    retireAll()
    checkDestroyed(destroyed, 1)
    doAssert closeHandle(getIoHandler(replacement)) != 0

  block: # Failed cancellation preserves the event and registration for retry.
    var destroyed = 0
    var called = false
    let ev = newAsyncEvent()
    watch(ev, addr destroyed, proc(fd: AsyncFD): bool =
      called = true
      false)
    privateAccess(typeof(ev[]))
    let registration = ev.registration
    privateAccess(typeof(registration[]))
    let waiter = registration.waiter
    registration.waiter = 0 # Force native cancellation to fail.
    var raised = false
    try:
      ev.close()
    except OSError:
      raised = true
    finally:
      registration.waiter = waiter
    doAssert raised
    doAssert ev.registration == registration
    checkDestroyed(destroyed, 0)
    ev.trigger() # The original handle and registration remain usable.
    waitUntil(called)
    ev.close()
    retireAll()
    checkDestroyed(destroyed, 1)

  when compileOption("threads"):
    type Attempts = object
      ev: AsyncEvent
      unregisterRejected, closeRejected: bool

    proc offThread(attempts: ptr Attempts) {.thread.} =
      try:
        attempts.ev.unregister()
      except ValueError:
        attempts.unregisterRejected = true
      try:
        attempts.ev.close()
      except ValueError:
        attempts.closeRejected = true

    proc closeUnregistered(ev: AsyncEvent) {.thread.} =
      ev.close()

    block: # Unregistered close needs no dispatcher on the closing thread.
      let ev = newAsyncEvent()
      var thread: Thread[AsyncEvent]
      createThread(thread, closeUnregistered, ev)
      joinThread(thread)
      doAssert not hasPendingOperations()

    block: # Off-thread teardown rejects without touching the owner or handle.
      var destroyed = 0
      var called = false
      let ev = newAsyncEvent()
      watch(ev, addr destroyed, proc(fd: AsyncFD): bool =
        called = true
        false)
      var attempts = Attempts(ev: ev)
      var thread: Thread[ptr Attempts]
      createThread(thread, offThread, addr attempts)
      joinThread(thread)
      doAssert attempts.unregisterRejected
      doAssert attempts.closeRejected
      ev.trigger()
      waitUntil(called)
      ev.close()
      retireAll()
      checkDestroyed(destroyed, 1)

doAssert not hasPendingOperations()
