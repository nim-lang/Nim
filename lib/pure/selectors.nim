#
#
#            Nimrod's Runtime Library
#        (c) Copyright 2013 Dominik Picheta
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

# TODO: Docs.

import tables, os, unsigned
when defined(windows):
  import winlean
else:
  import posix

type
  TEvent* = enum
    EvRead, EvWrite

  TSelectorKey* = object
    fd: cint
    events: set[TEvent]
    data: PObject

  TReadyInfo* = tuple[key: TSelectorKey, events: set[TEvent]]

  PSelector* = ref object of PObject ## Selector interface.
    fds*: TTable[cint, TSelectorKey]
    registerImpl*: proc (s: PSelector, fd: cint, events: set[TEvent],
                    data: var PObject): TSelectorKey {.nimcall, tags: [FWriteIO].}
    unregisterImpl*: proc (s: PSelector, fd: cint): TSelectorKey {.nimcall, tags: [FWriteIO].}
    selectImpl*: proc (s: PSelector, timeout: int): seq[TReadyInfo] {.nimcall, tags: [FReadIO].}
    closeImpl*: proc (s: PSelector) {.nimcall.}

template initSelector(r: expr) =
  new r
  r.fds = initTable[cint, TSelectorKey]()

proc register*(s: PSelector, fd: cint, events: set[TEvent], data: var PObject):
    TSelectorKey =
  if not s.registerImpl.isNil: result = s.registerImpl(s, fd, events, data)

proc unregister*(s: PSelector, fd: cint): TSelectorKey =
  ##
  ## **Note:** For the ``epoll`` implementation the resulting ``TSelectorKey``
  ## will only have the ``fd`` field set. This is an optimisation and may
  ## change in the future if a viable use case is presented. 
  if not s.unregisterImpl.isNil: result = s.unregisterImpl(s, fd)

proc select*(s: PSelector, timeout = 500): seq[TReadyInfo] =
  ##
  ## **Note:** For the ``epoll`` implementation the resulting
  ## ``TSelectorKey.events`` will not contain the original events.
  ## TODO: This breaks what TSelectorKey means... it's not a key anymore.
  ## Rename to TSelectorInfo?

  if not s.selectImpl.isNil: result = s.selectImpl(s, timeout)

proc close*(s: PSelector) =
  if not s.closeImpl.isNil: s.closeImpl(s)

# ---- Select() ----------------------------------------------------------------

type
  PSelectSelector* = ref object of PSelector ## Implementation of select()

proc ssRegister(s: PSelector, fd: cint, events: set[TEvent],
    data: var PObject): TSelectorKey =
  if s.fds.hasKey(fd):
    raise newException(EInvalidValue, "FD already exists in selector.")
  var sk = TSelectorKey(fd: fd, events: events, data: data)
  s.fds[fd] = sk
  result = sk

proc ssUnregister(s: PSelector, fd: cint): TSelectorKey =
  result = s.fds[fd]
  s.fds.del(fd)

proc ssClose(s: PSelector) = nil

proc timeValFromMilliseconds(timeout: int): TTimeVal =
  if timeout != -1:
    var seconds = timeout div 1000
    result.tv_sec = seconds.int32
    result.tv_usec = ((timeout - seconds * 1000) * 1000).int32

proc createFdSet(rd, wr: var TFdSet, fds: TTable[cint, TSelectorKey],
    m: var int) =
  FD_ZERO(rd); FD_ZERO(wr)
  for k, v in pairs(fds):
    if EvRead in v.events: 
      m = max(m, int(k))
      FD_SET(k, rd)
    if EvWrite in v.events:
      m = max(m, int(k))
      FD_SET(k, wr)
   
proc getReadyFDs(rd, wr: var TFdSet, fds: TTable[cint, TSelectorKey]):
    seq[TReadyInfo] =
  result = @[]
  for k, v in pairs(fds):
    var events: set[TEvent] = {}
    if FD_ISSET(k, rd) != 0'i32:
      events = events + {EvRead}
    if FD_ISSET(k, wr) != 0'i32:
      events = events + {EvWrite}
    result.add((v, events))

proc select(fds: TTable[cint, TSelectorKey], timeout = 500):
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

proc ssSelect(s: PSelector, timeout: int): seq[TReadyInfo] =
  result = select(s.fds, timeout)

proc newSelectSelector*(): PSelectSelector =
  initSelector(result)
  result.registerImpl = ssRegister
  result.unregisterImpl = ssUnregister
  result.selectImpl = ssSelect
  result.closeImpl = ssClose

# ---- Epoll -------------------------------------------------------------------

when defined(linux):
  import epoll
  type
    PEpollSelector = ref object of PSelector
      epollFD: cint
  
  proc esRegister(s: PSelector, fd: cint, events: set[TEvent],
      data: var PObject): TSelectorKey =
    var es = PEpollSelector(s)
    var event: epoll_event
    if EvRead in events:
      event.events = EPOLLIN
    if EvWrite in events:
      event.events = event.events or EPOLLOUT
    event.data.fd = fd
    event.data.thePtr = addr(data)
    
    if epoll_ctl(es.epollFD, EPOLL_CTL_ADD, fd, addr(event)) != 0:
      OSError(OSLastError())
    
    result = TSelectorKey(fd: fd, events: events, data: data)
  
  proc esUnregister(s: PSelector, fd: cint): TSelectorKey =
    # We cannot find out the information about this ``fd`` from the epoll
    # context. As such I will simply return an almost empty TSelectorKey.
    var es = PEpollSelector(s)
    if epoll_ctl(es.epollFD, EPOLL_CTL_DEL, fd, nil) != 0:
      OSError(OSLastError())
    # We could fill in the ``fds`` TTable to get the info, but that wouldn't
    # be nice for our memory.
    result = TSelectorKey(fd: fd, events: {}, data: nil)

  proc esClose(s: PSelector) =
    var es = PEpollSelector(s)
    if es.epollFD.close() != 0: OSError(OSLastError())
  
  proc esSelect(s: PSelector, timeout: int): seq[TReadyInfo] =
    result = @[]
    var es = PEpollSelector(s)
    
    var events: array[64, epoll_event]
    let evNum = epoll_wait(es.epollFD, addr events[0], 64.cint, timeout.cint)
    if evNum < 0: OSError(OSLastError())
    for i in 0 .. 63:
      var evSet: set[TEvent] = {}
      if (events[i].events and EPOLLIN) == 1: evSet = evSet + {EvRead}
      if (events[i].events and EPOLLOUT) == 1: evSet = evSet + {EvWrite}
      let selectorKey = TSelectorKey(fd: events[i].data.fd, events: evSet, 
          data: cast[PObject](events[i].data.thePtr))
      result.add((selectorKey, evSet))

  proc newEpollSelector*(): PEpollSelector =
    new result
    result.epollFD = epoll_create(64)
    if result.epollFD < 0:
      OSError(OSLastError())

when isMainModule:
  # Select()
  import sockets
  type
    PSockWrapper = ref object of PObject
      sock: TSocket 
  
  
  var sock = socket()
  sock.connect("irc.freenode.net", TPort(6667))
  
  var selector = newSelectSelector()
  var data = PSockWrapper(sock: sock)
  let key = selector.register(sock.getFD.cint, {EvRead, EvWrite}, data)
  while true:
    let ready = selector.select()
    echo ready.len
    if ready.len > 0: echo ready[0].repr
  
  
  
  
  
  
  
  
  
  