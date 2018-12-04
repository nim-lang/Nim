#
#
#            Nim's Runtime Library
#        (c) Copyright 2016 Eugene Kabanov
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

# This module implements Linux epoll().

import posix, times, epoll

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

when hasThreadSupport:
  type
    SelectorImpl[T] = object
      epollFD: cint
      maxFD: int
      fds: ptr SharedArray[SelectorKey[T]]
      count: int
    Selector*[T] = ptr SelectorImpl[T]
else:
  type
    SelectorImpl[T] = object
      epollFD: cint
      maxFD: int
      fds: seq[SelectorKey[T]]
      count: int
    Selector*[T] = ref SelectorImpl[T]
type
  SelectEventImpl = object
    efd: cint
  SelectEvent* = ptr SelectEventImpl

proc newSelector*[T](): Selector[T] =
  # Retrieve the maximum fd count (for current OS) via getrlimit()
  var a = RLimit()
  if getrlimit(posix.RLIMIT_NOFILE, a) != 0:
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

  for i in 0 ..< maxFD:
    result.fds[i].ident = InvalidIdent

proc close*[T](s: Selector[T]) =
  let res = posix.close(s.epollFD)
  when hasThreadSupport:
    deallocSharedArray(s.fds)
    deallocShared(cast[pointer](s))
  if res != 0:
    raiseIOSelectorsError(osLastError())

proc newSelectEvent*(): SelectEvent =
  let fdci = eventfd(0, 0)
  if fdci == -1:
    raiseIOSelectorsError(osLastError())
  setNonBlocking(fdci)
  result = cast[SelectEvent](allocShared0(sizeof(SelectEventImpl)))
  result.efd = fdci

proc trigger*(ev: SelectEvent) =
  var data: uint64 = 1
  if posix.write(ev.efd, addr data, sizeof(uint64)) == -1:
    raiseIOSelectorsError(osLastError())

proc close*(ev: SelectEvent) =
  let res = posix.close(ev.efd)
  deallocShared(cast[pointer](ev))
  if res != 0:
    raiseIOSelectorsError(osLastError())

template checkFd(s, f) =
  # TODO: I don't see how this can ever happen. You won't be able to create an
  # FD if there is too many. -- DP
  if f >= s.maxFD:
    raiseIOSelectorsError("Maximum number of descriptors is exhausted!")

proc registerHandle*[T](s: Selector[T], fd: int | SocketHandle,
                        events: set[Event], data: T) =
  let fdi = int(fd)
  s.checkFd(fdi)
  doAssert(s.fds[fdi].ident == InvalidIdent, "Descriptor $# already registered" % $fdi)
  s.setKey(fdi, events, 0, data)
  if events != {}:
    var epv = EpollEvent(events: EPOLLRDHUP)
    epv.data.u64 = fdi.uint
    if Event.Read in events: epv.events = epv.events or EPOLLIN
    if Event.Write in events: epv.events = epv.events or EPOLLOUT
    if epoll_ctl(s.epollFD, EPOLL_CTL_ADD, fdi.cint, addr epv) != 0:
      raiseIOSelectorsError(osLastError())
    inc(s.count)

proc updateHandle*[T](s: Selector[T], fd: int | SocketHandle, events: set[Event]) =
  let maskEvents = {Event.Timer, Event.Signal, Event.Process, Event.Vnode,
                    Event.User, Event.Oneshot, Event.Error}
  let fdi = int(fd)
  s.checkFd(fdi)
  var pkey = addr(s.fds[fdi])
  doAssert(pkey.ident != InvalidIdent,
           "Descriptor $# is not registered in the selector!" % $fdi)
  doAssert(pkey.events * maskEvents == {})
  if pkey.events != events:
    var epv = EpollEvent(events: EPOLLRDHUP)
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
  doAssert(pkey.ident != InvalidIdent,
           "Descriptor $# is not registered in the selector!" % $fdi)
  if pkey.events != {}:
    when not defined(android):
      if pkey.events * {Event.Read, Event.Write} != {}:
        var epv = EpollEvent()
        # TODO: Refactor all these EPOLL_CTL_DEL + dec(s.count) into a proc.
        if epoll_ctl(s.epollFD, EPOLL_CTL_DEL, fdi.cint, addr epv) != 0:
          raiseIOSelectorsError(osLastError())
        dec(s.count)
      elif Event.Timer in pkey.events:
        if Event.Finished notin pkey.events:
          var epv = EpollEvent()
          if epoll_ctl(s.epollFD, EPOLL_CTL_DEL, fdi.cint, addr epv) != 0:
            raiseIOSelectorsError(osLastError())
          dec(s.count)
        if posix.close(cint(fdi)) != 0:
          raiseIOSelectorsError(osLastError())
      elif Event.Signal in pkey.events:
        var epv = EpollEvent()
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
          var epv = EpollEvent()
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
        var epv = EpollEvent()
        if epoll_ctl(s.epollFD, EPOLL_CTL_DEL, fdi.cint, addr epv) != 0:
          raiseIOSelectorsError(osLastError())
        dec(s.count)
      elif Event.Timer in pkey.events:
        if Event.Finished notin pkey.events:
          var epv = EpollEvent()
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
  doAssert(pkey.ident != InvalidIdent, "Event is not registered in the queue!")
  doAssert(Event.User in pkey.events)
  var epv = EpollEvent()
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
  doAssert(s.fds[fdi].ident == InvalidIdent)

  var events = {Event.Timer}
  var epv = EpollEvent(events: EPOLLIN or EPOLLRDHUP)
  epv.data.u64 = fdi.uint

  if oneshot:
    new_ts.it_interval.tv_sec = posix.Time(0)
    new_ts.it_interval.tv_nsec = 0
    new_ts.it_value.tv_sec = posix.Time(timeout div 1_000)
    new_ts.it_value.tv_nsec = (timeout %% 1_000) * 1_000_000
    incl(events, Event.Oneshot)
    epv.events = epv.events or EPOLLONESHOT
  else:
    new_ts.it_interval.tv_sec = posix.Time(timeout div 1000)
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
    doAssert(s.fds[fdi].ident == InvalidIdent)

    var epv = EpollEvent(events: EPOLLIN or EPOLLRDHUP)
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
    doAssert(s.fds[fdi].ident == InvalidIdent)

    var epv = EpollEvent(events: EPOLLIN or EPOLLRDHUP)
    epv.data.u64 = fdi.uint
    epv.events = EPOLLIN or EPOLLRDHUP
    if epoll_ctl(s.epollFD, EPOLL_CTL_ADD, fdi.cint, addr epv) != 0:
      raiseIOSelectorsError(osLastError())
    s.setKey(fdi, {Event.Process, Event.Oneshot}, pid, data)
    inc(s.count)
    result = fdi

proc registerEvent*[T](s: Selector[T], ev: SelectEvent, data: T) =
  let fdi = int(ev.efd)
  doAssert(s.fds[fdi].ident == InvalidIdent, "Event is already registered in the queue!")
  s.setKey(fdi, {Event.User}, 0, data)
  var epv = EpollEvent(events: EPOLLIN or EPOLLRDHUP)
  epv.data.u64 = ev.efd.uint
  if epoll_ctl(s.epollFD, EPOLL_CTL_ADD, ev.efd, addr epv) != 0:
    raiseIOSelectorsError(osLastError())
  inc(s.count)

proc selectInto*[T](s: Selector[T], timeout: int,
                    results: var openarray[ReadyKey]): int =
  var
    resTable: array[MAX_EPOLL_EVENTS, EpollEvent]
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
      doAssert(pkey.ident != InvalidIdent)
      var rkey = ReadyKey(fd: fdi, events: {})

      if (pevents and EPOLLERR) != 0 or (pevents and EPOLLHUP) != 0:
        if (pevents and EPOLLHUP) != 0:
          rkey.errorCode = OSErrorCode ECONNRESET
        else:
          # Try reading SO_ERROR from fd.
          var error: cint
          var size = SockLen sizeof(error)
          if getsockopt(SocketHandle fdi, SOL_SOCKET, SO_ERROR, addr(error),
                        addr(size)) == 0'i32:
            rkey.errorCode = OSErrorCode error

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
        var epv = EpollEvent()
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

proc contains*[T](s: Selector[T], fd: SocketHandle|int): bool {.inline.} =
  return s.fds[fd.int].ident != InvalidIdent

proc getData*[T](s: Selector[T], fd: SocketHandle|int): var T =
  let fdi = int(fd)
  s.checkFd(fdi)
  if fdi in s:
    result = s.fds[fdi].data

proc setData*[T](s: Selector[T], fd: SocketHandle|int, data: T): bool =
  let fdi = int(fd)
  s.checkFd(fdi)
  if fdi in s:
    s.fds[fdi].data = data
    result = true

template withData*[T](s: Selector[T], fd: SocketHandle|int, value,
                        body: untyped) =
  mixin checkFd
  let fdi = int(fd)
  s.checkFd(fdi)
  if fdi in s:
    var value = addr(s.getData(fdi))
    body

template withData*[T](s: Selector[T], fd: SocketHandle|int, value, body1,
                        body2: untyped) =
  mixin checkFd
  let fdi = int(fd)
  s.checkFd(fdi)
  if fdi in s:
    var value = addr(s.getData(fdi))
    body1
  else:
    body2

proc getFd*[T](s: Selector[T]): int =
  return s.epollFd.int
