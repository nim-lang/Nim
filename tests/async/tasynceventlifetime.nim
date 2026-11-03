discard """
  targets: "c cpp"
  matrix: "--mm:refc; --mm:arc; --mm:orc; --mm:yrc"
  joinable: false
"""

import std/asyncdispatch

when defined(gcDestructors):
  type
    Lifetime = object
      destroyed: ptr int
    Token = ref Lifetime

  proc `=destroy`(value: Lifetime) =
    inc value.destroyed[]

proc watch(ev: AsyncEvent; destroyed: ptr int; cb: Callback) =
  when defined(gcDestructors):
    let token = Token(destroyed: destroyed)
    ev.addEvent(proc(fd: AsyncFD): bool {.gcsafe.} =
      doAssert token.destroyed != nil
      cb(fd))
  else:
    ev.addEvent(cb)

template checkDestroyed(count, expected: int) =
  when defined(gcDestructors):
    GC_fullCollect()
    doAssert count == expected

block: # Removing an idle registration releases its callback without polling.
  var destroyed = 0
  let ev = newAsyncEvent()
  watch(ev, addr destroyed, proc(fd: AsyncFD): bool =
    doAssert false, "unregistered callback")
  ev.unregister()
  ev.close()
  checkDestroyed(destroyed, 1)

when defined(windows):
  import std/winlean

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
    var packets: seq[Packet]
    for i in 0 ..< count:
      ev.trigger()
      packets.add(takePacket())
    for packet in packets:
      putPacket(packet)

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
      checkDestroyed(destroyed, 1)
      doAssert not called
      ev.trigger()
      putPacket(takePacket())
      poll(0)
      doAssert called
      ev.close()

    for remove in [false, true]:
      block: # Closing inside the callback is safe regardless of its return value.
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
      checkDestroyed(destroyed, 1)
      ev.close()

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
      checkDestroyed(destroyed, 1)
      doAssert not called
      putPacket(takePacket())
      poll(0)
      doAssert called
      ev.close()

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
      checkDestroyed(destroyed, 1)

  block: # close also cancels a still-registered event.
    var destroyed = 0
    let ev = newAsyncEvent()
    watch(ev, addr destroyed, proc(fd: AsyncFD): bool =
      doAssert false, "closed callback")
    ev.close()
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
    drain()
    checkDestroyed(destroyed, 1)

doAssert not hasPendingOperations()
