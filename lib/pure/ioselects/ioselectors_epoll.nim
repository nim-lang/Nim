#
#
#            Nim's Runtime Library
#        (c) Copyright 2016 Eugene Kabanov
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

# This module implements Linux epoll().

import posix, times

# Maximum number of events that can be returned
const MAX_EPOLL_EVENTS = 64

when not defined(android):
  type
    SignalFdInfo* {.importc: "struct signalfd_siginfo",
                    header: "<sys/signalfd.h>", pure, final.} = object
      ssi_signo*: uint32
      ssi_errno*: int32
      ssi_code*: int32
      ssi_pid*: uint32
      ssi_uid*: uint32
      ssi_fd*: int32
      ssi_tid*: uint32
      ssi_band*: uint32
      ssi_overrun*: uint32
      ssi_trapno*: uint32
      ssi_status*: int32
      ssi_int*: int32
      ssi_ptr*: uint64
      ssi_utime*: uint64
      ssi_stime*: uint64
      ssi_addr*: uint64
      pad* {.importc: "__pad".}: array[0..47, uint8]

type
  eventFdData {.importc: "eventfd_t",
                header: "<sys/eventfd.h>", pure, final.} = uint64
  epoll_data {.importc: "union epoll_data", header: "<sys/epoll.h>",
               pure, final.} = object
    u64 {.importc: "u64".}: uint64
  epoll_event {.importc: "struct epoll_event",
                header: "<sys/epoll.h>", pure, final.} = object
    events: uint32 # Epoll events
    data: epoll_data # User data variable

const
  EPOLL_CTL_ADD = 1          # Add a file descriptor to the interface.
  EPOLL_CTL_DEL = 2          # Remove a file descriptor from the interface.
  EPOLL_CTL_MOD = 3          # Change file descriptor epoll_event structure.
  EPOLLIN = 0x00000001
  EPOLLOUT = 0x00000004
  EPOLLERR = 0x00000008
  EPOLLHUP = 0x00000010
  EPOLLRDHUP = 0x00002000
  EPOLLONESHOT = 1 shl 30

proc epoll_create(size: cint): cint
     {.importc: "epoll_create", header: "<sys/epoll.h>".}
proc epoll_ctl(epfd: cint; op: cint; fd: cint; event: ptr epoll_event): cint
     {.importc: "epoll_ctl", header: "<sys/epoll.h>".}
proc epoll_wait(epfd: cint; events: ptr epoll_event; maxevents: cint;
                 timeout: cint): cint
     {.importc: "epoll_wait", header: "<sys/epoll.h>".}
proc timerfd_create(clock_id: ClockId, flags: cint): cint
     {.cdecl, importc: "timerfd_create", header: "<sys/timerfd.h>".}
proc timerfd_settime(ufd: cint, flags: cint,
                      utmr: var Itimerspec, otmr: var Itimerspec): cint
     {.cdecl, importc: "timerfd_settime", header: "<sys/timerfd.h>".}
proc eventfd(count: cuint, flags: cint): cint
     {.cdecl, importc: "eventfd", header: "<sys/eventfd.h>".}

when not defined(android):
  proc signalfd(fd: cint, mask: var Sigset, flags: cint): cint
       {.cdecl, importc: "signalfd", header: "<sys/signalfd.h>".}

var RLIMIT_NOFILE {.importc: "RLIMIT_NOFILE",
                    header: "<sys/resource.h>".}: cint
type
  rlimit {.importc: "struct rlimit",
           header: "<sys/resource.h>", pure, final.} = object
    rlim_cur: int
    rlim_max: int
proc getrlimit(resource: cint, rlp: var rlimit): cint
     {.importc: "getrlimit",header: "<sys/resource.h>".}

when hasThreadSupport:
  type
    SelectorImpl[T] = object
      epollFD : cint
      maxFD : int
      fds: ptr SharedArray[SelectorKey[T]]
      count: int
    Selector*[T] = ptr SelectorImpl[T]
else:
  type
    SelectorImpl[T] = object
      epollFD : cint
      maxFD : int
      fds: seq[SelectorKey[T]]
      count: int
    Selector*[T] = ref SelectorImpl[T]
type
  SelectEventImpl = object
    efd: cint
  SelectEvent* = ptr SelectEventImpl

proc newSelector*[T](): Selector[T] =
  var a = rlimit()
  if getrlimit(RLIMIT_NOFILE, a) != 0:
    raiseOsError(osLastError())
  var maxFD = int(a.rlim_max)
  doAssert(maxFD > 0)

  var epollFD = epoll_create(MAX_EPOLL_EVENTS)
  if epollFD < 0:
    raiseOsError(osLastError())

  when hasThreadSupport:
    result = cast[Selector[T]](allocShared0(sizeof(SelectorImpl[T])))
    result.epollFD = epollFD
    result.maxFD = maxFD
    result.fds = allocSharedArray[SelectorKey[T]](maxFD)
  else:
    result = Selector[T]()
    result.epollFD = epollFD
    result.maxFD = maxFD
    result.fds = newSeq[SelectorKey[T]](maxFD)

proc close*[T](s: Selector[T]) =
  let res = posix.close(s.epollFD)
  when hasThreadSupport:
    deallocSharedArray(s.fds)
    deallocShared(cast[pointer](s))
  if res != 0:
    raiseIOSelectorsError(osLastError())

template clearKey[T](key: ptr SelectorKey[T]) =
  var empty: T
  key.ident = 0
  key.events = {}
  key.data = empty

proc newSelectEvent*(): SelectEvent =
  let fdci = eventfd(0, 0)
  if fdci == -1:
    raiseIOSelectorsError(osLastError())
  setNonBlocking(fdci)
  result = cast[SelectEvent](allocShared0(sizeof(SelectEventImpl)))
  result.efd = fdci

proc setEvent*(ev: SelectEvent) =
  var data : uint64 = 1
  if posix.write(ev.efd, addr data, sizeof(uint64)) == -1:
    raiseIOSelectorsError(osLastError())

proc close*(ev: SelectEvent) =
  let res = posix.close(ev.efd)
  deallocShared(cast[pointer](ev))
  if res != 0:
    raiseIOSelectorsError(osLastError())

template checkFd(s, f) =
  if f >= s.maxFD:
    raiseIOSelectorsError("Maximum number of descriptors is exhausted!")

proc registerHandle*[T](s: Selector[T], fd: SocketHandle,
                        events: set[Event], data: T) =
  let fdi = int(fd)
  s.checkFd(fdi)
  doAssert(s.fds[fdi].ident == 0)
  s.setKey(fdi, events, 0, data)
  if events != {}:
    var epv = epoll_event(events: EPOLLRDHUP)
    epv.data.u64 = fdi.uint
    if Event.Read in events: epv.events = epv.events or EPOLLIN
    if Event.Write in events: epv.events = epv.events or EPOLLOUT
    if epoll_ctl(s.epollFD, EPOLL_CTL_ADD, fdi.cint, addr epv) != 0:
      raiseIOSelectorsError(osLastError())
    inc(s.count)

proc updateHandle*[T](s: Selector[T], fd: SocketHandle, events: set[Event]) =
  let maskEvents = {Event.Timer, Event.Signal, Event.Process, Event.Vnode,
                    Event.User, Event.Oneshot, Event.Error}
  let fdi = int(fd)
  s.checkFd(fdi)
  var pkey = addr(s.fds[fdi])
  doAssert(pkey.ident != 0,
           "Descriptor [" & $fdi & "] is not registered in the queue!")
  doAssert(pkey.events * maskEvents == {})
  if pkey.events != events:
    var epv = epoll_event(events: EPOLLRDHUP)
    epv.data.u64 = fdi.uint

    if Event.Read in events: epv.events = epv.events or EPOLLIN
    if Event.Write in events: epv.events = epv.events or EPOLLOUT

    if pkey.events == {}:
      if epoll_ctl(s.epollFD, EPOLL_CTL_ADD, fdi.cint, addr epv) != 0:
        raiseIOSelectorsError(osLastError())
      inc(s.count)
    else:
      if events != {}:
        if epoll_ctl(s.epollFD, EPOLL_CTL_MOD, fdi.cint, addr epv) != 0:
          raiseIOSelectorsError(osLastError())
      else:
        if epoll_ctl(s.epollFD, EPOLL_CTL_DEL, fdi.cint, addr epv) != 0:
          raiseIOSelectorsError(osLastError())
        dec(s.count)
    pkey.events = events

proc unregister*[T](s: Selector[T], fd: int|SocketHandle) =
  let fdi = int(fd)
  s.checkFd(fdi)
  var pkey = addr(s.fds[fdi])
  doAssert(pkey.ident != 0,
           "Descriptor [" & $fdi & "] is not registered in the queue!")
  if pkey.events != {}:
    when not defined(android):
      if pkey.events * {Event.Read, Event.Write} != {}:
        var epv = epoll_event()
        if epoll_ctl(s.epollFD, EPOLL_CTL_DEL, fdi.cint, addr epv) != 0:
          raiseIOSelectorsError(osLastError())
        dec(s.count)
      elif Event.Timer in pkey.events:
        if Event.Finished notin pkey.events:
          var epv = epoll_event()
          if epoll_ctl(s.epollFD, EPOLL_CTL_DEL, fdi.cint, addr epv) != 0:
            raiseIOSelectorsError(osLastError())
          dec(s.count)
        if posix.close(cint(fdi)) != 0:
          raiseIOSelectorsError(osLastError())
      elif Event.Signal in pkey.events:
        var epv = epoll_event()
        if epoll_ctl(s.epollFD, EPOLL_CTL_DEL, fdi.cint, addr epv) != 0:
          raiseIOSelectorsError(osLastError())
        var nmask, omask: Sigset
        discard sigemptyset(nmask)
        discard sigemptyset(omask)
        discard sigaddset(nmask, cint(s.fds[fdi].param))
        unblockSignals(nmask, omask)
        dec(s.count)
        if posix.close(cint(fdi)) != 0:
          raiseIOSelectorsError(osLastError())
      elif Event.Process in pkey.events:
        if Event.Finished notin pkey.events:
          var epv = epoll_event()
          if epoll_ctl(s.epollFD, EPOLL_CTL_DEL, fdi.cint, addr epv) != 0:
            raiseIOSelectorsError(osLastError())
          var nmask, omask: Sigset
          discard sigemptyset(nmask)
          discard sigemptyset(omask)
          discard sigaddset(nmask, SIGCHLD)
          unblockSignals(nmask, omask)
          dec(s.count)
        if posix.close(cint(fdi)) != 0:
          raiseIOSelectorsError(osLastError())
    else:
      if pkey.events * {Event.Read, Event.Write} != {}:
        var epv = epoll_event()
        if epoll_ctl(s.epollFD, EPOLL_CTL_DEL, fdi.cint, addr epv) != 0:
          raiseIOSelectorsError(osLastError())
        dec(s.count)
      elif Event.Timer in pkey.events:
        if Event.Finished notin pkey.events:
          var epv = epoll_event()
          if epoll_ctl(s.epollFD, EPOLL_CTL_DEL, fdi.cint, addr epv) != 0:
            raiseIOSelectorsError(osLastError())
          dec(s.count)
        if posix.close(cint(fdi)) != 0:
          raiseIOSelectorsError(osLastError())
  clearKey(pkey)

proc unregister*[T](s: Selector[T], ev: SelectEvent) =
  let fdi = int(ev.efd)
  s.checkFd(fdi)
  var pkey = addr(s.fds[fdi])
  doAssert(pkey.ident != 0, "Event is not registered in the queue!")
  doAssert(Event.User in pkey.events)
  var epv = epoll_event()
  if epoll_ctl(s.epollFD, EPOLL_CTL_DEL, fdi.cint, addr epv) != 0:
    raiseIOSelectorsError(osLastError())
  dec(s.count)
  clearKey(pkey)

proc registerTimer*[T](s: Selector[T], timeout: int, oneshot: bool,
                       data: T): int {.discardable.} =
  var
    new_ts: Itimerspec
    old_ts: Itimerspec
  let fdi = timerfd_create(CLOCK_MONOTONIC, 0).int
  if fdi == -1:
    raiseIOSelectorsError(osLastError())
  setNonBlocking(fdi.cint)

  s.checkFd(fdi)
  doAssert(s.fds[fdi].ident == 0)

  var events = {Event.Timer}
  var epv = epoll_event(events: EPOLLIN or EPOLLRDHUP)
  epv.data.u64 = fdi.uint
  if oneshot:
    new_ts.it_interval.tv_sec = 0.Time
    new_ts.it_interval.tv_nsec = 0
    new_ts.it_value.tv_sec = (timeout div 1_000).Time
    new_ts.it_value.tv_nsec = (timeout %% 1_000) * 1_000_000
    incl(events, Event.Oneshot)
    epv.events = epv.events or EPOLLONESHOT
  else:
    new_ts.it_interval.tv_sec = (timeout div 1000).Time
    new_ts.it_interval.tv_nsec = (timeout %% 1_000) * 1_000_000
    new_ts.it_value.tv_sec = new_ts.it_interval.tv_sec
    new_ts.it_value.tv_nsec = new_ts.it_interval.tv_nsec

  if timerfd_settime(fdi.cint, cint(0), new_ts, old_ts) != 0:
    raiseIOSelectorsError(osLastError())
  if epoll_ctl(s.epollFD, EPOLL_CTL_ADD, fdi.cint, addr epv) != 0:
    raiseIOSelectorsError(osLastError())
  s.setKey(fdi, events, 0, data)
  inc(s.count)
  result = fdi

when not defined(android):
  proc registerSignal*[T](s: Selector[T], signal: int,
                          data: T): int {.discardable.} =
    var
      nmask: Sigset
      omask: Sigset

    discard sigemptyset(nmask)
    discard sigemptyset(omask)
    discard sigaddset(nmask, cint(signal))
    blockSignals(nmask, omask)

    let fdi = signalfd(-1, nmask, 0).int
    if fdi == -1:
      raiseIOSelectorsError(osLastError())
    setNonBlocking(fdi.cint)

    s.checkFd(fdi)
    doAssert(s.fds[fdi].ident == 0)

    var epv = epoll_event(events: EPOLLIN or EPOLLRDHUP)
    epv.data.u64 = fdi.uint
    if epoll_ctl(s.epollFD, EPOLL_CTL_ADD, fdi.cint, addr epv) != 0:
      raiseIOSelectorsError(osLastError())
    s.setKey(fdi, {Event.Signal}, signal, data)
    inc(s.count)
    result = fdi

  proc registerProcess*[T](s: Selector, pid: int,
                           data: T): int {.discardable.} =
    var
      nmask: Sigset
      omask: Sigset

    discard sigemptyset(nmask)
    discard sigemptyset(omask)
    discard sigaddset(nmask, posix.SIGCHLD)
    blockSignals(nmask, omask)

    let fdi = signalfd(-1, nmask, 0).int
    if fdi == -1:
      raiseIOSelectorsError(osLastError())
    setNonBlocking(fdi.cint)

    s.checkFd(fdi)
    doAssert(s.fds[fdi].ident == 0)

    var epv = epoll_event(events: EPOLLIN or EPOLLRDHUP)
    epv.data.u64 = fdi.uint
    epv.events = EPOLLIN or EPOLLRDHUP
    if epoll_ctl(s.epollFD, EPOLL_CTL_ADD, fdi.cint, addr epv) != 0:
      raiseIOSelectorsError(osLastError())
    s.setKey(fdi, {Event.Process, Event.Oneshot}, pid, data)
    inc(s.count)
    result = fdi

proc registerEvent*[T](s: Selector[T], ev: SelectEvent, data: T) =
  let fdi = int(ev.efd)
  doAssert(s.fds[fdi].ident == 0, "Event is already registered in the queue!")
  s.setKey(fdi, {Event.User}, 0, data)
  var epv = epoll_event(events: EPOLLIN or EPOLLRDHUP)
  epv.data.u64 = ev.efd.uint
  if epoll_ctl(s.epollFD, EPOLL_CTL_ADD, ev.efd, addr epv) != 0:
    raiseIOSelectorsError(osLastError())
  inc(s.count)

proc selectInto*[T](s: Selector[T], timeout: int,
                    results: var openarray[ReadyKey]): int =
  var
    resTable: array[MAX_EPOLL_EVENTS, epoll_event]
    maxres = MAX_EPOLL_EVENTS
    i, k: int

  if maxres > len(results):
    maxres = len(results)

  let count = epoll_wait(s.epollFD, addr(resTable[0]), maxres.cint,
                         timeout.cint)
  if count < 0:
    result = 0
    let err = osLastError()
    if cint(err) != EINTR:
      raiseIOSelectorsError(err)
  elif count == 0:
    result = 0
  else:
    i = 0
    k = 0
    while i < count:
      let fdi = int(resTable[i].data.u64)
      let pevents = resTable[i].events
      var pkey = addr(s.fds[fdi])
      doAssert(pkey.ident != 0)
      var rkey = ReadyKey(fd: int(fdi), events: {})

      if (pevents and EPOLLERR) != 0 or (pevents and EPOLLHUP) != 0:
        rkey.events.incl(Event.Error)
      if (pevents and EPOLLOUT) != 0:
        rkey.events.incl(Event.Write)
      when not defined(android):
        if (pevents and EPOLLIN) != 0:
          if Event.Read in pkey.events:
            rkey.events.incl(Event.Read)
          elif Event.Timer in pkey.events:
            var data: uint64 = 0
            if posix.read(cint(fdi), addr data,
                          sizeof(uint64)) != sizeof(uint64):
              raiseIOSelectorsError(osLastError())
            rkey.events.incl(Event.Timer)
          elif Event.Signal in pkey.events:
            var data = SignalFdInfo()
            if posix.read(cint(fdi), addr data,
                          sizeof(SignalFdInfo)) != sizeof(SignalFdInfo):
              raiseIOSelectorsError(osLastError())
            rkey.events.incl(Event.Signal)
          elif Event.Process in pkey.events:
            var data = SignalFdInfo()
            if posix.read(cint(fdi), addr data,
                          sizeof(SignalFdInfo)) != sizeof(SignalFdInfo):
              raiseIOSelectorsError(osLastError())
            if cast[int](data.ssi_pid) == pkey.param:
              rkey.events.incl(Event.Process)
            else:
              inc(i)
              continue
          elif Event.User in pkey.events:
            var data: uint64 = 0
            if posix.read(cint(fdi), addr data,
                          sizeof(uint64)) != sizeof(uint64):
              let err = osLastError()
              if err == OSErrorCode(EAGAIN):
                inc(i)
                continue
              else:
                raiseIOSelectorsError(err)
            rkey.events.incl(Event.User)
      else:
        if (pevents and EPOLLIN) != 0:
          if Event.Read in pkey.events:
            rkey.events.incl(Event.Read)
          elif Event.Timer in pkey.events:
            var data: uint64 = 0
            if posix.read(cint(fdi), addr data,
                          sizeof(uint64)) != sizeof(uint64):
              raiseIOSelectorsError(osLastError())
            rkey.events.incl(Event.Timer)
          elif Event.User in pkey.events:
            var data: uint64 = 0
            if posix.read(cint(fdi), addr data,
                          sizeof(uint64)) != sizeof(uint64):
              let err = osLastError()
              if err == OSErrorCode(EAGAIN):
                inc(i)
                continue
              else:
                raiseIOSelectorsError(err)
            rkey.events.incl(Event.User)

      if Event.Oneshot in pkey.events:
        var epv = epoll_event()
        if epoll_ctl(s.epollFD, EPOLL_CTL_DEL, cint(fdi), addr epv) != 0:
          raiseIOSelectorsError(osLastError())
        # we will not clear key until it will be unregistered, so
        # application can obtain data, but we will decrease counter,
        # because epoll is empty.
        dec(s.count)
        # we are marking key with `Finished` event, to avoid double decrease.
        pkey.events.incl(Event.Finished)

      results[k] = rkey
      inc(k)
      inc(i)
    result = k

proc select*[T](s: Selector[T], timeout: int): seq[ReadyKey] =
  result = newSeq[ReadyKey](MAX_EPOLL_EVENTS)
  let count = selectInto(s, timeout, result)
  result.setLen(count)

template isEmpty*[T](s: Selector[T]): bool =
  (s.count == 0)

proc getData*[T](s: Selector[T], fd: SocketHandle|int): T =
  let fdi = int(fd)
  s.checkFd(fdi)
  if s.fds[fdi].ident != 0:
    result = s.fds[fdi].data

proc setData*[T](s: Selector[T], fd: SocketHandle|int, data: T): bool =
  let fdi = int(fd)
  s.checkFd(fdi)
  if s.fds[fdi].ident != 0:
    s.fds[fdi].data = data
    result = true

template withData*[T](s: Selector[T], fd: SocketHandle|int, value,
                        body: untyped) =
  mixin checkFd
  let fdi = int(fd)
  s.checkFd(fdi)
  if s.fds[fdi].ident != 0:
    var value = addr(s.fds[fdi].data)
    body

template withData*[T](s: Selector[T], fd: SocketHandle|int, value, body1,
                        body2: untyped) =
  mixin checkFd
  let fdi = int(fd)
  s.checkFd(fdi)
  if s.fds[fdi].ident != 0:
    var value = addr(s.fds[fdi].data)
    body1
  else:
    body2
