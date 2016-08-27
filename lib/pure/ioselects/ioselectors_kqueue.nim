#
#
#            Nim's Runtime Library
#        (c) Copyright 2016 Eugene Kabanov
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

#  This module implements BSD kqueue().

import posix, times, kqueue

const
  # Maximum number of cached changes.
  MAX_KQUEUE_CHANGE_EVENTS = 64
  # Maximum number of events that can be returned.
  MAX_KQUEUE_RESULT_EVENTS = 64
  # SIG_IGN and SIG_DFL declared in posix.nim as variables, but we need them
  # to be constants and GC-safe.
  SIG_DFL = cast[proc(x: cint) {.noconv,gcsafe.}](0)
  SIG_IGN = cast[proc(x: cint) {.noconv,gcsafe.}](1)

when defined(macosx) or defined(freebsd):
  when defined(macosx):
    const MAX_DESCRIPTORS_ID = 29 # KERN_MAXFILESPERPROC (MacOS)
  else:
    const MAX_DESCRIPTORS_ID = 27 # KERN_MAXFILESPERPROC (FreeBSD)
  proc sysctl(name: ptr cint, namelen: cuint, oldp: pointer, oldplen: ptr int,
              newp: pointer, newplen: int): cint
       {.importc: "sysctl",header: """#include <sys/types.h>
                                      #include <sys/sysctl.h>"""}
elif defined(netbsd) or defined(openbsd):
  # OpenBSD and NetBSD don't have KERN_MAXFILESPERPROC, so we are using
  # KERN_MAXFILES, because KERN_MAXFILES is always bigger,
  # than KERN_MAXFILESPERPROC.
  const MAX_DESCRIPTORS_ID = 7 # KERN_MAXFILES
  proc sysctl(name: ptr cint, namelen: cuint, oldp: pointer, oldplen: ptr int,
              newp: pointer, newplen: int): cint
       {.importc: "sysctl",header: """#include <sys/param.h>
                                      #include <sys/sysctl.h>"""}

when hasThreadSupport:
  type
    SelectorImpl[T] = object
      kqFD : cint
      maxFD : int
      changesTable: array[MAX_KQUEUE_CHANGE_EVENTS, KEvent]
      changesCount: int
      fds: ptr SharedArray[SelectorKey[T]]
      count: int
      changesLock: Lock
    Selector*[T] = ptr SelectorImpl[T]
else:
  type
    SelectorImpl[T] = object
      kqFD : cint
      maxFD : int
      changesTable: array[MAX_KQUEUE_CHANGE_EVENTS, KEvent]
      changesCount: int
      fds: seq[SelectorKey[T]]
      count: int
    Selector*[T] = ref SelectorImpl[T]

type
  SelectEventImpl = object
    rfd: cint
    wfd: cint
# SelectEvent is declared as `ptr` to be placed in `shared memory`,
# so you can share one SelectEvent handle between threads.
type SelectEvent* = ptr SelectEventImpl

proc newSelector*[T](): Selector[T] =
  var maxFD = 0.cint
  var size = sizeof(cint)
  var namearr = [1.cint, MAX_DESCRIPTORS_ID.cint]
  # Obtain maximum number of file descriptors for process
  if sysctl(addr(namearr[0]), 2, cast[pointer](addr maxFD), addr size,
            nil, 0) != 0:
    raiseOsError(osLastError())

  var kqFD = kqueue()
  if kqFD < 0:
    raiseOsError(osLastError())

  when hasThreadSupport:
    result = cast[Selector[T]](allocShared0(sizeof(SelectorImpl[T])))
    result.kqFD = kqFD
    result.maxFD = maxFD.int
    result.fds = allocSharedArray[SelectorKey[T]](maxFD)
    initLock(result.changesLock)
  else:
    result = Selector[T]()
    result.kqFD = kqFD
    result.maxFD = maxFD.int
    result.fds = newSeq[SelectorKey[T]](maxFD)

proc close*[T](s: Selector[T]) =
  if posix.close(s.kqFD) != 0:
    raiseOSError(osLastError())
  when hasThreadSupport:
    deinitLock(s.changesLock)
    deallocSharedArray(s.fds)
    deallocShared(cast[pointer](s))

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

template checkFd(s, f) =
  if f >= s.maxFD:
    raise newException(ValueError, "Maximum file descriptors exceeded")

when hasThreadSupport:
  template withChangeLock[T](s: Selector[T], body: untyped) =
    acquire(s.changesLock)
    {.locks: [s.changesLock].}:
      try:
        body
      finally:
        release(s.changesLock)
else:
  template withChangeLock(s, body: untyped) =
    body

template modifyKQueue[T](s: Selector[T], nident: uint, nfilter: cshort,
                         nflags: cushort, nfflags: cuint, ndata: int,
                         nudata: pointer) =
  mixin withChangeLock
  s.withChangeLock():
    s.changesTable[s.changesCount] = KEvent(ident: nident,
                                            filter: nfilter, flags: nflags,
                                            fflags: nfflags, data: ndata,
                                            udata: nudata)
    inc(s.changesCount)
    if s.changesCount == MAX_KQUEUE_CHANGE_EVENTS:
      if kevent(s.kqFD, addr(s.changesTable[0]), cint(s.changesCount),
                nil, 0, nil) == -1:
        raiseOSError(osLastError())
      s.changesCount = 0

proc registerHandle*[T](s: Selector[T], fd: SocketHandle,
                        events: set[Event], data: T) =
  let fdi = int(fd)
  s.checkFd(fdi)
  doAssert(s.fds[fdi].ident == 0)
  s.setKey(fdi, fdi, events, 0, data)
  if events != {}:
    if Event.Read in events:
      modifyKQueue(s, fdi.uint, EVFILT_READ, EV_ADD, 0, 0, nil)
      inc(s.count)
    if Event.Write in events:
      modifyKQueue(s, fdi.uint, EVFILT_WRITE, EV_ADD, 0, 0, nil)
      inc(s.count)

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
    if (Event.Read in pkey.events) and (Event.Read notin events):
      modifyKQueue(s, fdi.uint, EVFILT_READ, EV_DELETE, 0, 0, nil)
      dec(s.count)
    if (Event.Write in pkey.events) and (Event.Write notin events):
      modifyKQueue(s, fdi.uint, EVFILT_WRITE, EV_DELETE, 0, 0, nil)
      dec(s.count)
    if (Event.Read notin pkey.events) and (Event.Read in events):
      modifyKQueue(s, fdi.uint, EVFILT_READ, EV_ADD, 0, 0, nil)
      inc(s.count)
    if (Event.Write notin pkey.events) and (Event.Write in events):
      modifyKQueue(s, fdi.uint, EVFILT_WRITE, EV_ADD, 0, 0, nil)
      inc(s.count)
    pkey.events = events

proc registerTimer*[T](s: Selector[T], timeout: int, oneshot: bool,
                       data: T): int {.discardable.} =
  var fdi = posix.socket(posix.AF_INET, posix.SOCK_STREAM,
                         posix.IPPROTO_TCP).int
  if fdi == -1:
    raiseOsError(osLastError())

  s.checkFd(fdi)
  doAssert(s.fds[fdi].ident == 0)

  let events = if oneshot: {Event.Timer, Event.Oneshot} else: {Event.Timer}
  let flags: cushort = if oneshot: EV_ONESHOT or EV_ADD else: EV_ADD

  s.setKey(fdi, fdi, events, 0, data)
  # EVFILT_TIMER on Open/Net(BSD) has granularity of only milliseconds,
  # but MacOS and FreeBSD allow use `0` as `fflags` to use milliseconds
  # too
  modifyKQueue(s, fdi.uint, EVFILT_TIMER, flags, 0, cint(timeout), nil)
  inc(s.count)
  result = fdi

proc registerSignal*[T](s: Selector[T], signal: int,
                        data: T): int {.discardable.} =
  var fdi = posix.socket(posix.AF_INET, posix.SOCK_STREAM,
                         posix.IPPROTO_TCP).int
  if fdi == -1:
    raiseOsError(osLastError())

  s.checkFd(fdi)
  doAssert(s.fds[fdi].ident == 0)

  s.setKey(fdi, signal, {Event.Signal}, signal, data)
  var nmask, omask: Sigset
  discard sigemptyset(nmask)
  discard sigemptyset(omask)
  discard sigaddset(nmask, cint(signal))
  blockSignals(nmask, omask)
  # to be compatible with linux semantic we need to "eat" signals
  posix.signal(cint(signal), SIG_IGN)
  modifyKQueue(s, signal.uint, EVFILT_SIGNAL, EV_ADD, 0, 0,
               cast[pointer](fdi))
  inc(s.count)
  result = fdi

proc registerProcess*[T](s: Selector[T], pid: int,
                             data: T): int {.discardable.} =
  var fdi = posix.socket(posix.AF_INET, posix.SOCK_STREAM,
                         posix.IPPROTO_TCP).int
  if fdi == -1:
    raiseOsError(osLastError())

  s.checkFd(fdi)
  doAssert(s.fds[fdi].ident == 0)

  var kflags: cushort = EV_ONESHOT or EV_ADD
  setKey(s, fdi, pid, {Event.Process, Event.Oneshot}, pid, data)
  modifyKQueue(s, pid.uint, EVFILT_PROC, kflags, NOTE_EXIT, 0,
               cast[pointer](fdi))
  inc(s.count)
  result = fdi

proc registerEvent*[T](s: Selector[T], ev: SelectEvent, data: T) =
  let fdi = ev.rfd.int
  doAssert(s.fds[fdi].ident == 0)
  setKey(s, fdi, fdi, {Event.User}, 0, data)
  modifyKQueue(s, fdi.uint, EVFILT_READ, EV_ADD, 0, 0, nil)
  inc(s.count)

proc unregister*[T](s: Selector[T], fd: int|SocketHandle) =
  let fdi = int(fd)
  s.checkFd(fdi)
  var pkey = addr(s.fds[fdi])
  doAssert(pkey.ident != 0)

  if pkey.events != {}:
    if pkey.events * {Event.Read, Event.Write} != {}:
      if Event.Read in pkey.events:
        modifyKQueue(s, fdi.uint, EVFILT_READ, EV_DELETE, 0, 0, nil)
        dec(s.count)
      if Event.Write in pkey.events:
        modifyKQueue(s, fdi.uint, EVFILT_WRITE, EV_DELETE, 0, 0, nil)
        dec(s.count)
    elif Event.Timer in pkey.events:
      discard posix.close(cint(pkey.key.fd))
      modifyKQueue(s, fdi.uint, EVFILT_TIMER, EV_DELETE, 0, 0, nil)
      dec(s.count)
    elif Event.Signal in pkey.events:
      var nmask, omask: Sigset
      var signal = cint(pkey.param)
      discard sigemptyset(nmask)
      discard sigemptyset(omask)
      discard sigaddset(nmask, signal)
      unblockSignals(nmask, omask)
      posix.signal(signal, SIG_DFL)
      discard posix.close(cint(pkey.key.fd))
      modifyKQueue(s, fdi.uint, EVFILT_SIGNAL, EV_DELETE, 0, 0, nil)
      dec(s.count)
    elif Event.Process in pkey.events:
      discard posix.close(cint(pkey.key.fd))
      modifyKQueue(s, fdi.uint, EVFILT_PROC, EV_DELETE, 0, 0, nil)
      dec(s.count)
    elif Event.User in pkey.events:
      modifyKQueue(s, fdi.uint, EVFILT_READ, EV_DELETE, 0, 0, nil)
      dec(s.count)
  pkey.ident = 0
  pkey.events = {}

proc unregister*[T](s: Selector[T], ev: SelectEvent) =
  let fdi = int(ev.rfd)
  s.checkFd(fdi)
  var pkey = addr(s.fds[fdi])
  doAssert(pkey.ident != 0)
  doAssert(Event.User in pkey.events)
  pkey.ident = 0
  pkey.events = {}
  modifyKQueue(s, fdi.uint, EVFILT_READ, EV_DELETE, 0, 0, nil)
  dec(s.count)

proc flush*[T](s: Selector[T]) =
  s.withChangeLock():
    var tv = Timespec()
    if kevent(s.kqFD, addr(s.changesTable[0]), cint(s.changesCount),
              nil, 0, addr tv) == -1:
      raiseOSError(osLastError())
    s.changesCount = 0

proc selectInto*[T](s: Selector[T], timeout: int,
                    results: var openarray[ReadyKey[T]]): int =
  var
    tv: Timespec
    resTable: array[MAX_KQUEUE_RESULT_EVENTS, KEvent]
    ptv = addr tv
    maxres = MAX_KQUEUE_RESULT_EVENTS

  if timeout != -1:
    if timeout >= 1000:
      tv.tv_sec = (timeout div 1_000).Time
      tv.tv_nsec = (timeout %% 1_000) * 1_000_000
    else:
      tv.tv_sec = 0.Time
      tv.tv_nsec = timeout * 1_000_000
  else:
    ptv = nil

  if maxres > len(results):
    maxres = len(results)

  var count = 0
  s.withChangeLock():
    count = kevent(s.kqFD, addr(s.changesTable[0]), cint(s.changesCount),
                   addr(resTable[0]), cint(maxres), ptv)
    s.changesCount = 0

  if count < 0:
    result = 0
    let err = osLastError()
    if cint(err) != EINTR:
      raiseOSError(err)
  elif count == 0:
    result = 0
  else:
    var i = 0
    var k = 0
    var pkey: ptr SelectorKey[T]
    while i < count:
      let kevent = addr(resTable[i])
      if (kevent.flags and EV_ERROR) == 0:
        case kevent.filter:
        of EVFILT_READ:
          pkey = addr(s.fds[kevent.ident.int])
          pkey.key.events = {Event.Read}
          if Event.User in pkey.events:
            var data: uint64 = 0
            if posix.read(kevent.ident.cint, addr data,
                          sizeof(uint64)) != sizeof(uint64):
              let err = osLastError()
              if err == OSErrorCode(EAGAIN):
                # someone already consumed event data
                inc(i)
                continue
              else:
                raiseOSError(osLastError())
            pkey.key.events = {Event.User}
        of EVFILT_WRITE:
          pkey = addr(s.fds[kevent.ident.int])
          pkey.key.events = {Event.Write}
        of EVFILT_TIMER:
          pkey = addr(s.fds[kevent.ident.int])
          if Event.Oneshot in pkey.events:
            if posix.close(cint(pkey.ident)) == -1:
              raiseOSError(osLastError())
            pkey.ident = 0
            pkey.events = {}
            dec(s.count)
          pkey.key.events = {Event.Timer}
        of EVFILT_VNODE:
          pkey = addr(s.fds[kevent.ident.int])
          pkey.key.events = {Event.Vnode}
        of EVFILT_SIGNAL:
          pkey = addr(s.fds[cast[int](kevent.udata)])
          pkey.key.events = {Event.Signal}
        of EVFILT_PROC:
          pkey = addr(s.fds[cast[int](kevent.udata)])
          if posix.close(cint(pkey.ident)) == -1:
            raiseOSError(osLastError())
          pkey.ident = 0
          pkey.events = {}
          dec(s.count)
          pkey.key.events = {Event.Process}
        else:
          raise newException(ValueError, "Unsupported kqueue filter in queue")

        if (kevent.flags and EV_EOF) != 0:
          pkey.key.events.incl(Event.Error)

        results[k] = pkey.key
        inc(k)
      inc(i)
    result = k

proc select*[T](s: Selector[T], timeout: int): seq[ReadyKey[T]] =
  result = newSeq[ReadyKey[T]](MAX_KQUEUE_RESULT_EVENTS)
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
