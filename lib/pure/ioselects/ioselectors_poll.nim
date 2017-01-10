#
#
#            Nim's Runtime Library
#        (c) Copyright 2016 Eugene Kabanov
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

# This module implements Posix poll().

import posix, times

# Maximum number of events that can be returned
const MAX_POLL_RESULT_EVENTS = 64

when hasThreadSupport:
  type
    SelectorImpl[T] = object
      maxFD : int
      pollcnt: int
      fds: ptr SharedArray[SelectorKey[T]]
      pollfds: ptr SharedArray[TPollFd]
      count: int
      lock: Lock
    Selector*[T] = ptr SelectorImpl[T]
else:
  type
    SelectorImpl[T] = object
      maxFD : int
      pollcnt: int
      fds: seq[SelectorKey[T]]
      pollfds: seq[TPollFd]
      count: int
    Selector*[T] = ref SelectorImpl[T]

type
  SelectEventImpl = object
    rfd: cint
    wfd: cint
  SelectEvent* = ptr SelectEventImpl

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
  template withPollLock[T](s: Selector[T], body: untyped) =
    acquire(s.lock)
    {.locks: [s.lock].}:
      try:
        body
      finally:
        release(s.lock)
else:
  template withPollLock(s, body: untyped) =
    body

proc newSelector*[T](): Selector[T] =
  var a = rlimit()
  if getrlimit(RLIMIT_NOFILE, a) != 0:
    raiseOsError(osLastError())
  var maxFD = int(a.rlim_max)

  when hasThreadSupport:
    result = cast[Selector[T]](allocShared0(sizeof(SelectorImpl[T])))
    result.maxFD = maxFD
    result.fds = allocSharedArray[SelectorKey[T]](maxFD)
    result.pollfds = allocSharedArray[TPollFd](maxFD)
    initLock(result.lock)
  else:
    result = Selector[T]()
    result.maxFD = maxFD
    result.fds = newSeq[SelectorKey[T]](maxFD)
    result.pollfds = newSeq[TPollFd](maxFD)

proc close*[T](s: Selector[T]) =
  when hasThreadSupport:
    deinitLock(s.lock)
    deallocSharedArray(s.fds)
    deallocSharedArray(s.pollfds)
    deallocShared(cast[pointer](s))

template pollAdd[T](s: Selector[T], sock: cint, events: set[Event]) =
  withPollLock(s):
    var pollev: cshort = 0
    if Event.Read in events: pollev = pollev or POLLIN
    if Event.Write in events: pollev = pollev or POLLOUT
    s.pollfds[s.pollcnt].fd = cint(sock)
    s.pollfds[s.pollcnt].events = pollev
    inc(s.count)
    inc(s.pollcnt)

template pollUpdate[T](s: Selector[T], sock: cint, events: set[Event]) =
  withPollLock(s):
    var i = 0
    var pollev: cshort = 0
    if Event.Read in events: pollev = pollev or POLLIN
    if Event.Write in events: pollev = pollev or POLLOUT

    while i < s.pollcnt:
      if s.pollfds[i].fd == sock:
        s.pollfds[i].events = pollev
        break
      inc(i)

    if i == s.pollcnt:
      raise newException(ValueError, "Descriptor is not registered in queue")

template pollRemove[T](s: Selector[T], sock: cint) =
  withPollLock(s):
    var i = 0
    while i < s.pollcnt:
      if s.pollfds[i].fd == sock:
        if i == s.pollcnt - 1:
          s.pollfds[i].fd = 0
          s.pollfds[i].events = 0
          s.pollfds[i].revents = 0
        else:
          while i < (s.pollcnt - 1):
            s.pollfds[i].fd = s.pollfds[i + 1].fd
            s.pollfds[i].events = s.pollfds[i + 1].events
            inc(i)
        break
      inc(i)
    dec(s.pollcnt)
    dec(s.count)

template checkFd(s, f) =
  if f >= s.maxFD:
    raise newException(ValueError, "Maximum file descriptors exceeded")

proc registerHandle*[T](s: Selector[T], fd: SocketHandle,
                        events: set[Event], data: T) =
  var fdi = int(fd)
  s.checkFd(fdi)
  doAssert(s.fds[fdi].ident == 0)
  s.setKey(fdi, fdi, events, 0, data)
  if events != {}: s.pollAdd(fdi.cint, events)

proc updateHandle*[T](s: Selector[T], fd: SocketHandle,
                      events: set[Event]) =
  let maskEvents = {Event.Timer, Event.Signal, Event.Process, Event.Vnode,
                    Event.User, Event.Oneshot, Event.Error}
  let fdi = int(fd)
  s.checkFd(fdi)
  var pkey = addr(s.fds[fdi])
  doAssert(pkey.ident != 0)
  doAssert(pkey.events * maskEvents == {})

  if pkey.events != events:
    if pkey.events == {}:
      s.pollAdd(fd.cint, events)
    else:
      if events != {}:
        s.pollUpdate(fd.cint, events)
      else:
        s.pollRemove(fd.cint)
    pkey.events = events

proc registerEvent*[T](s: Selector[T], ev: SelectEvent, data: T) =
  var fdi = int(ev.rfd)
  doAssert(s.fds[fdi].ident == 0)
  var events = {Event.User}
  setKey(s, fdi, fdi, events, 0, data)
  events.incl(Event.Read)
  s.pollAdd(fdi.cint, events)

proc flush*[T](s: Selector[T]) = discard

proc unregister*[T](s: Selector[T], fd: int|SocketHandle) =
  let fdi = int(fd)
  s.checkFd(fdi)
  var pkey = addr(s.fds[fdi])
  doAssert(pkey.ident != 0)
  pkey.ident = 0
  pkey.events = {}
  s.pollRemove(fdi.cint)

proc unregister*[T](s: Selector[T], ev: SelectEvent) =
  let fdi = int(ev.rfd)
  s.checkFd(fdi)
  var pkey = addr(s.fds[fdi])
  doAssert(pkey.ident != 0)
  doAssert(Event.User in pkey.events)
  pkey.ident = 0
  pkey.events = {}
  s.pollRemove(fdi.cint)

proc newSelectEvent*(): SelectEvent =
  var fds: array[2, cint]
  if posix.pipe(fds) == -1:
    raiseOSError(osLastError())
  setNonBlocking(fds[0])
  setNonBlocking(fds[1])
  result = cast[SelectEvent](allocShared0(sizeof(SelectEventImpl)))
  result.rfd = fds[0]
  result.wfd = fds[1]

proc setEvent*(ev: SelectEvent) =
  var data: uint64 = 1
  if posix.write(ev.wfd, addr data, sizeof(uint64)) != sizeof(uint64):
    raiseOSError(osLastError())

proc close*(ev: SelectEvent) =
  discard posix.close(cint(ev.rfd))
  discard posix.close(cint(ev.wfd))
  deallocShared(cast[pointer](ev))

proc selectInto*[T](s: Selector[T], timeout: int,
                    results: var openarray[ReadyKey[T]]): int =
  var maxres = MAX_POLL_RESULT_EVENTS
  if maxres > len(results):
    maxres = len(results)

  s.withPollLock():
    let count = posix.poll(addr(s.pollfds[0]), Tnfds(s.pollcnt), timeout)
    if count < 0:
      result = 0
      let err = osLastError()
      if err.cint == EINTR:
        discard
      else:
        raiseOSError(osLastError())
    elif count == 0:
      result = 0
    else:
      var i = 0
      var k = 0
      var rindex = 0
      while (i < s.pollcnt) and (k < count) and (rindex < maxres):
        let revents = s.pollfds[i].revents
        if revents != 0:
          let fd = s.pollfds[i].fd
          var skey = addr(s.fds[fd])
          skey.key.events = {}

          if (revents and POLLIN) != 0:
            skey.key.events.incl(Event.Read)
            if Event.User in skey.events:
              var data: uint64 = 0
              if posix.read(fd, addr data, sizeof(uint64)) != sizeof(uint64):
                let err = osLastError()
                if err != OSErrorCode(EAGAIN):
                  raiseOSError(osLastError())
                else:
                  # someone already consumed event data
                  inc(i)
                  continue
              skey.key.events = {Event.User}
          if (revents and POLLOUT) != 0:
            skey.key.events.incl(Event.Write)
          if (revents and POLLERR) != 0 or (revents and POLLHUP) != 0 or
             (revents and POLLNVAL) != 0:
            skey.key.events.incl(Event.Error)
          results[rindex] = skey.key
          s.pollfds[i].revents = 0
          inc(rindex)
          inc(k)
        inc(i)
      result = k

proc select*[T](s: Selector[T], timeout: int): seq[ReadyKey[T]] =
  result = newSeq[ReadyKey[T]](MAX_POLL_RESULT_EVENTS)
  let count = selectInto(s, timeout, result)
  result.setLen(count)

template isEmpty*[T](s: Selector[T]): bool =
  (s.count == 0)

template withData*[T](s: Selector[T], fd: SocketHandle, value,
                        body: untyped) =
  mixin checkFd
  let fdi = int(fd)
  s.checkFd(fdi)
  if s.fds[fdi].ident != 0:
    var value = addr(s.fds[fdi].key.data)
    body

template withData*[T](s: Selector[T], fd: SocketHandle, value, body1,
                        body2: untyped) =
  mixin checkFd
  let fdi = int(fd)
  s.checkFd(fdi)
  if s.fds[fdi].ident != 0:
    var value = addr(s.fds[fdi].key.data)
    body1
  else:
    body2
