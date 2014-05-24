#
#
#            Nimrod's Runtime Library
#        (c) Copyright 2014 Dominik Picheta
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

# TODO: Docs.

import tables, os, unsigned, hashes

when defined(linux) or defined(macosx): 
  import posix, epoll
elif defined(windows): 
  import winlean
else: 
  import posix

proc hash*(x: TSocketHandle): THash {.borrow.}
proc `$`*(x: TSocketHandle): string {.borrow.}

type
  TEvent* = enum
    EvRead, EvWrite

  PSelectorKey* = ref object
    fd*: TSocketHandle
    events*: set[TEvent] ## The events which ``fd`` listens for.
    data*: PObject ## User object.

  TReadyInfo* = tuple[key: PSelectorKey, events: set[TEvent]]

when defined(linux) or defined(nimdoc):
  type
    PSelector* = ref object
      epollFD: cint
      events: array[64, epoll_event]
      fds: TTable[TSocketHandle, PSelectorKey]
  
  proc createEventStruct(events: set[TEvent], fd: TSocketHandle): epoll_event =
    if EvRead in events:
      result.events = EPOLLIN
    if EvWrite in events:
      result.events = result.events or EPOLLOUT
    result.events = result.events or EPOLLRDHUP
    result.data.fd = fd.cint
  
  proc register*(s: PSelector, fd: TSocketHandle, events: set[TEvent],
      data: PObject): PSelectorKey {.discardable.} =
    ## Registers file descriptor ``fd`` to selector ``s`` with a set of TEvent
    ## ``events``.
    var event = createEventStruct(events, fd)
    if events != {}:
      if epoll_ctl(s.epollFD, EPOLL_CTL_ADD, fd, addr(event)) != 0:
        OSError(OSLastError())

    var key = PSelectorKey(fd: fd, events: events, data: data)
  
    s.fds[fd] = key
    result = key
  
  proc update*(s: PSelector, fd: TSocketHandle,
      events: set[TEvent]): PSelectorKey {.discardable.} =
    ## Updates the events which ``fd`` wants notifications for.
    if s.fds[fd].events != events:
      if events == {}:
        # This fd is idle -- it should not be registered to epoll.
        # But it should remain a part of this selector instance.
        # This is to prevent epoll_wait from returning immediately
        # because its got fds which are waiting for no events and
        # are therefore constantly ready. (leading to 100% CPU usage).
        if epoll_ctl(s.epollFD, EPOLL_CTL_DEL, fd, nil) != 0:
          OSError(OSLastError())
        s.fds[fd].events = events
      else:
        var event = createEventStruct(events, fd)
        if s.fds[fd].events == {}:
          # This fd is idle. It's not a member of this epoll instance and must
          # be re-registered.
          if epoll_ctl(s.epollFD, EPOLL_CTL_ADD, fd, addr(event)) != 0:
            OSError(OSLastError())
        else:
          if epoll_ctl(s.epollFD, EPOLL_CTL_MOD, fd, addr(event)) != 0:
            OSError(OSLastError())
        s.fds[fd].events = events
      
      result = s.fds[fd]
  
  proc unregister*(s: PSelector, fd: TSocketHandle): PSelectorKey {.discardable.} =
    if epoll_ctl(s.epollFD, EPOLL_CTL_DEL, fd, nil) != 0:
      let err = OSLastError()
      if err.cint notin {ENOENT, EBADF}: # TODO: Why do we sometimes get an EBADF? Is this normal?
        OSError(err)
    result = s.fds[fd]
    s.fds.del(fd)

  proc close*(s: PSelector) =
    if s.epollFD.close() != 0: OSError(OSLastError())
    dealloc(addr s.events) # TODO: Test this
  
  proc epollHasFd(s: PSelector, fd: TSocketHandle): bool =
    result = true
    var event = createEventStruct(s.fds[fd].events, fd)
    if epoll_ctl(s.epollFD, EPOLL_CTL_MOD, fd, addr(event)) != 0:
      let err = osLastError()
      if err.cint in {ENOENT, EBADF}:
        return false
      OSError(OSLastError())
  
  proc select*(s: PSelector, timeout: int): seq[TReadyInfo] =
    ##
    ## The ``events`` field of the returned ``key`` contains the original events
    ## for which the ``fd`` was bound. This is contrary to the ``events`` field
    ## of the ``TReadyInfo`` tuple which determines which events are ready
    ## on the ``fd``.
    result = @[]
    let evNum = epoll_wait(s.epollFD, addr s.events[0], 64.cint, timeout.cint)
    if evNum < 0: OSError(OSLastError())
    if evNum == 0: return @[]
    for i in 0 .. <evNum:
      let fd = s.events[i].data.fd.TSocketHandle
    
      var evSet: set[TEvent] = {}
      if (s.events[i].events and EPOLLIN) != 0: evSet = evSet + {EvRead}
      if (s.events[i].events and EPOLLOUT) != 0: evSet = evSet + {EvWrite}
      let selectorKey = s.fds[fd]
      assert selectorKey != nil
      result.add((selectorKey, evSet))

      #echo("Epoll: ", result[i].key.fd, " ", result[i].events, " ", result[i].key.events)
  
  proc newSelector*(): PSelector =
    new result
    result.epollFD = epoll_create(64)
    result.events = cast[array[64, epoll_event]](alloc0(sizeof(epoll_event)*64))
    result.fds = initTable[TSocketHandle, PSelectorKey]()
    if result.epollFD < 0:
      OSError(OSLastError())

  proc contains*(s: PSelector, fd: TSocketHandle): bool =
    ## Determines whether selector contains a file descriptor.
    if s.fds.hasKey(fd):
      # Ensure the underlying epoll instance still contains this fd.
      if s.fds[fd].events != {}:
        result = epollHasFd(s, fd)
      else:
        result = true
    else:
      return false

  proc `[]`*(s: PSelector, fd: TSocketHandle): PSelectorKey =
    ## Retrieves the selector key for ``fd``.
    return s.fds[fd]

else:
  # TODO: kqueue for bsd/mac os x.
  type
    PSelector* = ref object
      fds: TTable[TSocketHandle, PSelectorKey]

  proc register*(s: PSelector, fd: TSocketHandle, events: set[TEvent],
      data: PObject): PSelectorKey {.discardable.} =
    if s.fds.hasKey(fd):
      raise newException(EInvalidValue, "File descriptor already exists.")
    var sk = PSelectorKey(fd: fd, events: events, data: data)
    s.fds[fd] = sk
    result = sk

  proc update*(s: PSelector, fd: TSocketHandle,
      events: set[TEvent]): PSelectorKey {.discardable.} =
    ## Updates the events which ``fd`` wants notifications for.
    if not s.fds.hasKey(fd):
      raise newException(EInvalidValue, "File descriptor not found.")

    s.fds[fd].events = events
    result = s.fds[fd]

  proc unregister*(s: PSelector, fd: TSocketHandle): PSelectorKey {.discardable.} =
    result = s.fds[fd]
    s.fds.del(fd)

  proc close*(s: PSelector) = nil

  proc timeValFromMilliseconds(timeout: int): TTimeVal =
    if timeout != -1:
      var seconds = timeout div 1000
      result.tv_sec = seconds.int32
      result.tv_usec = ((timeout - seconds * 1000) * 1000).int32

  proc createFdSet(rd, wr: var TFdSet, fds: TTable[TSocketHandle, PSelectorKey],
      m: var int) =
    FD_ZERO(rd); FD_ZERO(wr)
    for k, v in pairs(fds):
      if EvRead in v.events: 
        m = max(m, int(k))
        FD_SET(k, rd)
      if EvWrite in v.events:
        m = max(m, int(k))
        FD_SET(k, wr)
     
  proc getReadyFDs(rd, wr: var TFdSet, fds: TTable[TSocketHandle, PSelectorKey]):
      seq[TReadyInfo] =
    result = @[]
    for k, v in pairs(fds):
      var events: set[TEvent] = {}
      if FD_ISSET(k, rd) != 0'i32:
        events = events + {EvRead}
      if FD_ISSET(k, wr) != 0'i32:
        events = events + {EvWrite}
      result.add((v, events))

  proc select(fds: TTable[TSocketHandle, PSelectorKey], timeout = 500):
    seq[TReadyInfo] =
    var tv {.noInit.}: TTimeVal = timeValFromMilliseconds(timeout)
    
    var rd, wr: TFdSet
    var m = 0
    createFdSet(rd, wr, fds, m)
    
    var retCode = 0
    if timeout != -1:
      retCode = int(select(cint(m+1), addr(rd), addr(wr), nil, addr(tv)))
    else:
      retCode = int(select(cint(m+1), addr(rd), addr(wr), nil, nil))
    
    if retCode < 0:
      OSError(OSLastError())
    elif retCode == 0:
      return @[]
    else:
      return getReadyFDs(rd, wr, fds)

  proc select*(s: PSelector, timeout: int): seq[TReadyInfo] =
    result = select(s.fds, timeout)

  proc newSelector*(): PSelector =
    new result
    result.fds = initTable[TSocketHandle, PSelectorKey]()

  proc contains*(s: PSelector, fd: TSocketHandle): bool =
    return s.fds.hasKey(fd)

  proc `[]`*(s: PSelector, fd: TSocketHandle): PSelectorKey =
    return s.fds[fd]

proc contains*(s: PSelector, key: PSelectorKey): bool =
  ## Determines whether selector contains this selector key. More accurate
  ## than checking if the file descriptor is in the selector because it
  ## ensures that the keys are equal. File descriptors may not always be
  ## unique especially when an fd is closed and then a new one is opened,
  ## the new one may have the same value.
  return key.fd in s and s.fds[key.fd] == key

when isMainModule:
  # Select()
  import sockets
  type
    PSockWrapper = ref object of PObject
      sock: TSocket
  
  var sock = socket()
  if sock == sockets.InvalidSocket: osError(osLastError())
  #sock.setBlocking(false)
  sock.connect("irc.freenode.net", TPort(6667))
  
  var selector = newSelector()
  var data = PSockWrapper(sock: sock)
  let key = selector.register(sock.getFD, {EvWrite}, data)
  var i = 0
  while true:
    let ready = selector.select(1000)
    echo ready.len
    if ready.len > 0: echo ready[0].events
    i.inc
    if i == 6:
      assert selector.unregister(sock.getFD).fd == sock.getFD
      selector.close()
      break
