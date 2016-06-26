#
#
#            Nim's Runtime Library
#        (c) Copyright 2016 Eugene Kabanov
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## This module allows high-level and efficient I/O multiplexing.
##
## Supported OS primitives: ``epoll``, ``kqueue``, ``poll`` and
## Windows ``select``.
##
## To use threadsafe version of this module, it needs to be compiled
## with both ``-d:threadsafe`` and ``--threads:on`` options.
##
## Supported features: files, sockets, pipes, timers, processes, signals
## and user events.
##
## Fully supported OS: MacOSX, FreeBSD, OpenBSD, NetBSD, Linux.
##
## Partially supported OS: Windows (only sockets and user events),
## Solaris (files, sockets, handles and user events).
##
## TODO: ``/dev/poll``, ``event ports`` and filesystem events.

import os

const hasThreadSupport = compileOption("threads") and defined(threadsafe)

const supportedPlatform = defined(macosx) or defined(freebsd) or
                          defined(netbsd) or defined(openbsd) or
                          defined(linux)

const bsdPlatform = defined(macosx) or defined(freebsd) or
                    defined(netbsd) or defined(openbsd)

when defined(linux):
  import posix, times
elif bsdPlatform:
  import posix, kqueue, times
elif defined(windows):
  import winlean
else:
  import posix

when defined(nimdoc):
  type
    Selector*[T] = ref object
      ## An object which holds descriptors to be checked for read/write status

    Event* {.pure.} = enum
      ## An enum which hold event types
      Read,    ## Descriptor is available for read
      Write,   ## Descriptor is available for write
      Timer,   ## Timer descriptor is completed
      Signal,  ## Signal is raised
      Process, ## Process is finished
      Vnode,   ## Currently not supported
      User,    ## User event is raised
      Error    ## Error happens while waiting, for descriptor

    ReadyKey*[T] = object
      ## An object which holds result for descriptor
      fd* : int ## file/socket descriptor
      events*: set[Event] ## set of events
      data*: T ## application-defined data

    SelectEvent* = object
      ## An object which holds user defined event

  proc newSelector*[T](): Selector[T] =
    ## Creates a new selector

  proc close*[T](s: Selector[T]) =
    ## Closes selector

  proc registerHandle*[T](s: Selector[T], fd: SocketHandle, events: set[Event],
                          data: T) =
    ## Registers file/socket descriptor ``fd`` to selector ``s``
    ## with events set in ``events``. The ``data`` is application-defined
    ## data, which to be passed when event happens.

  proc updateHandle*[T](s: Selector[T], fd: SocketHandle, events: set[Event]) =
    ## Update file/socket descriptor ``fd``, registered in selector
    ## ``s`` with new events set ``event``.

  proc registerTimer*[T](s: Selector[T], timeout: int, oneshot: bool,
                         data: T): int {.discardable.} =
    ## Registers timer notification with ``timeout`` in milliseconds
    ## to selector ``s``.
    ## If ``oneshot`` is ``true`` timer will be notified only once.
    ## Set ``oneshot`` to ``false`` if your want periodic notifications.
    ## The ``data`` is application-defined data, which to be passed, when
    ## time limit expired.

  proc registerSignal*[T](s: Selector[T], signal: int,
                          data: T): int {.discardable.} =
    ## Registers Unix signal notification with ``signal`` to selector
    ## ``s``. The ``data`` is application-defined data, which to be
    ## passed, when signal raises.
    ##
    ## This function is not supported for ``Windows``.

  proc registerProcess*[T](s: Selector[T], pid: int,
                           data: T): int {.discardable.} =
    ## Registers process id (pid) notification when process has
    ## exited to selector ``s``.
    ## The ``data`` is application-defined data, which to be passed, when
    ## process with ``pid`` has exited.

  proc registerEvent*[T](s: Selector[T], ev: SelectEvent, data: T) =
    ## Registers selector event ``ev`` to selector ``s``.
    ## ``data`` application-defined data, which to be passed, when
    ## ``ev`` happens.

  proc newEvent*(): SelectEvent =
    ## Creates new event ``SelectEvent``.

  proc setEvent*(ev: SelectEvent) =
    ## Trigger event ``ev``.

  proc close*(ev: SelectEvent) =
    ## Closes selector event ``ev``.

  proc unregister*[T](s: Selector[T], ev: SelectEvent) =
    ## Unregisters event ``ev`` from selector ``s``.

  proc unregister*[T](s: Selector[T], fd: int|SocketHandle|cint) =
    ## Unregisters file/socket descriptor ``fd`` from selector ``s``.

  proc flush*[T](s: Selector[T]) =
    ## Flushes all changes was made to kernel pool/queue.
    ## This function is usefull only for BSD and MacOS, because
    ## kqueue supports bulk changes to be made.
    ## On Linux/Windows and other Posix compatible operation systems,
    ## ``flush`` is alias for `discard`.

  proc selectInto*[T](s: Selector[T], timeout: int,
                      results: var openarray[ReadyKey[T]]): int =
    ## Process call waiting for events registered in selector ``s``.
    ## The ``timeout`` argument specifies the minimum number of milliseconds
    ## the function will be blocked, if no events are not ready. Specifying a
    ## timeout of ``-1`` causes function to block indefinitely.
    ## All available events will be stored in ``results`` array.
    ##
    ## Function returns number of triggered events.

  proc select*[T](s: Selector[T], timeout: int): seq[ReadyKey[T]] =
    ## Process call waiting for events registered in selector ``s``.
    ## The ``timeout`` argument specifies the minimum number of milliseconds
    ## the function will be blocked, if no events are not ready. Specifying a
    ## timeout of -1 causes function to block indefinitely.
    ##
    ## Function returns sequence of triggered events.

  template isEmpty*[T](s: Selector[T]): bool =
    ## Returns ``true``, if there no registered events or descriptors
    ## in selector.

  template withData*[T](s: Selector[T], fd: SocketHandle, value,
                        body: untyped) =
    ## retrieves the application-data assigned with descriptor ``fd``
    ## to ``value``. This ``value`` can be modified in the scope of
    ## the ``withData`` call.
    ##
    ## .. code-block:: nim
    ##
    ##   s.withData(fd, value) do:
    ##     # block is executed only if ``fd`` registered in selector ``s``
    ##     value.uid = 1000
    ##

  template withData*[T](s: Selector[T], fd: SocketHandle, value,
                        body1, body2: untyped) =
    ## retrieves the application-data assigned with descriptor ``fd``
    ## to ``value``. This ``value`` can be modified in the scope of
    ## the ``withData`` call.
    ##
    ## .. code-block:: nim
    ##
    ##   s.withData(fd, value) do:
    ##     # block is executed only if ``fd`` registered in selector ``s``.
    ##     value.uid = 1000
    ##   do:
    ##     # block is executed if ``fd`` not registered in selector ``s``.
    ##     raise
    ##

else:
  when defined(macosx) or defined(freebsd):
    when defined(macosx):
      const maxDescriptors = 29 # KERN_MAXFILESPERPROC (MacOS)
    else:
      const maxDescriptors = 27 # KERN_MAXFILESPERPROC (FreeBSD)
    proc sysctl(name: ptr cint, namelen: cuint, oldp: pointer, oldplen: ptr int,
                newp: pointer, newplen: int): cint
         {.importc: "sysctl",header: """#include <sys/types.h>
                                        #include <sys/sysctl.h>"""}
  elif defined(netbsd) or defined(openbsd):
    # OpenBSD and NetBSD don't have KERN_MAXFILESPERPROC, so we are using
    # KERN_MAXFILES, because KERN_MAXFILES is always bigger,
    # than KERN_MAXFILESPERPROC
    const maxDescriptors = 7 # KERN_MAXFILES
    proc sysctl(name: ptr cint, namelen: cuint, oldp: pointer, oldplen: ptr int,
                newp: pointer, newplen: int): cint
         {.importc: "sysctl",header: """#include <sys/param.h>
                                        #include <sys/sysctl.h>"""}
  elif defined(linux) or defined(solaris):
    proc ulimit(cmd: cint): clong
         {.importc: "ulimit", header: "<ulimit.h>", varargs.}
  elif defined(windows):
    discard
  else:
    var
      RLIMIT_NOFILE {.importc: "RLIMIT_NOFILE",
                      header: "<sys/resource.h>".}: cint
    type
      rlimit {.importc: "struct rlimit",
               header: "<sys/resource.h>", pure, final.} = object
        rlim_cur: int
        rlim_max: int
    proc getrlimit(resource: cint, rlp: var rlimit): cint
        {.importc: "getrlimit",header: "<sys/resource.h>".}

  proc getMaxFds*(): int =
    when defined(macosx) or defined(freebsd) or defined(netbsd) or
         defined(openbsd):
      var count = cint(0)
      var size = sizeof(count)
      var namearr = [cint(1), cint(maxDescriptors)]

      if sysctl(addr namearr[0], 2, cast[pointer](addr count), addr size,
                nil, 0) != 0:
        raiseOsError(osLastError())
      result = count
    elif defined(linux) or defined(solaris):
      result = int(ulimit(4, 0))
    elif defined(windows):
      result = FD_SETSIZE
    else:
      var a = rlimit()
      if getrlimit(RLIMIT_NOFILE, a) != 0:
        raiseOsError(osLastError())
      result = a.rlim_max

  when hasThreadSupport:
    import locks

  type
    Event* {.pure.} = enum
      Read, Write, Timer, Signal, Process, Vnode, User, Error,
      flagHandle, flagTimer, flagSignal, flagProcess, flagVnode, flagUser,
      flagOneshot

    ReadyKey*[T] = object
      fd* : int
      events*: set[Event]
      data*: T

    SelectorKey[T] = object
      ident : int
      flags : set[Event]
      param : int
      key : ReadyKey[T]

  when not defined(windows):
    type
      SharedArrayHolder[T] = object
        part: array[16, T]
      SharedArray {.unchecked.}[T] = array[0..100_000_000, T]

    proc allocSharedArray[T](nsize: int): ptr SharedArray[T] =
      let holder = cast[ptr SharedArrayHolder[T]](
                     allocShared0(sizeof(T) * nsize)
                   )
      result = cast[ptr SharedArray[T]](addr(holder.part[0]))

    proc deallocSharedArray[T](sa: ptr SharedArray[T]) =
      deallocShared(cast[pointer](sa))

    template setNonBlocking(fd) =
      var x: int = fcntl(fd, F_GETFL, 0)
      if x == -1: raiseOSError(osLastError())
      else:
        var mode = x or O_NONBLOCK
        if fcntl(fd, F_SETFL, mode) == -1:
          raiseOSError(osLastError())

    template setKey(s, f1, f2, e, p, d) =
      s.fds[f1].ident = f1
      s.fds[f1].flags = e
      s.fds[f1].param = p
      s.fds[f1].key.fd = f2
      s.fds[f1].key.data = d

    template clearKey(s, f) =
      s.fds[f].ident = 0
      s.fds[f].flags = {}

    template checkMaxFd(s, fd) =
      if fd.uint >= s.maxFD:
        raise newException(ValueError, "Maximum file descriptors exceeded")

  when supportedPlatform:
    template blockSignals(newmask: var Sigset, oldmask: var Sigset) =
      when hasThreadSupport:
        if posix.pthread_sigmask(SIG_BLOCK, newmask, oldmask) == -1:
          raiseOSError(osLastError())
      else:
        if posix.sigprocmask(SIG_BLOCK, newmask, oldmask) == -1:
          raiseOSError(osLastError())

    template unblockSignals(newmask: var Sigset, oldmask: var Sigset) =
      when hasThreadSupport:
        if posix.pthread_sigmask(SIG_UNBLOCK, newmask, oldmask) == -1:
          raiseOSError(osLastError())
      else:
        if posix.sigprocmask(SIG_UNBLOCK, newmask, oldmask) == -1:
          raiseOSError(osLastError())
  #
  # BSD kqueue
  #
  # I have tried to adopt kqueue's EVFILT_USER filter for user-events, but it
  # looks not very usable, because of 2 cases:
  # 1) EVFILT_USER does not supported by OpenBSD and NetBSD
  # 2) You can't have one event, which you can use with many kqueue handles.
  # So decision was made in favor of the pipes
  #
  when bsdPlatform:
    const
      # Maximum number of cached changes
      MAX_KQUEUE_CHANGE_EVENTS = 64
      # Maximum number of events that can be returned
      MAX_KQUEUE_RESULT_EVENTS = 64

    type
      SelectorImpl[T] = object
        kqFD : cint
        maxFD : uint
        changesTable: array[MAX_KQUEUE_CHANGE_EVENTS, KEvent]
        changesCount: int
        fds: ptr SharedArray[SelectorKey[T]]
        count: int
        when hasThreadSupport:
          changesLock: Lock
      Selector*[T] = ptr SelectorImpl[T]

    type
      SelectEventImpl = object
        rfd: cint
        wfd: cint
    # SelectEvent is declared as `ptr` to be placed in `shared memory`,
    # so you can share one SelectEvent handle between threads.
    type SelectEvent* = ptr SelectEventImpl

    proc newSelector*[T](): Selector[T] =
      var maxFD = getMaxFds()
      var kqFD = kqueue()
      if kqFD < 0:
        raiseOsError(osLastError())

      result = cast[Selector[T]](allocShared0(sizeof(SelectorImpl[T])))
      result.kqFD = kqFD
      result.maxFD = maxFD.uint
      result.fds = allocSharedArray[SelectorKey[T]](maxFD)
      when hasThreadSupport:
        initLock(result.changesLock)

    proc close*[T](s: Selector[T]) =
      if posix.close(s.kqFD) != 0:
        raiseOSError(osLastError())
      when hasThreadSupport:
        deinitLock(s.changesLock)
      deallocSharedArray(s.fds)
      deallocShared(cast[pointer](s))

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
      var fdi = int(fd)
      s.checkMaxFd(fdi)
      doAssert(s.fds[fdi].ident == 0)
      setKey(s, fdi, fdi, {Event.flagHandle} + events, 0, data)
      if events != {}:
        if Event.Read in events:
          modifyKQueue(s, fdi.uint, EVFILT_READ, EV_ADD, 0, 0, nil)
          inc(s.count)
        if Event.Write in events:
          modifyKQueue(s, fdi.uint, EVFILT_WRITE, EV_ADD, 0, 0, nil)
          inc(s.count)

    proc updateHandle*[T](s: Selector[T], fd: SocketHandle,
                          events: set[Event]) =
      var fdi = int(fd)
      s.checkMaxFd(fdi)
      doAssert(s.fds[fdi].ident != 0)
      doAssert(Event.flagHandle in s.fds[fdi].flags)
      var ne = events + {Event.flagHandle}
      var oe = s.fds[fdi].flags
      if oe != ne:
        if (Event.Read in oe) and (Event.Read notin ne):
          modifyKQueue(s, fdi.uint, EVFILT_READ, EV_DELETE, 0, 0, nil)
          dec(s.count)
        if (Event.Write in oe) and (Event.Write notin ne):
           modifyKQueue(s, fdi.uint, EVFILT_WRITE, EV_DELETE, 0, 0, nil)
           dec(s.count)
        if (Event.Read notin oe) and (Event.Read in ne):
           modifyKQueue(s, fdi.uint, EVFILT_READ, EV_ADD, 0, 0, nil)
           inc(s.count)
        if (Event.Write notin oe) and (Event.Write in ne):
           modifyKQueue(s, fdi.uint, EVFILT_WRITE, EV_ADD, 0, 0, nil)
           inc(s.count)
        s.fds[fdi].flags = ne

    proc registerTimer*[T](s: Selector[T], timeout: int, oneshot: bool,
                           data: T): int {.discardable.} =
      var fdi = posix.socket(posix.AF_INET, posix.SOCK_STREAM,
                             posix.IPPROTO_TCP).int
      if fdi == -1:
        raiseOsError(osLastError())
      s.checkMaxFd(fdi)
      doAssert(s.fds[fdi].ident == 0)
      var mflags = if oneshot: {Event.flagTimer, Event.flagOneshot}
                   else: {Event.flagTimer}
      var kflags: cushort = if oneshot: EV_ONESHOT or EV_ADD
                            else: EV_ADD
      setKey(s, fdi, fdi, mflags, 0, data)
      # EVFILT_TIMER on Open/Net(BSD) has granularity of only milliseconds,
      # but MacOS and FreeBSD allow use `0` as `fflags` to use milliseconds
      # too
      modifyKQueue(s, fdi.uint, EVFILT_TIMER, kflags, 0, cint(timeout), nil)
      inc(s.count)
      result = fdi

    proc registerSignal*[T](s: Selector[T], signal: int,
                            data: T): int {.discardable.} =
      var fdi = posix.socket(posix.AF_INET, posix.SOCK_STREAM,
                             posix.IPPROTO_TCP).int
      if fdi == -1:
        raiseOsError(osLastError())

      s.checkMaxFd(fdi)
      doAssert(s.fds[fdi].ident == 0)
      setKey(s, fdi, signal, {Event.flagSignal}, signal, data)
      # block signal `signal`
      var nmask: Sigset
      var omask: Sigset
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

      s.checkMaxFd(fdi)
      doAssert(s.fds[fdi].ident == 0)
      var kflags: cushort = EV_ONESHOT or EV_ADD
      setKey(s, fdi, pid, {Event.flagProcess, Event.flagOneshot}, pid, data)
      modifyKQueue(s, pid.uint, EVFILT_PROC, kflags, NOTE_EXIT, 0,
                   cast[pointer](fdi))
      inc(s.count)
      result = fdi

    proc unregister*[T](s: Selector[T], fd: int|SocketHandle|cint) =
      var fdi = int(fd)
      if fdi.uint < s.maxFD:
        var flags = s.fds[fdi].flags
        var filter: cshort = 0
        if s.fds[fdi].ident != 0 and flags != {}:
          if Event.flagHandle in flags:
            # if events == 0, than descriptor was modified with
            # updateHandle(fd, 0), so it was already deleted from kqueue.
            if flags != {Event.flagHandle}:
              if Event.Read in flags:
                modifyKQueue(s, fdi.uint, EVFILT_READ, EV_DELETE, 0, 0, nil)
                dec(s.count)
              if Event.Write in flags:
                modifyKQueue(s, fdi.uint, EVFILT_WRITE, EV_DELETE, 0, 0, nil)
                dec(s.count)
          elif Event.flagTimer in flags:
            filter = EVFILT_TIMER
            discard posix.close(cint(s.fds[fdi].key.fd))
            modifyKQueue(s, fdi.uint, filter, EV_DELETE, 0, 0, nil)
            dec(s.count)
          elif Event.flagSignal in flags:
            filter = EVFILT_SIGNAL
            # unblocking signal
            var nmask = Sigset()
            var omask = Sigset()
            var signal = cint(s.fds[fdi].param)
            discard sigaddset(nmask, signal)
            unblockSignals(nmask, omask)
            posix.signal(signal, SIG_DFL)
            discard posix.close(cint(s.fds[fdi].key.fd))
            modifyKQueue(s, fdi.uint, filter, EV_DELETE, 0, 0, nil)
            dec(s.count)
          elif Event.flagProcess in flags:
            filter = EVFILT_PROC
            discard posix.close(cint(s.fds[fdi].key.fd))
            modifyKQueue(s, fdi.uint, filter, EV_DELETE, 0, 0, nil)
            dec(s.count)
          elif Event.flagUser in flags:
            filter = EVFILT_READ
            modifyKQueue(s, fdi.uint, filter, EV_DELETE, 0, 0, nil)
            dec(s.count)
          clearKey(s, fdi)

    proc flush*[T](s: Selector[T]) =
      s.withChangeLock():
        var tv = Timespec()
        if kevent(s.kqFD, addr(s.changesTable[0]), cint(s.changesCount),
                  nil, 0, addr tv) == -1:
          raiseOSError(osLastError())
        s.changesCount = 0

    template isEmpty*[T](s: Selector[T]): bool =
      (s.count == 0)

    proc newEvent*(): SelectEvent =
      var fds: array[2, cint]

      if posix.pipe(fds) == -1:
        raiseOSError(osLastError())

      setNonBlocking(fds[0])
      setNonBlocking(fds[1])

      result = cast[SelectEvent](allocShared0(sizeof(SelectEventImpl)))
      result.rfd = fds[0]
      result.wfd = fds[1]

    proc setEvent*(ev: SelectEvent) =
      var data: int = 1
      if posix.write(ev.wfd, addr data, sizeof(int)) != sizeof(int):
        raiseOSError(osLastError())

    proc close*(ev: SelectEvent) =
      discard posix.close(cint(ev.rfd))
      discard posix.close(cint(ev.wfd))
      deallocShared(cast[pointer](ev))

    proc registerEvent*[T](s: Selector[T], ev: SelectEvent, data: T) =
      let fdi = ev.rfd.int
      doAssert(s.fds[fdi].ident == 0)
      setKey(s, fdi, fdi, {Event.flagUser}, 0, data)
      modifyKQueue(s, fdi.uint, EVFILT_READ, EV_ADD, 0, 0, nil)
      inc(s.count)

    proc unregister*[T](s: Selector[T], ev: SelectEvent) =
      let fdi = ev.rfd.int
      var flags = s.fds[fdi].flags
      if s.fds[fdi].ident != 0 and flags != {}:
        modifyKQueue(s, fdi.uint, EVFILT_READ, EV_DELETE, 0, 0, nil)
        dec(s.count)
        clearKey(s, fdi)

    proc selectInto*[T](s: Selector[T], timeout: int,
                        results: var openarray[ReadyKey[T]]): int =
      var
        tv: Timespec
        resultsTable: array[MAX_KQUEUE_RESULT_EVENTS, KEvent]
        ptv: ptr Timespec = addr tv

      if timeout != -1:
        if timeout >= 1000:
          tv.tv_sec = (timeout div 1_000).Time
          tv.tv_nsec = (timeout %% 1_000) * 1_000_000
        else:
          tv.tv_sec = 0.Time
          tv.tv_nsec = timeout * 1_000_000
      else:
        ptv = nil

      var maxResults = MAX_KQUEUE_RESULT_EVENTS
      if maxResults > len(results):
        maxResults = len(results)

      var count = 0
      s.withChangeLock():
        count = kevent(s.kqFD,
                       addr(s.changesTable[0]), cint(s.changesCount),
                       addr(resultsTable[0]), cint(maxResults), ptv)
        s.changesCount = 0
      if count >= 0:
        var skey: ptr SelectorKey[T]
        var i = 0
        var k = 0
        while i < count:
          var kevent = addr(resultsTable[i])
          if (kevent.flags and EV_ERROR) == 0:
            var events: set[Event] = {}
            case kevent.filter
            of EVFILT_READ:
              skey = addr(s.fds[kevent.ident.int])
              if Event.flagHandle in skey.flags:
                events = {Event.Read}
              elif Event.flagUser in skey.flags:
                var data: int = 0
                if posix.read(kevent.ident.cint, addr data,
                              sizeof(int)) != sizeof(int):
                  let err = osLastError()
                  if err == OSErrorCode(EAGAIN):
                    # someone already consumed event data
                    inc(i)
                    continue
                  else:
                    raiseOSError(osLastError())
                  events = {Event.User}
              else:
                events = {Event.Read}
            of EVFILT_WRITE:
              skey = addr(s.fds[kevent.ident.int])
              events = {Event.Write}
            of EVFILT_TIMER:
              skey = addr(s.fds[kevent.ident.int])
              if Event.flagOneshot in skey.flags:
                if posix.close(skey.ident.cint) == -1:
                  raiseOSError(osLastError())
                clearKey(s, skey.ident)
                # no need to modify kqueue, because EV_ONESHOT is already made
                # this for us
                dec(s.count)
              events = {Event.Timer}
            of EVFILT_VNODE:
              skey = addr(s.fds[kevent.ident.int])
              events = {Event.Vnode}
            of EVFILT_SIGNAL:
              skey = addr(s.fds[cast[int](kevent.udata)])
              events = {Event.Signal}
            of EVFILT_PROC:
              skey = addr(s.fds[cast[int](kevent.udata)])
              if posix.close(skey.ident.cint) == -1:
                raiseOSError(osLastError())
              clearKey(s, skey.ident)
              # no need to modify kqueue, because EV_ONESHOT is already made
              # this for us
              dec(s.count)
              events = {Event.Process}
            else:
              raise newException(ValueError,
                                 "Unsupported kqueue filter in queue")

            if (kevent.flags and EV_EOF) != 0:
              events = events + {Event.Error}
            results[k].fd = skey.key.fd
            results[k].events = events
            results[k].data = skey.key.data
            inc(k)
          inc(i)
        result = k
      else:
        result = 0
        let err = osLastError()
        if cint(err) != EINTR:
          raiseOSError(err)

    proc select*[T](s: Selector[T], timeout: int): seq[ReadyKey[T]] =
      result = newSeq[ReadyKey[T]](MAX_KQUEUE_RESULT_EVENTS)
      var count = selectInto(s, timeout, result)
      result.setLen(count)

  #
  # Linux epoll
  #

  elif defined(linux):
    const
      # Maximum number of events that can be returned
      MAX_EPOLL_RESULT_EVENTS = 64
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
      epoll_data {.importc: "union epoll_data",
                    header: "<sys/epoll.h>",
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
    const
      EPOLLIN      = 0x00000001
      EPOLLOUT     = 0x00000004
      EPOLLERR     = 0x00000008
      EPOLLHUP     = 0x00000010
      EPOLLRDHUP   = 0x00002000
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
    proc signalfd(fd: cint, mask: var Sigset, flags: cint): cint
         {.cdecl, importc: "signalfd", header: "<sys/signalfd.h>".}
    proc eventfd(count: cuint, flags: cint): cint
         {.cdecl, importc: "eventfd", header: "<sys/eventfd.h>".}

    type
      SelectorImpl[T] = object
        epollFD : cint
        maxFD : uint
        fds: ptr SharedArray[SelectorKey[T]]
        count: int

      Selector*[T] = ptr SelectorImpl[T]

      SelectEventImpl = object
        efd: cint

      SelectEvent* = ptr SelectEventImpl

    proc newSelector*[T](): Selector[T] =
      var maxFD = getMaxFds()
      var epollFD = epoll_create(MAX_EPOLL_RESULT_EVENTS)
      if epollFD < 0:
        raiseOsError(osLastError())

      result = cast[Selector[T]](allocShared0(sizeof(SelectorImpl[T])))
      result.epollFD = epollFD
      result.maxFD = maxFD.uint
      result.fds = allocSharedArray[SelectorKey[T]](maxFD)

    proc close*[T](s: Selector[T]) =
      if posix.close(s.epollFD) != 0:
        raiseOSError(osLastError())
      deallocSharedArray(s.fds)
      deallocShared(cast[pointer](s))

    proc registerHandle*[T](s: Selector[T], fd: SocketHandle,
                            events: set[Event], data: T) =
      var fdi = int(fd)
      s.checkMaxFd(fdi)
      doAssert(s.fds[fdi].ident == 0)
      setKey(s, fdi, fdi, events + {Event.flagHandle}, 0, data)
      if events != {}:
        var epv: epoll_event
        epv.events = EPOLLRDHUP
        epv.data.u64 = fdi.uint
        if Event.Read in events:
          epv.events = epv.events or EPOLLIN
        if Event.Write in events:
          epv.events = epv.events or EPOLLOUT
        if epoll_ctl(s.epollFD, EPOLL_CTL_ADD, fdi.cint, addr epv) == -1:
          raiseOSError(osLastError())
        inc(s.count)

    proc updateHandle*[T](s: Selector[T], fd: SocketHandle,
                          events: set[Event]) =
      var fdi = int(fd)
      s.checkMaxFd(fdi)
      var oe = s.fds[fdi].flags
      doAssert(s.fds[fdi].ident != 0)
      doAssert(Event.flagHandle in oe)
      var ne = events + {Event.flagHandle}
      if oe != ne:
        var epv: epoll_event
        epv.data.u64 = fdi.uint
        epv.events = EPOLLRDHUP

        if Event.Read in events:
          epv.events = epv.events or EPOLLIN
        if Event.Write in events:
          epv.events = epv.events or EPOLLOUT

        if oe == {Event.flagHandle}:
          if ne != {Event.flagHandle}:
            if epoll_ctl(s.epollFD, EPOLL_CTL_ADD, fdi.cint,
                         addr epv) == -1:
              raiseOSError(osLastError())
            inc(s.count)
        else:
          if ne != {Event.flagHandle}:
            if epoll_ctl(s.epollFD, EPOLL_CTL_MOD, fdi.cint,
                         addr epv) == -1:
              raiseOSError(osLastError())
          else:
            if epoll_ctl(s.epollFD, EPOLL_CTL_DEL, fdi.cint,
                         addr epv) == -1:
              raiseOSError(osLastError())
            dec(s.count)
        s.fds[fdi].flags = ne

    proc unregister*[T](s: Selector[T], fd: int|SocketHandle|cint) =
      var epv: epoll_event
      var fdi = int(fd)
      if fdi.uint < s.maxFD:
        var flags = s.fds[fdi].flags
        if s.fds[fdi].ident != 0 and flags != {}:
          if Event.flagHandle in flags:
            # if events == {flagHandle}, then descriptor was already
            # unregistered from epoll with updateHandle() call.
            # This check is done to omit EBADF error.
            if flags != {Event.flagHandle}:
              if epoll_ctl(s.epollFD, EPOLL_CTL_DEL, fdi.cint,
                           addr epv) == -1:
                raiseOSError(osLastError())
              dec(s.count)
          elif Event.flagTimer in flags:
            if epoll_ctl(s.epollFD, EPOLL_CTL_DEL, fdi.cint, addr epv) == -1:
              raiseOSError(osLastError())
            discard posix.close(fdi.cint)
            dec(s.count)
          elif Event.flagSignal in flags:
            if epoll_ctl(s.epollFD, EPOLL_CTL_DEL, fdi.cint, addr epv) == -1:
              raiseOSError(osLastError())
            var nmask: Sigset
            var omask: Sigset
            discard sigemptyset(nmask)
            discard sigemptyset(omask)
            discard sigaddset(nmask, cint(s.fds[fdi].param))
            unblockSignals(nmask, omask)
            discard posix.close(fdi.cint)
            dec(s.count)
          elif Event.flagProcess in flags:
            if epoll_ctl(s.epollFD, EPOLL_CTL_DEL, fdi.cint, addr epv) == -1:
              raiseOSError(osLastError())
            var nmask: Sigset
            var omask: Sigset
            discard sigemptyset(nmask)
            discard sigemptyset(omask)
            discard sigaddset(nmask, SIGCHLD)
            unblockSignals(nmask, omask)
            discard posix.close(fdi.cint)
            dec(s.count)
          clearKey(s, fdi)

    proc unregister*[T](s: Selector[T], ev: SelectEvent) =
      let fdi = int(ev.efd)
      if fdi.uint < s.maxFD:
        if s.fds[fdi].ident != 0 and (Event.flagUser in s.fds[fdi].flags):
          clearKey(s, fdi)
          var epv: epoll_event
          if epoll_ctl(s.epollFD, EPOLL_CTL_DEL, fdi.cint, addr epv) == -1:
            raiseOSError(osLastError())
          dec(s.count)

    proc registerTimer*[T](s: Selector[T], timeout: int, oneshot: bool,
                           data: T): int {.discardable.} =
      var
        new_ts: Itimerspec
        old_ts: Itimerspec
      var fdi = timerfd_create(CLOCK_MONOTONIC, 0)
      if fdi == -1:
        raiseOSError(osLastError())
      s.checkMaxFd(fdi)
      doAssert(s.fds[fdi].ident == 0)
      var flags = {Event.flagTimer}
      var epv: epoll_event
      epv.data.u64 = fdi.uint
      epv.events = EPOLLIN or EPOLLRDHUP
      setNonBlocking(fdi.cint)
      if oneshot:
        new_ts.it_interval.tv_sec = 0.Time
        new_ts.it_interval.tv_nsec = 0
        new_ts.it_value.tv_sec = (timeout div 1_000).Time
        new_ts.it_value.tv_nsec = (timeout %% 1_000) * 1_000_000
        flags = flags + {Event.flagOneshot}
        epv.events = epv.events or EPOLLONESHOT
      else:
        new_ts.it_interval.tv_sec = (timeout div 1000).Time
        new_ts.it_interval.tv_nsec = (timeout %% 1_000) * 1_000_000
        new_ts.it_value.tv_sec = new_ts.it_interval.tv_sec
        new_ts.it_value.tv_nsec = new_ts.it_interval.tv_nsec
      if timerfd_settime(fdi.cint, cint(0), new_ts, old_ts) == -1:
        raiseOSError(osLastError())
      if epoll_ctl(s.epollFD, EPOLL_CTL_ADD, fdi.cint, addr epv) == -1:
        raiseOSError(osLastError())
      setKey(s, fdi, fdi, flags, 0, data)
      inc(s.count)
      result = fdi

    proc registerSignal*[T](s: Selector[T], signal: int,
                            data: T): int {.discardable.} =
      var
        nmask: Sigset
        omask: Sigset

      discard sigemptyset(nmask)
      discard sigemptyset(omask)
      discard sigaddset(nmask, cint(signal))
      blockSignals(nmask, omask)

      var fdi = signalfd(-1, nmask, 0).int
      if fdi == -1:
        raiseOSError(osLastError())

      s.checkMaxFd(fdi)
      doAssert(s.fds[fdi].ident == 0)
      setNonBlocking(fdi.cint)

      var epv: epoll_event
      epv.data.u64 = fdi.uint
      epv.events = EPOLLIN or EPOLLRDHUP
      if epoll_ctl(s.epollFD, EPOLL_CTL_ADD, fdi.cint, addr epv) == -1:
        raiseOSError(osLastError())
      setKey(s, fdi, signal, {Event.flagSignal}, signal, data)
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

      var fdi = signalfd(-1, nmask, 0).int
      if fdi == -1:
        raiseOSError(osLastError())

      s.checkMaxFd(fdi)
      doAssert(s.fds[fdi].ident == 0)
      setNonBlocking(fdi.cint)

      var epv: epoll_event
      epv.data.u64 = fdi.uint
      epv.events = EPOLLIN or EPOLLRDHUP
      if epoll_ctl(s.epollFD, EPOLL_CTL_ADD, fdi.cint, addr epv) == -1:
        raiseOSError(osLastError())
      setKey(s, fdi, pid, {Event.flagProcess}, pid, data)
      inc(s.count)
      result = fdi

    proc flush*[T](s: Selector[T]) =
      discard

    template isEmpty*[T](s: Selector[T]): bool =
      (s.count == 0)

    proc registerEvent*[T](s: Selector[T], ev: SelectEvent, data: T) =
      let fdi = int(ev.efd)
      doAssert(s.fds[fdi].ident == 0)
      setKey(s, fdi, fdi, {Event.flagUser}, 0, data)
      var epv = epoll_event(events: EPOLLIN or EPOLLRDHUP)
      epv.data.u64 = ev.efd.uint
      if epoll_ctl(s.epollFD, EPOLL_CTL_ADD, ev.efd, addr epv) == -1:
        raiseOSError(osLastError())
      inc(s.count)

    proc setEvent*(ev: SelectEvent) =
      var data : uint64 = 1
      if posix.write(ev.efd, addr data, sizeof(uint64)) == -1:
        raiseOSError(osLastError())

    proc close*(ev: SelectEvent) =
      discard posix.close(ev.efd)
      deallocShared(cast[pointer](ev))

    proc newEvent*(): SelectEvent =
      var fdi = eventfd(0, 0)
      if fdi == -1:
        raiseOSError(osLastError())
      setNonBlocking(fdi)
      result = cast[SelectEvent](allocShared0(sizeof(SelectEventImpl)))
      result.efd = cint(fdi)

    proc selectInto*[T](s: Selector[T], timeout: int,
                     results: var openarray[ReadyKey[T]]): int =
      var
        resultsTable: array[MAX_EPOLL_RESULT_EVENTS, epoll_event]

      var maxResults = MAX_EPOLL_RESULT_EVENTS
      if maxResults > len(results):
        maxResults = len(results)

      var count = epoll_wait(s.epollFD, addr(resultsTable[0]), maxResults.cint,
                             timeout.cint)
      if count > 0:
        var i = 0
        var k = 0
        while i < count:
          var events: set[Event] = {}
          let fdi = int(resultsTable[i].data.u64)
          var skey = addr(s.fds[fdi])
          let pevents = resultsTable[i].events
          var flags = s.fds[fdi].flags

          if skey.ident != 0 and flags != {}:
            block processItem:
              if (pevents and EPOLLERR) != 0 or (pevents and EPOLLHUP) != 0:
                events = events + {Event.Error}
              if (pevents and EPOLLOUT) != 0:
                events = events + {Event.Write}
              if (pevents and EPOLLIN) != 0:
                if Event.flagHandle in flags:
                  events = events + {Event.Read}
                elif Event.flagTimer in flags:
                  var data: uint64 = 0
                  if posix.read(fdi.cint, addr data,
                                sizeof(uint64)) != sizeof(uint64):
                    raiseOSError(osLastError())
                  events = events + {Event.Timer}
                elif Event.flagSignal in flags:
                  var data: SignalFdInfo
                  if posix.read(fdi.cint, addr data,
                                sizeof(SignalFdInfo)) != sizeof(SignalFdInfo):
                    raiseOsError(osLastError())
                  events = events + {Event.Signal}
                elif Event.flagProcess in flags:
                  var data: SignalFdInfo
                  if posix.read(fdi.cint, addr data,
                                sizeof(SignalFdInfo)) != sizeof(SignalFdInfo):
                    raiseOsError(osLastError())
                  if cast[int](data.ssi_pid) == skey.param:
                    events = events + {Event.Process}
                    # we want to free resources for this event
                    flags = flags + {Event.flagOneshot}
                  else:
                    break processItem
                elif Event.flagUser in flags:
                  var data: uint = 0
                  if posix.read(fdi.cint, addr data,
                                sizeof(uint)) != sizeof(uint):
                    let err = osLastError()
                    if err == OSErrorCode(EAGAIN):
                      # someone already consumed event data
                      inc(i)
                      continue
                    else:
                      raiseOSError(err)
                  events = events + {Event.User}
                else:
                  raise newException(ValueError,
                                     "Unsupported epoll event in queue")
              results[k].fd = skey.key.fd
              results[k].events = events
              results[k].data = skey.key.data

              if Event.flagOneshot in flags:
                var epv: epoll_event
                try:
                  if epoll_ctl(s.epollFD, EPOLL_CTL_DEL, fdi.cint,
                               addr epv) == -1:
                    raiseOSError(osLastError())
                finally:
                  discard posix.close(fdi.cint)
                  s.fds[fdi].ident = 0
                  s.fds[fdi].flags = {}
                  dec(s.count)
              inc(k)
          inc(i)
        result = k
      elif count == 0:
        discard
      else:
        result = 0
        let err = osLastError()
        if cint(err) != EINTR:
          raiseOSError(err)

    proc select*[T](s: Selector[T], timeout: int): seq[ReadyKey[T]] =
      result = newSeq[ReadyKey[T]](MAX_EPOLL_RESULT_EVENTS)
      var count = selectInto(s, timeout, result)
      result.setLen(count)

  #
  # Windows select
  #

  elif defined(windows):
    const FD_SETSIZE = 64

    import hashes, nativesockets

    when hasThreadSupport:
      import sharedtables
    else:
      import tables

    proc hash*(x: SocketHandle): Hash {.borrow.}
    proc `$`*(x: SocketHandle): string {.borrow.}

    proc WSAFDIsSet(s: SocketHandle, fdSet: var TFdSet): bool {.
      stdcall, importc: "__WSAFDIsSet", dynlib: "ws2_32.dll", noSideEffect.}

    template iFD_ISSET(s: SocketHandle, fdSet: var TFdSet): bool =
      if WSAFDIsSet(s, fdSet): true else: false

    template iFD_SET(s: SocketHandle, fdSet: var TFdSet) =
      block:
        var i = 0
        while i < fdSet.fd_count:
          if fdSet.fd_array[i] == s:
            break
          inc(i)
        if i == fdSet.fd_count:
          if fdSet.fd_count < ioselectors.FD_SETSIZE:
            fdSet.fd_array[i] = s
            inc(fdSet.fd_count)

    template iFD_CLR(s: SocketHandle, fdSet: var TFdSet) =
      block:
        var i = 0
        while i < fdSet.fd_count:
          if fdSet.fd_array[i] == s:
            if i == fdSet.fd_count - 1:
              fdSet.fd_array[i] = 0.SocketHandle
            else:
              while i < (fdSet.fd_count - 1):
                fdSet.fd_array[i] = fdSet.fd_array[i + 1]
                inc(i)
            dec(fdSet.fd_count)
            break
          inc(i)

    template iFD_ZERO(fdSet: var TFdSet) =
      fdSet.fd_count = 0

    when hasThreadSupport:
      type
        SelectorImpl[T] = object
          rSet: TFdSet
          wSet: TFdSet
          eSet: TFdSet
          maxFD: uint
          fds: SharedTable[SocketHandle, SelectorKey[T]]
          count: int
          lock: Lock
    else:
      type
        SelectorImpl[T] = object
          rSet: TFdSet
          wSet: TFdSet
          eSet: TFdSet
          maxFD: uint
          fds: Table[SocketHandle, SelectorKey[T]]
          count: int

    when hasThreadSupport:
      type Selector*[T] = ptr SelectorImpl[T]
    else:
      type Selector*[T] = ref SelectorImpl[T]

    type
      SelectEventImpl = object
        rsock: SocketHandle
        wsock: SocketHandle

    type SelectEvent* = ptr SelectEventImpl

    when hasThreadSupport:
      template withSelectLock[T](s: Selector[T], body: untyped) =
        acquire(s.lock)
        {.locks: [s.lock].}:
          try:
            body
          finally:
            release(s.lock)
    else:
      template withSelectLock[T](s: Selector[T], body: untyped) =
        body

    proc newSelector*[T](): Selector[T] =
      var maxFD = FD_SETSIZE
      when hasThreadSupport:
        result = cast[Selector[T]](allocShared0(sizeof(SelectorImpl[T])))
        result.maxFD = maxFD.uint
        result.fds = initSharedTable[SocketHandle, SelectorKey[T]]()
        initLock result.lock
      else:
        result = Selector[T](maxFD: FD_SETSIZE)
        result.maxFD = maxFD.uint
        result.fds = initTable[SocketHandle, SelectorKey[T]]()

      iFD_ZERO(result.rSet)
      iFD_ZERO(result.wSet)
      iFD_ZERO(result.eSet)

    proc close*(s: Selector) =
      when hasThreadSupport:
        deinitSharedTable(s.fds)
        deallocShared(cast[pointer](s))

    template isEmpty*[T](s: Selector[T]): bool =
      (s.count == 0)

    template selectAdd[T](s: Selector[T], fd: SocketHandle,
                          events: set[Event]) =
      mixin withSelectLock
      s.withSelectLock():
        if Event.Read in events:
          if s.rSet.fd_count == FD_SETSIZE:
            raise newException(ValueError, "Maximum numbers of fds exceeded")
          iFD_SET(fd, s.rSet)
          inc(s.count)
        if Event.Write in events:
          if s.wSet.fd_count == FD_SETSIZE:
            raise newException(ValueError, "Maximum numbers of fds exceeded")
          iFD_SET(fd, s.wSet)
          iFD_SET(fd, s.eSet)
          inc(s.count)

    proc registerHandle*[T](s: Selector[T], fd: SocketHandle,
                            events: set[Event], data: T) =
      var fdi = int(fd)
      var flags = {Event.flagHandle} + events
      var nkey = SelectorKey[T](ident: fdi, flags: flags)
      nkey.key.fd = fdi
      nkey.key.data = data

      if s.fds.hasKeyOrPut(fd, nkey):
        raise newException(ValueError, "Re-use of non closed descriptor")
      selectAdd(s, fd, flags)

    proc updateHandle*[T](s: Selector[T], fd: SocketHandle,
                          events: set[Event]) =
      s.withSelectLock():
        withValue(s.fds, fd, skey) do:
          if Event.flagHandle in skey.flags:
            var oe = skey.flags
            var ne = events + {Event.flagHandle}
            if oe != ne:
              if (Event.Read in oe) and (Event.Read notin ne):
                iFD_CLR(fd, s.rSet)
                dec(s.count)
              if (Event.Write in oe) and (Event.Write notin ne):
                iFD_CLR(fd, s.wSet)
                iFD_CLR(fd, s.eSet)
                dec(s.count)
              if (Event.Read notin oe) and (Event.Read in ne):
                iFD_SET(fd, s.rSet)
                inc(s.count)
              if (Event.Write notin oe) and (Event.Write in ne):
                iFD_SET(fd, s.wSet)
                iFD_SET(fd, s.eSet)
                inc(s.count)
              skey.flags = ne
          else:
            raise newException(ValueError,
                               "Could not update non-handle descriptor")
        do:
          raise newException(ValueError,
                             "Descriptor is not registered in queue")

    proc registerTimer*[T](s: Selector, timeout: int, oneshot: bool,
                           data: T): int {.discardable.} =
      raise newException(ValueError, "Not implemented")

    proc registerSignal*[T](s: Selector, signal: int,
                            data: T): int {.discardable.} =
      raise newException(ValueError, "Not implemented")

    proc registerProcess*[T](s: Selector, pid: int,
                             data: T): int {.discardable.} =
      raise newException(ValueError, "Not implemented")

    proc flush*[T](s: Selector[T]) = discard

    proc unregister*[T](s: Selector[T], ev: SelectEvent) =
      let fd = ev.rsock
      s.withSelectLock():
        iFD_CLR(fd, s.rSet)
        dec(s.count)
        s.fds.del(fd)


    proc unregister*[T](s: Selector[T], fd: SocketHandle) =
      s.withSelectLock():
        s.fds.withValue(fd, skey) do:
          if Event.Read in skey.flags:
            iFD_CLR(fd, s.rSet)
            dec(s.count)
          if Event.Write in skey.flags:
            iFD_CLR(fd, s.wSet)
            iFD_CLR(fd, s.eSet)
            dec(s.count)
        s.fds.del(fd)

    proc registerEvent*[T](s: Selector[T], ev: SelectEvent, data: T) =
      var flags = {Event.flagUser, Event.Read}
      var nkey = SelectorKey[T](ident: ev.rsock.int, flags: flags)
      nkey.key.fd = ev.rsock.int
      nkey.key.data = data
      if s.fds.hasKeyOrPut(ev.rsock, nkey):
        raise newException(ValueError, "Re-use of non closed descriptor")
      selectAdd(s, ev.rsock, flags)

    proc newEvent*(): SelectEvent =
      var ssock = newNativeSocket()
      var wsock = newNativeSocket()
      var rsock: SocketHandle = INVALID_SOCKET
      var saddr = Sockaddr_in()
      try:
        saddr.sin_family = winlean.AF_INET
        saddr.sin_port = 0
        saddr.sin_addr.s_addr = INADDR_ANY
        if bindAddr(ssock, cast[ptr SockAddr](addr(saddr)),
                    sizeof(saddr).SockLen) < 0'i32:
          raiseOSError(osLastError())

        if winlean.listen(ssock, 1) == -1:
          raiseOSError(osLastError())

        var namelen = sizeof(saddr).SockLen
        if getsockname(ssock, cast[ptr SockAddr](addr(saddr)),
                       addr(namelen)) == -1'i32:
          raiseOSError(osLastError())

        saddr.sin_addr.s_addr = 0x0100007F
        if winlean.connect(wsock, cast[ptr SockAddr](addr(saddr)),
                           sizeof(saddr).SockLen) == -1:
          raiseOSError(osLastError())
        namelen = sizeof(saddr).SockLen
        rsock = winlean.accept(ssock, cast[ptr SockAddr](addr(saddr)),
                               cast[ptr SockLen](addr(namelen)))
        if rsock == SocketHandle(-1):
          raiseOSError(osLastError())

        if winlean.closesocket(ssock) == -1:
          raiseOSError(osLastError())

        var mode = clong(1)
        if ioctlsocket(rsock, FIONBIO, addr(mode)) == -1:
          raiseOSError(osLastError())
        mode = clong(1)
        if ioctlsocket(wsock, FIONBIO, addr(mode)) == -1:
          raiseOSError(osLastError())

        result = cast[SelectEvent](allocShared0(sizeof(SelectEventImpl)))
        result.rsock = rsock
        result.wsock = wsock
      except:
        discard winlean.closesocket(ssock)
        discard winlean.closesocket(wsock)
        if rsock != INVALID_SOCKET:
          discard winlean.closesocket(rsock)

    proc setEvent*(ev: SelectEvent) =
      var data: int = 1
      if winlean.send(ev.wsock, cast[pointer](addr data),
                      cint(sizeof(int)), 0) != sizeof(int):
        raiseOSError(osLastError())

    proc close*(ev: SelectEvent) =
      discard winlean.closesocket(ev.rsock)
      discard winlean.closesocket(ev.wsock)
      deallocShared(cast[pointer](ev))

    proc selectInto*[T](s: Selector[T], timeout: int,
                     results: var openarray[ReadyKey[T]]): int =
      var tv = Timeval()
      var ptv = addr tv
      var rset, wset, eset: TFdSet

      if timeout != -1:
        tv.tv_sec = timeout.int32 div 1_000
        tv.tv_usec = (timeout.int32 %% 1_000) * 1_000
      else:
        ptv = nil

      s.withSelectLock():
        rset = s.rSet
        wset = s.wSet
        eset = s.eSet

      var count = select(cint(0), addr(rset), addr(wset),
                         addr(eset), ptv).int
      if count > 0:
        var rindex = 0
        var i = 0
        while i < rset.fd_count:
          let fd = rset.fd_array[i]
          if iFD_ISSET(fd, rset):
            var events = {Event.Read}
            if iFD_ISSET(fd, eset): events = events + {Event.Error}
            if iFD_ISSET(fd, wset): events = events + {Event.Write}
            s.fds.withValue(fd, skey) do:
              if Event.flagHandle in skey.flags:
                skey.key.events = events
              elif Event.flagUser in skey.flags:
                var data: int = 0
                if winlean.recv(fd, cast[pointer](addr(data)),
                                sizeof(int).cint, 0) != sizeof(int):
                  let err = osLastError()
                  if err != OSErrorCode(WSAEWOULDBLOCK):
                    raiseOSError(err)
                  else:
                    # someone already consumed event data
                    inc(i)
                    continue
                skey.key.events = {Event.User}
              results[rindex].fd = skey.key.fd
              results[rindex].data = skey.key.data
              results[rindex].events = skey.key.events
              inc(rindex)
          inc(i)

        i = 0
        while i < wset.fd_count:
          let fd = wset.fd_array[i]
          if iFD_ISSET(fd, wset):
            var events = {Event.Write}
            if not iFD_ISSET(fd, rset):
              if iFD_ISSET(fd, eset): events = events + {Event.Error}
              s.fds.withValue(fd, skey) do:
                skey.key.events = events
                results[rindex].fd = skey.key.fd
                results[rindex].data = skey.key.data
                results[rindex].events = skey.key.events
                inc(rindex)
          inc(i)
        count = rindex
      elif count == 0:
        discard
      else:
        raiseOSError(osLastError())
      result = count

    proc select*[T](s: Selector[T], timeout: int): seq[ReadyKey[T]] =
      result = newSeq[ReadyKey[T]](FD_SETSIZE)
      var count = selectInto(s, timeout, result)
      result.setLen(count)

  #
  # Posix poll
  #

  else:
    # Maximum number of events that can be returned
    const MAX_POLL_RESULT_EVENTS = 64

    type
      SelectorImpl[T] = object
        maxFD : uint
        pollcnt: int
        fds: ptr SharedArray[SelectorKey[T]]
        pollfds: ptr SharedArray[TPollFd]
        count: int
        when hasThreadSupport:
          lock: Lock

      Selector*[T] = ptr SelectorImpl[T]

      SelectEventImpl = object
        rfd: cint
        wfd: cint

      SelectEvent* = ptr SelectEventImpl

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
      var maxFD = getMaxFds()

      result = cast[Selector[T]](allocShared0(sizeof(SelectorImpl[T])))
      result.maxFD = maxFD.uint
      result.fds = allocSharedArray[SelectorKey[T]](maxFD)
      result.pollfds = allocSharedArray[TPollFd](maxFD)
      when hasThreadSupport:
        initLock(result.lock)

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
          raise newException(ValueError,
                             "Descriptor is not registered in queue")

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

    proc registerHandle*[T](s: Selector[T], fd: SocketHandle,
                            events: set[Event], data: T) =
      var fdi = int(fd)
      s.checkMaxFd(fdi)
      doAssert(s.fds[fdi].ident == 0)
      setKey(s, fdi, fdi, {Event.flagHandle} + events, 0, data)
      s.pollAdd(fdi.cint, events)

    proc updateHandle*[T](s: Selector[T], fd: SocketHandle,
                          events: set[Event]) =
      var fdi = int(fd)
      s.checkMaxFd(fdi)
      var oe = s.fds[fdi].flags
      doAssert(s.fds[fdi].ident != 0)
      doAssert(Event.flagHandle in oe)
      var ne = events + {Event.flagHandle}
      if ne != oe:
        if events != {}:
          s.pollUpdate(fd.cint, events)
        else:
          s.pollRemove(fd.cint)
        s.fds[fdi].flags = ne

    proc registerTimer*[T](s: Selector[T], timeout: int, oneshot: bool,
                           data: T): int {.discardable.} =
      raise newException(ValueError, "Not implemented")

    proc registerSignal*[T](s: Selector[T], signal: int,
                            data: T): int {.discardable.} =
      raise newException(ValueError, "Not implemented")

    proc registerProcess*[T](s: Selector[T], pid: int,
                             data: T): int {.discardable.} =
      raise newException(ValueError, "Not implemented")

    proc registerEvent*[T](s: Selector[T], ev: SelectEvent, data: T) =
      var fdi = int(ev.rfd)
      doAssert(s.fds[fdi].ident == 0)
      var events = {Event.flagUser, Event.Read}
      setKey(s, fdi, fdi, events, 0, data)
      s.pollAdd(fdi.cint, events)

    proc flush*[T](s: Selector[T]) = discard

    template isEmpty*[T](s: Selector[T]): bool =
      (s.count == 0)

    proc unregister*[T](s: Selector[T], fd: int|SocketHandle|cint) =
      var fdi = int(fd)
      if fdi.uint < s.maxFD:
        if s.fds[fdi].ident != 0 and s.fds[fdi].flags != {}:
          clearKey(s, fdi)
          s.pollRemove(fdi.cint)

    proc unregister*[T](s: Selector[T], ev: SelectEvent) =
      var fdi = int(ev.rfd)
      if fdi.uint < s.maxFD:
        if s.fds[fdi].ident != 0 and (Event.flagUser in s.fds[fdi].flags):
          clearKey(s, fdi)
          s.pollRemove(fdi.cint)

    proc newEvent*(): SelectEvent =
      var fds: array[2, cint]
      if posix.pipe(fds) == -1:
        raiseOSError(osLastError())
      setNonBlocking(fds[0])
      setNonBlocking(fds[1])
      result = cast[SelectEvent](allocShared0(sizeof(SelectEventImpl)))
      result.rfd = fds[0]
      result.wfd = fds[1]

    proc setEvent*(ev: SelectEvent) =
      var data: int = 1
      if posix.write(ev.wfd, addr data, sizeof(int)) != sizeof(int):
        raiseOSError(osLastError())

    proc close*(ev: SelectEvent) =
      discard posix.close(cint(ev.rfd))
      discard posix.close(cint(ev.wfd))
      deallocShared(cast[pointer](ev))

    proc selectInto*[T](s: Selector[T], timeout: int,
                        results: var openarray[ReadyKey[T]]): int =
      var maxResults = MAX_POLL_RESULT_EVENTS
      if maxResults > len(results):
        maxResults = len(results)

      s.withPollLock():
        var count = posix.poll(addr(s.pollfds[0]), Tnfds(s.pollcnt), timeout)
        if count > 0:
          var i = 0
          var k = 0
          var rindex = 0
          while (i < s.pollcnt) and (k < count) and (rindex < maxResults):
            let revents = s.pollfds[i].revents
            let fd = s.pollfds[i].fd
            if revents != 0:
              var events: set[Event] = {}
              if (revents and POLLIN) != 0:
                events = events + {Event.Read}
              if (revents and POLLOUT) != 0:
                events = events + {Event.Write}
              if (revents and POLLERR) != 0 or (revents and POLLHUP) != 0 or
                 (revents and POLLNVAL) != 0:
                events = events + {Event.Error}

              var skey = addr(s.fds[fd])
              if Event.flagUser in skey.flags:
                if Event.Read in events:
                  var data: int = 0
                  if posix.read(fd, addr data, sizeof(int)) != sizeof(int):
                    let err = osLastError()
                    if err != OSErrorCode(EAGAIN):
                      raiseOSError(osLastError())
                    else:
                      # someone already consumed event data
                      inc(i)
                      continue
                  events = {Event.User}

              results[rindex].fd = fd
              results[rindex].events = events
              results[rindex].data = skey.key.data
              s.pollfds[i].revents = 0
              inc(rindex)
              inc(k)
            inc(i)
          result = k
        elif count == 0:
          discard
        else:
          let err = osLastError()
          if err.cint == EINTR:
            discard
          else:
            raiseOSError(osLastError())

    proc select*[T](s: Selector[T], timeout: int): seq[ReadyKey[T]] =
      result = newSeq[ReadyKey[T]](MAX_POLL_RESULT_EVENTS)
      var count = selectInto(s, timeout, result)
      result.setLen(count)

  when not defined(windows):
    template withData*[T](s: Selector[T], fd: SocketHandle, value,
                          body: untyped) =
      var fdi = int(fd)
      if fdi.uint < s.maxFD:
        if s.fds[fdi].ident != 0:
          var value = addr(s.fds[fdi].key.data)
          body
      else:
        raise newException(ValueError, "Maximum file descriptors exceeded")

    template withData*[T](s: Selector[T], fd: SocketHandle, value, body1,
                          body2: untyped) =
      var fdi = int(fd)
      if fdi.uint < s.maxFD:
        if s.fds[fdi].ident != 0:
          var value = addr(s.fds[fdi].key.data)
          body1
        else:
          body2
      else:
        raise newException(ValueError, "Maximum file descriptors exceeded")
  else:
    template withData*(s: Selector, fd: SocketHandle, value, body: untyped) =
      s.fds.withValue(fd, skey) do:
        var value {.inject.} = addr(skey.key.data)
        body

    template withData*(s: Selector, fd: SocketHandle, value,
                       body1, body2: untyped) =
      s.fds.withValue(fd, skey) do:
        var value {.inject.} = addr(skey.key.data)
        body1
      do:
        body2
