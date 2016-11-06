#
#
#            Nim's Runtime Library
#        (c) Copyright 2015 Dominik Picheta
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

# TODO: Docs.

import os, hashes

when defined(linux):
  import posix, epoll
elif defined(macosx) or defined(freebsd) or defined(openbsd) or defined(netbsd):
  import posix, kqueue, times
elif defined(windows):
  import winlean
else:
  import posix

const MultiThreaded = defined(useStdlibThreading)

when MultiThreaded:
  import sharedtables

  type SelectorData = pointer
else:
  import tables

  type SelectorData = RootRef

proc hash*(x: SocketHandle): Hash {.borrow.}
proc `$`*(x: SocketHandle): string {.borrow.}

type
  Event* = enum
    EvRead, EvWrite, EvError

  SelectorKey* = object
    fd*: SocketHandle
    events*: set[Event] ## The events which ``fd`` listens for.
    data*: SelectorData ## User object.

  ReadyInfo* = tuple[key: SelectorKey, events: set[Event]]

when defined(nimdoc):
  type
    Selector* = ref object
      ## An object which holds file descriptors to be checked for read/write
      ## status.

  proc register*(s: Selector, fd: SocketHandle, events: set[Event],
                 data: SelectorData): SelectorKey {.discardable.} =
    ## Registers file descriptor ``fd`` to selector ``s`` with a set of Event
    ## ``events``.

  proc update*(s: Selector, fd: SocketHandle,
               events: set[Event]): SelectorKey {.discardable.} =
    ## Updates the events which ``fd`` wants notifications for.

  proc unregister*(s: Selector, fd: SocketHandle): SelectorKey {.discardable.} =
    ## Unregisters file descriptor ``fd`` from selector ``s``.

  proc close*(s: Selector) =
    ## Closes the selector

  proc select*(s: Selector, timeout: int): seq[ReadyInfo] =
    ## The ``events`` field of the returned ``key`` contains the original events
    ## for which the ``fd`` was bound. This is contrary to the ``events`` field
    ## of the ``ReadyInfo`` tuple which determines which events are ready
    ## on the ``fd``.

  proc newSelector*(): Selector =
    ## Creates a new selector

  proc contains*(s: Selector, fd: SocketHandle): bool =
    ## Determines whether selector contains a file descriptor.

  proc `[]`*(s: Selector, fd: SocketHandle): SelectorKey =
    ## Retrieves the selector key for ``fd``.

elif defined(linux):
  type
    Selector* = object
      epollFD: cint
      events: array[64, epoll_event]
      when MultiThreaded:
        fds: SharedTable[SocketHandle, SelectorKey]
      else:
        fds: Table[SocketHandle, SelectorKey]

  proc createEventStruct(events: set[Event], fd: SocketHandle): epoll_event =
    if EvRead in events:
      result.events = EPOLLIN
    if EvWrite in events:
      result.events = result.events or EPOLLOUT
    result.events = result.events or EPOLLRDHUP
    result.data.fd = fd.cint

  proc register*(s: var Selector, fd: SocketHandle, events: set[Event],
                 data: SelectorData) =
    var event = createEventStruct(events, fd)
    if events != {}:
      if epoll_ctl(s.epollFD, EPOLL_CTL_ADD, fd, addr(event)) != 0:
        raiseOSError(osLastError())

    s.fds[fd] = SelectorKey(fd: fd, events: events, data: data)

  proc update*(s: var Selector, fd: SocketHandle, events: set[Event]) =
    if s.fds[fd].events != events:
      if events == {}:
        # This fd is idle -- it should not be registered to epoll.
        # But it should remain a part of this selector instance.
        # This is to prevent epoll_wait from returning immediately
        # because its got fds which are waiting for no events and
        # are therefore constantly ready. (leading to 100% CPU usage).
        if epoll_ctl(s.epollFD, EPOLL_CTL_DEL, fd, nil) != 0:
          raiseOSError(osLastError())
        s.fds[fd].events = events
      else:
        var event = createEventStruct(events, fd)
        if s.fds[fd].events == {}:
          # This fd is idle. It's not a member of this epoll instance and must
          # be re-registered.
          if epoll_ctl(s.epollFD, EPOLL_CTL_ADD, fd, addr(event)) != 0:
            raiseOSError(osLastError())
        else:
          if epoll_ctl(s.epollFD, EPOLL_CTL_MOD, fd, addr(event)) != 0:
            raiseOSError(osLastError())
        s.fds[fd].events = events

  proc unregister*(s: var Selector, fd: SocketHandle) =
    if s.fds[fd].events != {}:
      if epoll_ctl(s.epollFD, EPOLL_CTL_DEL, fd, nil) != 0:
        let err = osLastError()
        if err.cint notin {ENOENT, EBADF}:
          # TODO: Why do we sometimes get an EBADF? Is this normal?
          raiseOSError(err)
    s.fds.del(fd)

  proc close*(s: var Selector) =
    when MultiThreaded: deinitSharedTable(s.fds)
    if s.epollFD.close() != 0: raiseOSError(osLastError())

  proc epollHasFd(s: Selector, fd: SocketHandle): bool =
    result = true
    var event = createEventStruct(s.fds[fd].events, fd)
    if epoll_ctl(s.epollFD, EPOLL_CTL_MOD, fd, addr(event)) != 0:
      let err = osLastError()
      if err.cint in {ENOENT, EBADF}:
        return false
      raiseOSError(err)

  proc select*(s: var Selector, timeout: int): seq[ReadyInfo] =
    result = @[]
    let evNum = epoll_wait(s.epollFD, addr s.events[0], 64.cint, timeout.cint)
    if evNum < 0:
      let err = osLastError()
      if err.cint == EINTR:
        return @[]
      raiseOSError(err)
    if evNum == 0: return @[]
    for i in 0 .. <evNum:
      let fd = s.events[i].data.fd.SocketHandle

      var evSet: set[Event] = {}
      if (s.events[i].events and EPOLLERR) != 0 or (s.events[i].events and EPOLLHUP) != 0: evSet = evSet + {EvError}
      if (s.events[i].events and EPOLLIN) != 0: evSet = evSet + {EvRead}
      if (s.events[i].events and EPOLLOUT) != 0: evSet = evSet + {EvWrite}
      let selectorKey = s.fds[fd]
      assert selectorKey.fd != 0.SocketHandle
      result.add((selectorKey, evSet))

      #echo("Epoll: ", result[i].key.fd, " ", result[i].events, " ", result[i].key.events)

  proc newSelector*(): Selector =
    result.epollFD = epoll_create(64)
    if result.epollFD < 0:
      raiseOSError(osLastError())
    when MultiThreaded:
      result.fds = initSharedTable[SocketHandle, SelectorKey]()
    else:
      result.fds = initTable[SocketHandle, SelectorKey]()

  proc contains*(s: Selector, fd: SocketHandle): bool =
    ## Determines whether selector contains a file descriptor.
    if s.fds.hasKey(fd):
      # Ensure the underlying epoll instance still contains this fd.
      if s.fds[fd].events != {}:
        result = epollHasFd(s, fd)
      else:
        result = true
    else:
      return false

  proc `[]`*(s: Selector, fd: SocketHandle): SelectorKey =
    ## Retrieves the selector key for ``fd``.
    return s.fds[fd]

elif defined(macosx) or defined(freebsd) or defined(openbsd) or defined(netbsd):
  type
    Selector* = object
      kqFD: cint
      events: array[64, KEvent]
      when MultiThreaded:
        fds: SharedTable[SocketHandle, SelectorKey]
      else:
        fds: Table[SocketHandle, SelectorKey]

  template modifyKQueue(kqFD: cint, fd: SocketHandle, event: Event,
                        op: cushort) =
    var kev = KEvent(ident:  fd.cuint,
                     filter: if event == EvRead: EVFILT_READ else: EVFILT_WRITE,
                     flags:  op)
    if kevent(kqFD, addr kev, 1, nil, 0, nil) == -1:
      raiseOSError(osLastError())

  proc register*(s: var Selector, fd: SocketHandle, events: set[Event],
                 data: SelectorData) =
    for event in events:
      modifyKQueue(s.kqFD, fd, event, EV_ADD)
    s.fds[fd] = SelectorKey(fd: fd, events: events, data: data)

  proc update*(s: var Selector, fd: SocketHandle, events: set[Event]) =
    let previousEvents = s.fds[fd].events
    if previousEvents != events:
      for event in events-previousEvents:
        modifyKQueue(s.kqFD, fd, event, EV_ADD)
      for event in previousEvents-events:
        modifyKQueue(s.kqFD, fd, event, EV_DELETE)
      s.fds[fd].events = events

  proc unregister*(s: var Selector, fd: SocketHandle) =
    for event in s.fds[fd].events:
      modifyKQueue(s.kqFD, fd, event, EV_DELETE)
    s.fds.del(fd)

  proc close*(s: var Selector) =
    when MultiThreaded: deinitSharedTable(s.fds)
    if s.kqFD.close() != 0: raiseOSError(osLastError())

  proc select*(s: var Selector, timeout: int): seq[ReadyInfo] =
    result = @[]
    var tv =
      if timeout >= 1000: Timespec(tv_sec: (timeout div 1000).Time, tv_nsec: 0)
      else: Timespec(tv_sec: 0.Time, tv_nsec: timeout * 1000000)
    let evNum = kevent(s.kqFD, nil, 0, addr s.events[0], 64.cint, addr tv)
    if evNum < 0:
      let err = osLastError()
      if err.cint == EINTR:
        return @[]
      raiseOSError(err)
    if evNum == 0: return @[]
    for i in 0 .. <evNum:
      let fd = s.events[i].ident.SocketHandle

      var evSet: set[Event] = {}
      if  (s.events[i].flags and EV_EOF) != 0: evSet = evSet + {EvError}
      if   s.events[i].filter == EVFILT_READ:  evSet = evSet + {EvRead}
      elif s.events[i].filter == EVFILT_WRITE: evSet = evSet + {EvWrite}
      let selectorKey = s.fds[fd]
      assert selectorKey.fd != 0.SocketHandle
      result.add((selectorKey, evSet))

  proc newSelector*(): Selector =
    result.kqFD = kqueue()
    if result.kqFD < 0:
      raiseOSError(osLastError())
    when MultiThreaded:
      result.fds = initSharedTable[SocketHandle, SelectorKey]()
    else:
      result.fds = initTable[SocketHandle, SelectorKey]()

  proc contains*(s: Selector, fd: SocketHandle): bool =
    ## Determines whether selector contains a file descriptor.
    s.fds.hasKey(fd) # and s.fds[fd].events != {}

  proc `[]`*(s: Selector, fd: SocketHandle): SelectorKey =
    ## Retrieves the selector key for ``fd``.
    return s.fds[fd]

elif not defined(nimdoc):
  # TODO: kqueue for bsd/mac os x.
  type
    Selector* = object
      when MultiThreaded:
        fds: SharedTable[SocketHandle, SelectorKey]
      else:
        fds: Table[SocketHandle, SelectorKey]

  proc register*(s: var Selector, fd: SocketHandle, events: set[Event],
                 data: SelectorData) =
    let result = SelectorKey(fd: fd, events: events, data: data)
    if s.fds.hasKeyOrPut(fd, result):
      raise newException(ValueError, "File descriptor already exists.")

  proc update*(s: var Selector, fd: SocketHandle, events: set[Event]) =
    #if not s.fds.hasKey(fd):
    #  raise newException(ValueError, "File descriptor not found.")
    s.fds[fd].events = events

  proc unregister*(s: var Selector, fd: SocketHandle) =
    s.fds.del(fd)

  proc close*(s: var Selector) =
    when MultiThreaded: deinitSharedTable(s.fds)

  proc timeValFromMilliseconds(timeout: int): TimeVal =
    if timeout != -1:
      var seconds = timeout div 1000
      result.tv_sec = seconds.int32
      result.tv_usec = ((timeout - seconds * 1000) * 1000).int32

  proc createFdSet(rd, wr: var TFdSet, s: Selector, m: var int) =
    FD_ZERO(rd); FD_ZERO(wr)
    for k, v in pairs(s.fds):
      if EvRead in v.events:
        m = max(m, int(k))
        FD_SET(k, rd)
      if EvWrite in v.events:
        m = max(m, int(k))
        FD_SET(k, wr)

  proc getReadyFDs(rd, wr: var TFdSet,
                   s: var Selector): seq[ReadyInfo] =
    result = @[]
    for k, v in pairs(s.fds):
      var events: set[Event] = {}
      if FD_ISSET(k, rd) != 0'i32:
        events = events + {EvRead}
      if FD_ISSET(k, wr) != 0'i32:
        events = events + {EvWrite}
      result.add((v, events))

  proc select*(s: var Selector, timeout: int): seq[ReadyInfo] =
    var tv {.noInit.}: TimeVal = timeValFromMilliseconds(timeout)

    var rd, wr: TFdSet
    var m = 0
    createFdSet(rd, wr, s, m)

    var retCode = 0
    if timeout != -1:
      retCode = int(select(cint(m+1), addr(rd), addr(wr), nil, addr(tv)))
    else:
      retCode = int(select(cint(m+1), addr(rd), addr(wr), nil, nil))

    if retCode < 0:
      raiseOSError(osLastError())
    elif retCode == 0:
      return @[]
    else:
      return getReadyFDs(rd, wr, s)

  proc newSelector*(): Selector =
    when MultiThreaded:
      result.fds = initSharedTable[SocketHandle, SelectorKey]()
    else:
      result.fds = initTable[SocketHandle, SelectorKey]()

  proc contains*(s: Selector, fd: SocketHandle): bool =
    return s.fds.hasKey(fd)

  proc `[]`*(s: Selector, fd: SocketHandle): SelectorKey =
    return s.fds[fd]

proc contains*(s: Selector, key: SelectorKey): bool =
  ## Determines whether selector contains this selector key. More accurate
  ## than checking if the file descriptor is in the selector because it
  ## ensures that the keys are equal. File descriptors may not always be
  ## unique especially when an fd is closed and then a new one is opened,
  ## the new one may have the same value.
  when not defined(nimdoc):
    return key.fd in s and s.fds[key.fd] == key

proc len*(s: Selector): int =
  ## Retrieves the number of registered file descriptors in this Selector.
  when not defined(nimdoc):
    return s.fds.len

{.deprecated: [TEvent: Event, PSelectorKey: SelectorKey,
   TReadyInfo: ReadyInfo, PSelector: Selector].}


when not defined(testing) and isMainModule and not defined(nimdoc):
  # Select()
  import sockets

  when MultiThreaded:
    type
      SockWrapper = object
        sock: Socket
  else:
    type
      SockWrapper = ref object of RootObj
        sock: Socket

  var sock = socket()
  if sock == sockets.invalidSocket: raiseOSError(osLastError())
  #sock.setBlocking(false)
  sock.connect("irc.freenode.net", Port(6667))

  var selector = newSelector()
  var data = SockWrapper(sock: sock)
  when MultiThreaded:
    selector.register(sock.getFD, {EvWrite}, addr data)
  else:
    selector.register(sock.getFD, {EvWrite}, data)
  var i = 0
  while true:
    let ready = selector.select(1000)
    echo ready.len
    if ready.len > 0: echo ready[0].events
    i.inc
    if i == 6:
      selector.unregister(sock.getFD)
      selector.close()
      break
