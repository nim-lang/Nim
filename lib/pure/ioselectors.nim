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
## Supported features: files, sockets, pipes, timers, processes, signals
## and user events
##
## Fully supported OS: MacOSX, FreeBSD, OpenBSD, NetBSD, Linux
##
## Partially supported OS: Windows (only sockets and user events),
## Solaris (files, sockets, handles and user events).

import os

const hasThreadSupport = compileOption("threads")
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
    Selector* = ref object
      ## An object which holds descriptors to be checked for read/write status

    ReadyKey* = object
      ## An object which holds result for descriptor
      fd* : int ## file/socket descriptor
      events*: int ## event mask 
      data*: SelectorData ## application-defined data

    SelectEvent* = object
      ## An object which holds user defined event
  const
    EVENT_READ*       = 0x00000001 ## Descriptor is available for read
    EVENT_WRITE*      = 0x00000002 ## Descriptor is available for write
    EVENT_TIMER*      = 0x00000004 ## Timer descriptor is completed
    EVENT_SIGNAL*     = 0x00000008 ## Signal is raised
    EVENT_PROCESS*    = 0x00000010 ## Process is finished
    EVENT_VNODE*      = 0x00000020 ## Currently not supported
    EVENT_USER*       = 0x00000040 ## User event is raised
    EVENT_ERROR*      = 0x00000080 ## Error happens while waiting
                                   ## for descriptor

  proc newSelector*(): Selector =
    ## Creates a new selector

  proc close*(s: Selector) =
    ## Closes selector

  proc registerHandle*(s: Selector, fd: SocketHandle, event: int,
                       data: SelectorData) =
    ## Registers file/socket descriptor ``fd`` to selector ``s``
    ## with event mask in ``event``. ``data`` application-defined
    ## data, which to be passed when ``event`` happens.

  proc updateHandle*(s: Selector, fd: SocketHandle, event: int) =
    ## Update file/socket descriptor ``fd``, registered in selector
    ## ``s`` with new event mask ``event``.

  proc registerTimer*(s: Selector, timeout: int, oneshot: bool,
                      data: SelectorData): int {.discardable.} =
    ## Registers timer notification with ``timeout`` in milliseconds 
    ## to selector ``s``.
    ## If ``oneshot`` is ``true`` timer will be notified only once.
    ## Set ``oneshot`` to ``false`` if your want periodic notifications
    ## ``data`` application-defined data, which to be passed, when
    ## ``event`` happens
  
  proc registerSignal*(s: Selector, signal: int,
                       data: SelectorData): int {.discardable.} =
    ## Registers Unix signal notification with ``signal`` to selector
    ## ``s``.
    ## ``data`` application-defined data, which to be passed, when
    ## ``event`` happens.
    ##
    ## This function is not supported for ``Windows``.

  proc registerProcess*(s: Selector, pid: int,
                        data: SelectorData): int {.discardable.} =
    ## Registers process id (pid) notification when process has 
    ## exited to selector ``s``.
    ## ``data`` application-defined data, which to be passed, when
    ## ``event`` happens.

  proc registerEvent*(s: Selector, ev: SelectEvent, data: SelectorData) =
    ## Registers selector event ``ev`` to selector ``s``.
    ## ``data`` application-defined data, which to be passed, when
    ## ``event`` happens.    

  proc unregister*(s: Selector, fd: int|SocketHandle|cint) =
    ## Unregisters file/socket descriptor ``fd`` from selector ``s``.

  proc newEvent*(s: Selector): SelectEvent =
    ## Creates new event ``SelectEvent`` associated with selector ``s``.

  proc setEvent*(ev: SelectEvent) =
    ## Trigger event ``ev``.

  proc close*(ev: SelectEvent) =
    ## Closes selector event ``ev``

  template fd*(ev: SelectEvent): cint =
    ## Returns file descriptor associated with event ``ev``.

  proc selectInto*(s: Selector, timeout: int,
                   results: var openarray[ReadyKey]): int =
    ## Process call waiting for events registered in selector ``s``.
    ## The ``timeout`` argument specifies the minimum number of milliseconds
    ## that function will block if not events are available. Specifying a
    ## timeout of -1 causes function to block indefinitely.
    ## All available events will be stored in ``results`` array.
    ##
    ## Function returns number of triggered events.

  proc select*(s: Selector, timeout: int): seq[ReadyKey] =
    ## Process call waiting for events registered in selector ``s``.
    ## The ``timeout`` argument specifies the minimum number of milliseconds
    ## that function will block if not events are available. Specifying a
    ## timeout of -1 causes function to block indefinitely.
    ##
    ## Function returns sequence of triggered events.

  template isError*(e: int): bool =
    ## Returns ``true``, if event mask has ``EVENT_ERROR`` set.

  template isReadable*(e: int): bool =
    ## Returns ``true``, if event has ``EVENT_READ`` set.

  template isWritable*(e: int): bool =
    ## Returns ``true``, if event has ``EVENT_WRITE`` set.

  template isTimer*(e: int): bool =
    ## Returns ``true``, if event has ``EVENT_TIMER`` set.

  template isProcess*(e: int): bool =
    ## Returns ``true``, if event has ``EVENT_PROCESS`` set.

  template isSignal*(e: int): bool =
    ## Returns ``true``, if event has ``EVENT_SIGNAL`` set.

  template isUser*(e: int): bool =
    ## Returns ``true``, if event has ``EVENT_USER`` set.

  template isSupport*(e: int): bool =
    ## Returns ``true``, if one of ``EVENT_TIMER``, ``EVENT_PROCESS``,
    ## ``EVENT_SIGNAL``, ``EVENT_USER`` set.

  template withData*(s: Selector, fd: SocketHandle, value, body: untyped) =
    ## retrieves the application-data assigned to descriptor ``fd``
    ## to ``value``. This ``value`` can be modified in the scope of 
    ## the ``withData`` call.
    ##
    ## .. code-block:: nim
    ##
    ##   s.withData(fd, value) do:
    ##     # block is executed only if ``fd`` registered in selector ``s``
    ##     value.uid = 1000
    ##

  template withData*(s: Selector, fd: SocketHandle, value,
                     body1, body2: untyped) =
    ## retrieves the application-data assigned to descriptor ``fd``
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
  when not defined(windows):
    when defined(macosx):
      var
        OPEN_MAX {.importc: "OPEN_MAX", header: "<sys/resource.h>".}: cint
    var
      RLIMIT_NOFILE {.importc: "RLIMIT_NOFILE",
                      header: "<sys/resource.h>".}: cint
    type
      rlimit {.importc: "struct rlimit",
              header: "<sys/resource.h>", pure, final.} = object
        rlim_cur: int
        rlim_max: int
    proc getrlimit(resource: cint, rlp: var rlimit): cint {.importc: "getrlimit",
         header: "<sys/resource.h>"}
    proc getMaxFds*(): int =
      var a = rlimit()
      if getrlimit(RLIMIT_NOFILE, a) != 0:
        raiseOsError(osLastError())
      result = a.rlim_max
      when defined(macosx):
        if a.rlim_max > OPEN_MAX:
          result = OPEN_MAX

  when hasThreadSupport:
    import locks
    type SelectorData* = pointer
  else:
    type SelectorData* = RootRef

  type
    ReadyKeyImpl* = object
      fd* : int
      events*: int
      data*: SelectorData

    SelectorKey* = object
      ident : int
      flags : int
      param : int
      key : ReadyKeyImpl

  when hasThreadSupport:
    type ReadyKey* = ReadyKeyImpl
  else:
    type ReadyKey* = ptr ReadyKeyImpl

  const
    EVENT_READ*       = 0x00000001
    EVENT_WRITE*      = 0x00000002
    EVENT_TIMER*      = 0x00000004
    EVENT_SIGNAL*     = 0x00000008
    EVENT_PROCESS*    = 0x00000010
    EVENT_VNODE*      = 0x00000020
    EVENT_USER*       = 0x00000040
    EVENT_ERROR*      = 0x00000080
    EVENT_SUPPORT*    = EVENT_TIMER or EVENT_SIGNAL or EVENT_PROCESS or 
                        EVENT_VNODE or EVENT_USER
    EVENT_MASK*       = 0x000000FF
    
    FLAG_HANDLE       = 0x00080000
    FLAG_USER         = 0x00100000

  when not defined(windows):
    when hasThreadSupport:
      const uncheckedSize = when defined(cpu16): 10_000 else: 100_000_000
      type fdList = ptr array[0..uncheckedSize, SelectorKey]
    else:
      type fdList = seq[SelectorKey]

  when not defined(windows) and not defined(freebsd) and
       not defined(macosx):

    template setNonBlocking(fd) =
      var x: int = fcntl(fd, F_GETFL, 0)
      if x == -1: raiseOSError(osLastError())
      else:
        var mode = x or O_NONBLOCK
        if fcntl(fd, F_SETFL, mode) == -1:
          raiseOSError(osLastError())

  when supportedPlatform:
    const
      FLAG_SIGNAL     = 0x01000000
      FLAG_ONESHOT    = 0x00010000
      FLAG_TIMER      = 0x00020000
      FLAG_PROCESS    = 0x00040000

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
    
  template isError*(e: int): bool =
    ((e and EVENT_ERROR) != 0)
  template isReadable*(e: int): bool =
    ((e and EVENT_READ) != 0)
  template isWritable*(e: int): bool =
    ((e and EVENT_WRITE) != 0)
  template isTimer*(e: int): bool =
    ((e and EVENT_TIMER) != 0)
  template isProcess*(e: int): bool =
    ((e and EVENT_PROCESS) != 0)
  template isSignal*(e: int): bool =
    ((e and EVENT_SIGNAL) != 0)
  template isUser*(e: int): bool =
    ((e and EVENT_USER) != 0)
  template isSupport*(e: int): bool =
    ((e and EVENT_SUPPORT) != 0)

  #
  # BSD kqueue 
  #

  when bsdPlatform:
    const
      MAX_KQUEUE_CHANGE_EVENTS = 64
      MAX_KQUEUE_RESULT_EVENTS = 64

    type
      SelectorImpl* = object
        kqFD : cint
        maxFD : uint
        changesTable: array[MAX_KQUEUE_CHANGE_EVENTS, KEvent]
        changesCount: int
        fds: fdList
        when hasThreadSupport:
          changesLock: Lock

    when hasThreadSupport:
      type Selector* = ptr SelectorImpl
    else:
      type Selector* = ref SelectorImpl

    type
      SelectEventImpl* = object
        rfd: cint
        wfd: cint
        selector: Selector

    when hasThreadSupport:
      type SelectEvent* = ptr SelectEventImpl
    else:
      type SelectEvent* = ref SelectEventImpl

    proc newSelector*(): Selector =
      var maxFD = getMaxFds()
      var kqFD = kqueue()
      if kqFD < 0:
        raiseOsError(osLastError())
      when hasThreadSupport:
        result = cast[Selector](allocShared0(sizeof(SelectorImpl)))
        result.kqFD = kqFD
        result.maxFD = maxFD.uint
        result.fds = cast[fdList](allocShared0(maxFD * sizeof(SelectorKey)))
        initLock(result.changesLock)
      else:
        result = Selector(kqFD: kqFD, maxFD: maxFD.uint)
        result.fds = newSeq[SelectorKey](maxFD)

    proc close*(s: Selector) =
      if posix.close(s.kqFD) != 0:
        raiseOSError(osLastError())
      when hasThreadSupport:
        deinitLock(s.changesLock)
        deallocShared(cast[pointer](s.fds))
        deallocShared(cast[pointer](s))

    when hasThreadSupport:
      template withChangeLock(s: Selector, body: untyped) =
        acquire(s.changesLock)
        {.locks: [s.changesLock].}:
          try:
            body
          finally:
            release(s.changesLock)
    else:
      template withChangeLock(s, body: untyped) =
        body

    template modifyKQueue(s: Selector, nident: uint, nfilter: cshort,
                          nflags: cushort, nfflags: cuint, ndata: int,
                          nudata: pointer) =
      mixin withChangeLock
      s.withChangeLock() do:
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

    proc registerHandle*(s: Selector, fd: SocketHandle, event: int,
                         data: SelectorData) =
      var fdi = int(fd)
      if fdi.uint < s.maxFD:
        if s.fds[fdi].ident == 0:
          s.fds[fdi].ident = fdi
          s.fds[fdi].flags = FLAG_HANDLE or event
          s.fds[fdi].param = 0
          s.fds[fdi].key.fd = fdi
          s.fds[fdi].key.data = data
          if (event and EVENT_READ) != 0:
            modifyKQueue(s, fdi.uint, EVFILT_READ, EV_ADD, 0, 0, nil)
          if (event and EVENT_WRITE) != 0:
            modifyKQueue(s, fdi.uint, EVFILT_WRITE, EV_ADD, 0, 0, nil)
        else:
          raise newException(ValueError, "Re-use of non-closed descriptor")
      else:
        raise newException(ValueError, "Maximum file descriptors exceeded")

    proc updateHandle*(s: Selector, fd: SocketHandle, event: int) =
      var fdi = int(fd)
      if fdi.uint < s.maxFD:
        if s.fds[fdi].ident != 0:
          if (s.fds[fdi].flags and FLAG_HANDLE) != 0:
            var oe = s.fds[fdi].flags and EVENT_MASK
            if (oe xor event) != 0:
              if (oe and EVENT_READ) != 0 and (event and EVENT_READ) == 0:
                modifyKQueue(s, fdi.uint, EVFILT_READ, EV_DELETE, 0, 0, nil)
              if (oe and EVENT_WRITE) != 0 and (event and EVENT_WRITE) == 0:
                modifyKQueue(s, fdi.uint, EVFILT_WRITE, EV_DELETE, 0, 0, nil)
              if (oe and EVENT_READ) == 0 and (event and EVENT_READ) != 0:
                modifyKQueue(s, fdi.uint, EVFILT_READ, EV_ADD, 0, 0, nil)
              if (oe and EVENT_WRITE) == 0 and (event and EVENT_WRITE) != 0:
                modifyKQueue(s, fdi.uint, EVFILT_WRITE, EV_ADD, 0, 0, nil)
              s.fds[fdi].flags = FLAG_HANDLE or event
          else:
            raise newException(ValueError,
                               "Could not update non-handle descriptor")
        else:
          raise newException(ValueError, "Descriptor is not registered in queue")
      else:
        raise newException(ValueError, "Maximum file descriptors exceeded")

    proc registerTimer*(s: Selector, timeout: int, oneshot: bool,
                        data: SelectorData): int {.discardable.} =
      var fdi = posix.socket(posix.AF_INET, posix.SOCK_STREAM,
                             posix.IPPROTO_TCP).int
      if fdi == -1:
        raiseOsError(osLastError())
      if fdi.uint < s.maxFD:
        if s.fds[fdi].ident == 0:
          var mflags = if oneshot: FLAG_TIMER or FLAG_ONESHOT
                       else: FLAG_TIMER
          var kflags: cushort = if oneshot: EV_ONESHOT or EV_ADD
                                else: EV_ADD
          s.fds[fdi].ident = fdi
          s.fds[fdi].flags = mflags
          s.fds[fdi].key.fd = fdi
          s.fds[fdi].param = 0
          s.fds[fdi].key.data = data
          modifyKQueue(s, fdi.uint, EVFILT_TIMER, kflags, 0, cint(timeout), nil)
          result = fdi
        else:
          raise newException(ValueError, "Re-use of non-closed descriptor")
      else:
        raise newException(ValueError, "Maximum file descriptors exceeded")

    proc registerSignal*(s: Selector, signal: int,
                         data: SelectorData): int {.discardable.} =
      var fdi = posix.socket(posix.AF_INET, posix.SOCK_STREAM,
                             posix.IPPROTO_TCP).int
      if fdi == -1:
        raiseOsError(osLastError())

      if fdi.uint < s.maxFD:
        if s.fds[fdi].ident == 0:
          s.fds[fdi].ident = fdi
          s.fds[fdi].key.fd = fdi
          s.fds[fdi].key.data = data
          s.fds[fdi].param = signal
          s.fds[fdi].flags = FLAG_SIGNAL

          # block signal `signal`
          var nmask: Sigset
          var omask: Sigset

          discard sigemptyset(nmask)
          discard sigemptyset(omask)
          discard sigaddset(nmask, cint(signal))
          blockSignals(nmask, omask)
          try:
            modifyKQueue(s, signal.uint, EVFILT_SIGNAL, EV_ADD, 0, 0,
                         cast[pointer](fdi))
            result = fdi
          except:
            # on error unblocking signal `signal`
            unblockSignals(omask, nmask)
        else:
          raise newException(ValueError, "Re-use of non-closed descriptor")
      else:
        raise newException(ValueError, "Maximum file descriptors exceeded")

    proc registerProcess*(s: Selector, pid: int,
                          data: SelectorData): int {.discardable.} =
      var fdi = posix.socket(posix.AF_INET, posix.SOCK_STREAM,
                             posix.IPPROTO_TCP).int
      if fdi == -1:
        raiseOsError(osLastError())

      if fdi.uint < s.maxFD:
        if s.fds[fdi].ident == 0:
          var mflags = FLAG_PROCESS or FLAG_ONESHOT or EVENT_PROCESS
          var kflags: cushort = EV_ONESHOT or EV_ADD
          s.fds[fdi].ident = fdi
          s.fds[fdi].key.fd = fdi
          s.fds[fdi].key.data = data
          s.fds[fdi].param = pid
          s.fds[fdi].flags = mflags
          modifyKQueue(s, pid.uint, EVFILT_PROC, kflags, NOTE_EXIT, 0,
                       cast[pointer](fdi))
          result = fdi
        else:
          raise newException(ValueError, "Re-use of non-closed descriptor")
      else:
        raise newException(ValueError, "Maximum file descriptors exceeded")

    proc unregister*(s: Selector, fd: int|SocketHandle|cint) =
      var fdi = int(fd)
      if fdi.uint < s.maxFD:
        var flags = s.fds[fdi].flags
        var filter: cshort = 0
        if s.fds[fdi].ident != 0 and flags != 0:
          if (flags and FLAG_HANDLE) != 0:
            if (flags and EVENT_READ) != 0: filter = EVFILT_READ
            if (flags and EVENT_WRITE) != 0: filter = EVFILT_WRITE
            modifyKQueue(s, fdi.uint, filter, EV_DELETE, 0, 0, nil)
          elif (flags and FLAG_TIMER) != 0:
            filter = EVFILT_TIMER
            discard posix.close(cint(s.fds[fdi].key.fd))
            if (flags and FLAG_ONESHOT) == 0:
              modifyKQueue(s, fdi.uint, filter, EV_DELETE, 0, 0, nil)
          elif (flags and FLAG_SIGNAL) != 0:
            filter = EVFILT_SIGNAL
            # unblocking signal
            var nmask = Sigset()
            var omask = Sigset()
            discard sigaddset(nmask, cint(s.fds[fdi].param))
            unblockSignals(nmask, omask)
            discard posix.close(cint(s.fds[fdi].key.fd))
            modifyKQueue(s, fdi.uint, filter, EV_DELETE, 0, 0, nil)
          elif (flags and FLAG_PROCESS) != 0:
            filter = EVFILT_PROC
            discard posix.close(cint(s.fds[fdi].key.fd))
          elif (flags and FLAG_USER) != 0:
            when defined(macosx) or defined(freebsd):
              filter = EVFILT_USER
            else:
              filter = EVFILT_READ
            s.fds[fdi].param = 1
            modifyKQueue(s, fdi.uint, filter, EV_DISABLE, 0, 0, nil)

          s.fds[fdi].ident = 0
          s.fds[fdi].flags = 0

    proc flush*(s: Selector) =
      s.withChangeLock() do:
        var tv = Timespec()
        # if s.changesCount != 0:
        #   echo("FLUSH ===>")
        #   var i = 0
        #   while i < s.changesCount:
        #     stdout.write("changeTable[" & $i & "] = ")
        #     echo $(s.changesTable[i])
        #     inc(i)
        if kevent(s.kqFD, addr(s.changesTable[0]), cint(s.changesCount),
                  nil, 0, addr tv) == -1:
          raiseOSError(osLastError())
        s.changesCount = 0


    template fd*(ev: SelectEvent): cint =
      (ev.rfd)

    when defined(macosx) or defined(freebsd):
      proc setEvent*(ev: SelectEvent) =
        var fdi = ev.rfd.int
        var s = ev.selector
        if (s.fds[fdi].flags and FLAG_USER) != 0:
          if s.fds[fdi].param == 0:
            modifyKQueue(ev.selector, cast[uint](ev.rfd), EVFILT_USER,
                         EV_ENABLE, 0, 0, nil)
            s.fds[fdi].param = 1
            ev.selector.flush()
          modifyKQueue(ev.selector, cast[uint](ev.rfd), EVFILT_USER,
                       0, NOTE_TRIGGER, 0, nil)
        else:
          raise newException(ValueError, "Wrong descriptor type")

      proc close*(ev: SelectEvent) =
        var selector = ev.selector
        selector.unregister(int(ev.rfd))
        modifyKQueue(ev.selector, cast[uint](ev.rfd), EVFILT_USER,
                     EV_DELETE, 0, 0, nil)
        discard posix.close(cint(ev.rfd))
        when hasThreadSupport:
          deallocShared(cast[pointer](ev))
        else:
          GC_unref(ev)

      proc registerEvent*(s: Selector, ev: SelectEvent, data: SelectorData) =
        let param = s.fds[ev.rfd.int].param
        if param != 2:
          s.fds[ev.rfd.int].param = 2
          s.fds[ev.rfd.int].key.data = data
          if param != 1:
            modifyKQueue(s, ev.rfd.uint, EVFILT_USER, EV_ENABLE, 0, 0,
                         nil)
        else:
          raise newException(ValueError, "Event wait still pending!")
      
      proc newEvent*(s: Selector): SelectEvent =
        var fdi = posix.socket(posix.AF_INET, posix.SOCK_STREAM,
                             posix.IPPROTO_TCP).int
        if fdi == -1:
          raiseOsError(osLastError())

        if fdi.uint < s.maxFD:
          if s.fds[fdi].ident == 0:
            when hasThreadSupport:
              result = cast[SelectEvent](allocShared0(sizeof(SelectEventImpl)))
            else:
              result = SelectEvent()
              GC_ref(result)

            result.selector = s
            result.rfd = cint(fdi)

            s.fds[fdi].ident = fdi
            s.fds[fdi].flags = FLAG_USER
            s.fds[fdi].param = 0
            s.fds[fdi].key.fd = fdi
            s.fds[fdi].key.data = nil
            modifyKQueue(s, fdi.uint, EVFILT_USER,
                         EV_ADD or EV_CLEAR or EV_DISABLE, 0, 0, nil)
          else:
            raise newException(ValueError, "Re-use of non-closed descriptor")
        else:
          raise newException(ValueError, "Maximum file descriptors exceeded")
    else:
      # OpenBSD and NetBSD doesn't have support of EVFILT_USER for kqueue
      # (checked for OpenBSD 5.8 and NetBSD 7.0)
      # So we are using pipes to emulate events
      proc newEvent*(s: Selector): SelectEvent =
        var fds: array[2, cint]

        if posix.pipe(fds) == -1:
          raiseOSError(osLastError())

        var fdi = fds[0].int
        if fds[0].uint < s.maxFD and fds[1].uint < s.maxFD:
          if s.fds[fdi].ident == 0:

            setNonBlocking(fds[0])
            setNonBlocking(fds[1])

            when hasThreadSupport:
              result = cast[SelectEvent](allocShared0(sizeof(SelectEventImpl)))
            else:
              result = SelectEvent()
              GC_ref(result)

            result.selector = s
            result.rfd = fds[0]
            result.wfd = fds[1]

            s.fds[fdi].ident = fdi
            s.fds[fdi].flags = FLAG_USER
            s.fds[fdi].param = 0
            s.fds[fdi].key.fd = fdi
            s.fds[fdi].key.data = cast[SelectorData](0)
          else:
            raise newException(ValueError, "Re-use of non-closed descriptor")
        else:
          raise newException(ValueError, "Maximum file descriptors exceeded")

      proc setEvent*(ev: SelectEvent) =
        var data: int = 1
        if posix.write(ev.wfd, addr data, sizeof(int)) != sizeof(int):
          raiseOSError(osLastError())

      proc close*(ev: SelectEvent) =
        var selector = ev.selector
        selector.unregister(int(ev.rfd))
        discard posix.close(cint(ev.rfd))
        discard posix.close(cint(ev.wfd))
        when hasThreadSupport:
          deallocShared(cast[pointer](ev))
        else:
          GC_unref(ev)

      proc registerEvent*(s: Selector, ev: SelectEvent, data: SelectorData) =
        let param = s.fds[ev.rfd.int].param
        if param != 2:
          s.fds[ev.rfd.int].param = 2
          s.fds[ev.rfd.int].key.data = data
          if param != 1:
            modifyKQueue(s, ev.rfd.uint, EVFILT_READ, EV_ADD, 0, 0, nil)
        else:
          raise newException(ValueError, "Event wait still pending!")

    template processEndgame(s: Selector, kevents, count, results: untyped): int =
      var skey: ptr SelectorKey
      var i = 0
      var k = 0
      while i < count:
        if (kevents[i].flags and EV_ERROR) == 0:
          var events = 0
          case kevents[i].filter
          of EVFILT_READ:
            skey = addr(s.fds[kevents[i].ident.int])
            when defined(openbsd) or defined(netbsd):
              if (skey.flags and FLAG_USER) != 0:
                var data: int = 0
                if posix.read(kevents[i].ident.cint, addr data,
                              sizeof(int)) != sizeof(int):
                  raiseOSError(osLastError())
              events = EVENT_USER
            else:
              events = EVENT_READ
          of EVFILT_WRITE:
            skey = addr(s.fds[kevents[i].ident.int])
            events = EVENT_WRITE
          of EVFILT_TIMER:
            skey = addr(s.fds[kevents[i].ident.int])
            if (skey.flags and FLAG_ONESHOT) != 0:
              if posix.close(skey.ident.cint) == -1:
                raiseOSError(osLastError())
              skey.ident = 0
              skey.flags = 0
            events = EVENT_TIMER
          of EVFILT_VNODE:
            skey = addr(s.fds[kevents[i].ident.int])
            events = EVENT_VNODE
          of EVFILT_SIGNAL:
            skey = addr(s.fds[cast[int](kevents[i].udata)])
            events = EVENT_SIGNAL
          of EVFILT_PROC:
            skey = addr(s.fds[cast[int](kevents[i].udata)])
            events = EVENT_PROCESS
          else:
            when defined(macosx) or defined(freebsd):
              if kevents[i].filter == EVFILT_USER:
                skey = addr(s.fds[kevents[i].ident.int])
                events = EVENT_USER
                s.modifyKQueue(kevents[i].ident, EVFILT_USER, EV_CLEAR, 0, 0, nil)
              else:
                raise newException(ValueError,
                                   "Unsupported kqueue filter in queue")
            else:
              raise newException(ValueError,
                                 "Unsupported kqueue filter in queue")

          if (kevents[i].flags and EV_EOF) != 0: events = events or EVENT_ERROR

          when hasThreadSupport:
            results[k].fd = skey.key.fd
            results[k].events = events
            results[k].data = skey.key.data
          else:
            skey.key.events = events
            results[k] = cast[ReadyKey](addr skey.key)
          inc(k)
        inc(i)
      k

    proc selectInto*(s: Selector, timeout: int,
                     results: var openarray[ReadyKey]): int =
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

      # echo("SELECT ===>")
      # if s.changesCount != 0:
      #   var i = 0
      #   while i < s.changesCount:
      #     stdout.write("changeTable[" & $i & "] = ")
      #     echo $(s.changesTable[i])
      #     inc(i)

      var count = 0
      s.withChangeLock() do:
        count = kevent(s.kqFD,
                       addr(s.changesTable[0]), cint(s.changesCount),
                       addr(resultsTable[0]), cint(maxResults), ptv)
        s.changesCount = 0
      if count >= 0:
        result = s.processEndgame(resultsTable, count, results)
      else:
        result = 0
        let err = osLastError()
        if cint(err) != EINTR:
          raiseOSError(err)

    proc select*(s: Selector, timeout: int): seq[ReadyKey] =
      result = newSeq[ReadyKey](MAX_KQUEUE_RESULT_EVENTS)
      var count = selectInto(s, timeout, result)
      result.setLen(count)

  #
  # Linux epoll
  #

  elif defined(linux):
    const
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
      # EPOLLPRI     = 0x00000002
      EPOLLOUT     = 0x00000004
      EPOLLERR     = 0x00000008
      EPOLLHUP     = 0x00000010
      # EPOLLRDNORM  = 0x00000040
      # EPOLLRDBAND  = 0x00000080
      # EPOLLWRNORM  = 0x00000100
      # EPOLLWRBAND  = 0x00000200
      # EPOLLMSG     = 0x00000400
      EPOLLRDHUP   = 0x00002000
      # EPOLLWAKEUP  = 1 shl 29
      EPOLLONESHOT = 1 shl 30
      # EPOLLET      = 1 shl 31

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
      SelectorImpl* = object
        epollFD : cint
        maxFD : uint
        fds: fdList

    when hasThreadSupport:
      type Selector* = ptr SelectorImpl
    else:
      type Selector* = ref SelectorImpl

    type
      SelectEventImpl* = object
        efd: cint
        selector: Selector

    when hasThreadSupport:
      type SelectEvent* = ptr SelectEventImpl
    else:
      type SelectEvent* = ref SelectEventImpl

    proc newSelector*(): Selector =
      var maxFD = getMaxFds()
      var epollFD = epoll_create(MAX_EPOLL_RESULT_EVENTS)
      if epollFD < 0:
        raiseOsError(osLastError())
      when hasThreadSupport:
        result = cast[Selector](allocShared0(sizeof(SelectorImpl)))
        result.epollFD = epollFD
        result.maxFD = maxFD.uint
        result.fds = cast[fdList](allocShared0(maxFD * sizeof(SelectorKey)))
      else:
        result = Selector(epollFD: epollFD, maxFD: maxFD.uint)
        result.fds = newSeq[SelectorKey](maxFD)

    proc close*(s: Selector) =
      if posix.close(s.epollFD) != 0:
        raiseOSError(osLastError())
      when hasThreadSupport:
        deallocShared(cast[pointer](s.fds))
        deallocShared(cast[pointer](s))

    proc registerHandle*(s: Selector, fd: SocketHandle, event: int,
                         data: SelectorData) =
      var fdi = int(fd)
      if fdi.uint < s.maxFD:
        if s.fds[fdi].ident == 0:
          s.fds[fdi].ident = fdi
          s.fds[fdi].flags = FLAG_HANDLE or event
          s.fds[fdi].param = 0
          s.fds[fdi].key.fd = fdi
          s.fds[fdi].key.data = data
          var epv: epoll_event
          epv.events = EPOLLRDHUP
          epv.data.u64 = fdi.uint
          if (event and EVENT_READ) != 0:
            epv.events = epv.events or EPOLLIN
          if (event and EVENT_WRITE) != 0:
            epv.events = epv.events or EPOLLOUT
          if epoll_ctl(s.epollFD, EPOLL_CTL_ADD, fdi.cint, addr epv) == -1:
            raiseOSError(osLastError())
        else:
          raise newException(ValueError, "Re-use of non-closed descriptor")
      else:
        raise newException(ValueError, "Maximum file descriptors exceeded")

    proc updateHandle*(s: Selector, fd: SocketHandle, event: int) =
      var fdi = int(fd)
      if fdi.uint < s.maxFD:
        if s.fds[fdi].ident != 0:
          if (s.fds[fdi].flags and FLAG_HANDLE) != 0:
            var epv: epoll_event
            epv.data.u64 = fdi.uint
            epv.events = EPOLLRDHUP
            if (event and EVENT_READ) != 0:
              epv.events = epv.events or EPOLLIN
            if (event and EVENT_WRITE) != 0:
              epv.events = epv.events or EPOLLOUT
            if epoll_ctl(s.epollFD, EPOLL_CTL_MOD, fdi.cint, addr epv) == -1:
              raiseOSError(osLastError())
            s.fds[fdi].flags = FLAG_HANDLE or event
          else:
            raise newException(ValueError,
                               "Could not update non-handle descriptor")
        else:
          raise newException(ValueError, "Descriptor is not registered in queue")
      else:
        raise newException(ValueError, "Maximum file descriptors exceeded")

    proc unregister*(s: Selector, fd: int|SocketHandle|cint) =
      var fdi = int(fd)
      if fdi.uint < s.maxFD:
        var flags = s.fds[fdi].flags
        if s.fds[fdi].ident != 0 and flags != 0:
          s.fds[fdi].ident = 0
          s.fds[fdi].flags = 0
          var epv: epoll_event
          try:
            if epoll_ctl(s.epollFD, EPOLL_CTL_DEL, fdi.cint, addr epv) == -1:
              raiseOSError(osLastError())
          finally:
            if (flags and FLAG_HANDLE) != 0:
              discard
            elif (flags and FLAG_TIMER) != 0:
              discard posix.close(fdi.cint)
            elif (flags and FLAG_SIGNAL) != 0:
              var nmask: Sigset
              var omask: Sigset
              discard sigemptyset(nmask)
              discard sigemptyset(omask)
              discard sigaddset(nmask, cint(s.fds[fdi].param))
              unblockSignals(nmask, omask)
              discard posix.close(fdi.cint)
            elif (flags and FLAG_PROCESS) != 0:
              var nmask: Sigset
              var omask: Sigset
              discard sigemptyset(nmask)
              discard sigemptyset(omask)
              discard sigaddset(nmask, SIGCHLD)
              unblockSignals(nmask, omask)
              discard posix.close(fdi.cint)
            elif (flags and FLAG_USER) != 0:
              s.fds[fdi].param = 0

    proc registerTimer*(s: Selector, timeout: int, oneshot: bool,
                        data: SelectorData): int {.discardable.} =
      var
        new_ts: Itimerspec
        old_ts: Itimerspec
      var fdi = timerfd_create(CLOCK_MONOTONIC.ClockId, 0)
      if fdi == -1:
        raiseOSError(osLastError())
      if fdi.uint < s.maxFD:
        if s.fds[fdi].ident == 0:
          var epv: epoll_event
          epv.data.u64 = fdi.uint
          epv.events = EPOLLIN or EPOLLRDHUP
          setNonBlocking(fdi.cint)
          var flags = FLAG_TIMER
          if oneshot:
            new_ts.it_interval.tv_sec = 0.Time
            new_ts.it_interval.tv_nsec = 0
            new_ts.it_value.tv_sec = (timeout div 1_000).Time
            new_ts.it_value.tv_nsec = (timeout %% 1_000) * 1_000_000
            flags = flags or FLAG_ONESHOT
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
          s.fds[fdi].ident = fdi
          s.fds[fdi].flags = flags
          s.fds[fdi].param = 0
          s.fds[fdi].key.fd = fdi
          s.fds[fdi].key.data = data
          result = fdi
        else:
          raise newException(ValueError, "Re-use of non-closed descriptor")
      else:
        raise newException(ValueError, "Maximum file descriptors exceeded")

    proc registerSignal*(s: Selector, signal: int,
                         data: SelectorData): int {.discardable.} =
      var
        nmask: Sigset
        omask: Sigset
        fd: int
      discard sigemptyset(nmask)
      discard sigemptyset(omask)
      discard sigaddset(nmask, signal.cint)
      blockSignals(nmask, omask)
      try:
        var fdi = signalfd(-1, nmask, 0)
        if fd == -1:
          raiseOSError(osLastError())
        if fdi.uint < s.maxFD:
          if s.fds[fdi].ident == 0:
            setNonBlocking(fdi.cint)
            var epv: epoll_event
            epv.data.u64 = fdi.uint
            epv.events = EPOLLIN or EPOLLRDHUP
            if epoll_ctl(s.epollFD, EPOLL_CTL_ADD, fdi.cint, addr epv) == -1:
              raiseOSError(osLastError())
            s.fds[fdi].ident = fdi
            s.fds[fdi].flags = FLAG_SIGNAL
            s.fds[fdi].param = signal
            s.fds[fdi].key.fd = signal
            s.fds[fdi].key.data = data
            result = fdi
          else:
            raise newException(ValueError, "Re-use of non-closed descriptor")
        else:
          raise newException(ValueError, "Maximum file descriptors exceeded")
      except:
        if fd != -1: discard posix.close(fd.cint)
        unblockSignals(omask, nmask)

    proc registerProcess*(s: Selector, pid: int,
                          data: SelectorData): int {.discardable.} =
      var
        nmask: Sigset
        omask: Sigset
        fd: int
      discard sigemptyset(nmask)
      discard sigemptyset(omask)
      discard sigaddset(nmask, posix.SIGCHLD)
      blockSignals(nmask, omask)
      try:
        var fdi = signalfd(-1, nmask, 0)
        if fd == -1:
          raiseOSError(osLastError())
        if fdi.uint < s.maxFD:
          if s.fds[fdi].ident == 0:
            setNonBlocking(fdi.cint)
            var epv: epoll_event
            epv.data.u64 = fdi.uint
            epv.events = EPOLLIN or EPOLLRDHUP
            if epoll_ctl(s.epollFD, EPOLL_CTL_ADD, fdi.cint, addr epv) == -1:
              raiseOSError(osLastError())
            s.fds[fdi].ident = fdi
            s.fds[fdi].flags = FLAG_PROCESS
            s.fds[fdi].param = pid
            s.fds[fdi].key.fd = fdi
            s.fds[fdi].key.data = data
            result = fdi
          else:
            raise newException(ValueError, "Re-use of non-closed descriptor")
        else:
          raise newException(ValueError, "Maximum file descriptors exceeded")
      except:
        if fd != -1: discard posix.close(fd.cint)
        unblockSignals(omask, nmask)

    proc flush*(s: Selector) =
      discard

    proc registerEvent*(s: Selector, ev: SelectEvent, data: SelectorData) =
      if s.fds[ev.efd.int].param == 0:
        s.fds[ev.efd.int].param = 1
        s.fds[ev.efd.int].key.data = data

        var epv = epoll_event(events: EPOLLIN or EPOLLRDHUP)
        epv.data.u64 = ev.efd.uint
        if epoll_ctl(s.epollFD, EPOLL_CTL_ADD, ev.efd.cint, addr epv) == -1:
          raiseOSError(osLastError())
      else:
        raise newException(ValueError, "Event wait still pending!")

    proc setEvent*(ev: SelectEvent) =
      var data : uint64 = 1
      if posix.write(ev.efd, addr data, sizeof(uint64)) == -1:
        raiseOSError(osLastError())

    proc close*(ev: SelectEvent) =
      var selector = ev.selector
      selector.unregister(int(ev.efd))
      discard posix.close(ev.efd)
      when hasThreadSupport:
        deallocShared(cast[pointer](ev))
      else:
        GC_unref(ev)

    template fd*(ev: SelectEvent): cint =
      (ev.efd)

    proc newEvent*(s: Selector): SelectEvent =
      var fdi = eventfd(0, 0)
      if fdi == -1:
        raiseOSError(osLastError())

      if fdi.uint < s.maxFD:
        if s.fds[fdi].ident == 0:
          when hasThreadSupport:
            result = cast[SelectEvent](allocShared0(sizeof(SelectEventImpl)))
          else:
            result = SelectEvent()
            GC_ref(result)
          result.selector = s
          result.efd = cint(fdi)
          s.fds[fdi].ident = fdi
          s.fds[fdi].flags = FLAG_USER
          s.fds[fdi].param = 0
          s.fds[fdi].key.fd = fdi
        else:
          raise newException(ValueError, "Re-use of non-closed descriptor")
      else:
        raise newException(ValueError, "Maximum file descriptors exceeded")

    template processEndgame(s: Selector, eevents, count, results: untyped): int =
      var skey: ptr SelectorKey
      var i = 0
      var k = 0
      while i < count:
        var events = 0
        let fdi = int(eevents[i].data.u64)
        var skey = addr(s.fds[fdi])
        let pevents = eevents[i].events
        let flags = s.fds[fdi].flags

        if skey.ident != 0 and flags != 0:
          block processItem:
            if (pevents and EPOLLERR) != 0 or (pevents and EPOLLHUP) != 0:
              events = events or EVENT_ERROR
            if (pevents and EPOLLOUT) != 0:
              events = events or EVENT_WRITE
            if (pevents and EPOLLIN) != 0:
              if (flags and FLAG_HANDLE) != 0:
                events = events or EVENT_READ
              elif (flags and FLAG_TIMER) != 0:
                var data: uint64 = 0
                if posix.read(fdi.cint, addr data,
                              sizeof(uint64)) != sizeof(uint64):
                  raiseOSError(osLastError())
                events = events or EVENT_TIMER
              elif (flags and FLAG_SIGNAL) != 0:
                var data: SignalFdInfo
                if posix.read(fdi.cint, addr data,
                              sizeof(SignalFdInfo)) != sizeof(SignalFdInfo):
                  raiseOsError(osLastError())
                events = events or EVENT_SIGNAL
              elif (flags and FLAG_PROCESS) != 0:
                var data: SignalFdInfo
                if posix.read(fdi.cint, addr data,
                              sizeof(SignalFdInfo)) != sizeof(SignalFdInfo):
                  raiseOsError(osLastError())
                if cast[int](data.ssi_pid) == skey.param:
                  events = events or EVENT_PROCESS
                else:
                  break processItem
              elif (flags and FLAG_USER) != 0:
                var data: uint = 0
                if posix.read(fdi.cint, addr data, sizeof(uint)) != sizeof(uint):
                  raiseOSError(osLastError())
                events = events or EVENT_USER
              else:
                raise newException(ValueError, "Unsupported epoll event in queue")

            when hasThreadSupport:
              results[k].fd = fdi
              results[k].events = events
              results[k].data = skey.key.data
            else:
              skey.key.events = events
              results[k] = cast[ReadyKey](addr skey.key)
            inc(k)
        inc(i)
      k

    proc selectInto*(s: Selector, timeout: int,
                     results: var openarray[ReadyKey]): int =
      var
        resultsTable: array[MAX_EPOLL_RESULT_EVENTS, epoll_event]

      var maxResults = MAX_EPOLL_RESULT_EVENTS
      if maxResults > len(results):
        maxResults = len(results)

      var count = epoll_wait(s.epollFD, addr(resultsTable[0]), maxResults.cint,
                             timeout.cint)
      if count > 0:
        result = s.processEndgame(resultsTable, count, results)
      elif count == 0:
        discard
      else:
        result = 0
        let err = osLastError()
        if cint(err) != EINTR:
          raiseOSError(err)

    proc select*(s: Selector, timeout: int): seq[ReadyKey] =
      result = newSeq[ReadyKey](MAX_EPOLL_RESULT_EVENTS)
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

    template FD_ISSET(s: SocketHandle, fdSet: var TFdSet): bool =
      if WSAFDIsSet(s, fdSet): true else: false

    template FD_SET(s: SocketHandle, fdSet: var TFdSet) =
      block:
        var i = 0
        while i < fdSet.fd_count:
          if fdSet.fd_array[i] == s:
            break
          inc(i)
        if i == fdSet.fd_count:
          if fdSet.fd_count < FD_SETSIZE:
            fdSet.fd_array[i] = s
            inc(fdSet.fd_count)
    template FD_CLR(s: SocketHandle, fdSet: var TFdSet) =
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
    template FD_ZERO(fdSet: var TFdSet) =
      fdSet.fd_count = 0

    type
      SelectorImpl* = object
        rSet: TFdSet
        wSet: TFdSet
        eSet: TFdSet
        maxFD : uint
        when hasThreadSupport:
          fds: SharedTable[SocketHandle, SelectorKey]
          lock: Lock
        else:
          fds: Table[SocketHandle, SelectorKey]

    when hasThreadSupport:
      type Selector* = ptr SelectorImpl
    else:
      type Selector* = ref SelectorImpl

    type
      SelectEventImpl* = object
        rsock: SocketHandle
        wsock: SocketHandle
        selector: Selector

    when hasThreadSupport:
      type SelectEvent* = ptr SelectEventImpl
    else:
      type SelectEvent* = ref SelectEventImpl

    proc newSelector*(): Selector =
      var maxFD = FD_SETSIZE
      when hasThreadSupport:
        result = cast[Selector](allocShared0(sizeof(SelectorImpl)))
        result.maxFD = maxFD.uint
        result.fds = initSharedTable[SocketHandle, SelectorKey]()
        initLock result.lock
      else:
        result = Selector(maxFD: FD_SETSIZE)
        result.maxFD = maxFD.uint
        result.fds = initTable[SocketHandle, SelectorKey]()
      FD_ZERO(result.rSet)
      FD_ZERO(result.wSet)
      FD_ZERO(result.eSet)

    proc close*(s: Selector) =
      when hasThreadSupport:
        deinitSharedTable(s.fds)
        deallocShared(cast[pointer](s))

    template selectAdd(s: Selector, fd: SocketHandle, event: int) =
      when hasThreadSupport:
        withLock s.lock:
          if (event and EVENT_READ) != 0 and s.rSet.fd_count == FD_SETSIZE:
            raise newException(ValueError, "Maximum numbers of fds exceeded")
          if (event and EVENT_WRITE) != 0 and s.wSet.fd_count == FD_SETSIZE:
            raise newException(ValueError, "Maximum numbers of fds exceeded")

          if (event and EVENT_READ) != 0:
            FD_SET(fd, s.rSet)
          if (event and EVENT_WRITE) != 0:
            FD_SET(fd, s.wSet)
            FD_SET(fd, s.eSet)
      else:
        if (event and EVENT_READ) != 0 and s.rSet.fd_count == FD_SETSIZE:
            raise newException(ValueError, "Maximum numbers of fds exceeded")
        if (event and EVENT_WRITE) != 0 and s.wSet.fd_count == FD_SETSIZE:
          raise newException(ValueError, "Maximum numbers of fds exceeded")

        if (event and EVENT_READ) != 0:
          FD_SET(fd, s.rSet)
        if (event and EVENT_WRITE) != 0:
          FD_SET(fd, s.wSet)
          FD_SET(fd, s.eSet)

    proc registerHandle*(s: Selector, fd: SocketHandle, event: int,
                         data: SelectorData) =
      var fdi = int(fd)
      var nkey = SelectorKey(ident: fdi, flags: FLAG_HANDLE or event)
      nkey.key.fd = fdi
      nkey.key.data = data

      if s.fds.hasKeyOrPut(fd, nkey):
        raise newException(ValueError, "Re-use of non closed descriptor")
      s.selectAdd(fd, event)

    proc updateHandle*(s: Selector, fd: SocketHandle, event: int) =
      when hasThreadSupport:
        s.fds.withValue(fd, value) do:
          withLock(s.lock) do:
            if (value.flags and FLAG_HANDLE) != 0:
              var oe = value.flags
              if (oe xor event) != 0:
                if (oe and EVENT_READ) != 0 and (event and EVENT_READ) == 0:
                  FD_CLR(fd, s.rSet)
                if (oe and EVENT_WRITE) != 0 and (event and EVENT_WRITE) == 0:
                  FD_CLR(fd, s.wSet)
                  FD_CLR(fd, s.eSet)
                if (oe and EVENT_READ) == 0 and (event and EVENT_READ) != 0:
                  FD_SET(fd, s.rSet)
                if (oe and EVENT_WRITE) == 0 and (event and EVENT_WRITE) != 0:
                  FD_SET(fd, s.wSet)
                  FD_SET(fd, s.eSet)
                value.flags = FLAG_HANDLE or event  
            else:
              raise newException(ValueError,
                                 "Could not update non-handle descriptor")
        do:
          raise newException(ValueError, "Descriptor is not registered in queue")
      else:
        s.fds.withValue(fd, value) do:
          if (value.flags and FLAG_HANDLE) != 0:
            var oe = (value.flags and EVENT_MASK)
            if (oe xor event) != 0:
              if (oe and EVENT_READ) != 0 and (event and EVENT_READ) == 0:
                FD_CLR(fd, s.rSet)
              if (oe and EVENT_WRITE) != 0 and (event and EVENT_WRITE) == 0:
                FD_CLR(fd, s.wSet)
                FD_CLR(fd, s.eSet)
              if (oe and EVENT_READ) == 0 and (event and EVENT_READ) != 0:
                FD_SET(fd, s.rSet)
              if (oe and EVENT_WRITE) == 0 and (event and EVENT_WRITE) != 0:
                FD_SET(fd, s.wSet)
                FD_SET(fd, s.eSet)
              value.flags = FLAG_HANDLE or event
          else:
            raise newException(ValueError, "error")
        do:
          raise newException(ValueError, "Descriptor is not registered in queue")

    proc registerTimer*(s: Selector, timeout: int, oneshot: bool,
                        data: SelectorData): int {.discardable.} =
      raise newException(ValueError, "Not implemented")

    proc registerSignal*(s: Selector, signal: int,
                         data: SelectorData): int {.discardable.} =
      raise newException(ValueError, "Not implemented")

    proc registerProcess*(s: Selector, pid: int,
                          data: SelectorData): int {.discardable.} =
      raise newException(ValueError, "Not implemented")

    proc flush*(s: Selector) = discard

    proc unregister*(s: Selector, fd: SocketHandle) =
      when hasThreadSupport:
        withLock s.lock:
          s.fds.del(fd)
          FD_CLR(fd, s.rSet)
          FD_CLR(fd, s.wSet)
          FD_CLR(fd, s.eSet)
      else:
        s.fds.del(fd)
        FD_CLR(fd, s.rSet)
        FD_CLR(fd, s.wSet)
        FD_CLR(fd, s.eSet)

    proc newEvent*(s: Selector): SelectEvent = 
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

        when hasThreadSupport:
          result = cast[SelectEvent](allocShared0(sizeof(SelectEventImpl)))
        else:
          result = SelectEvent()
          GC_ref(result)

        result.selector = s
        result.rsock = rsock
        result.wsock = wsock

        var nkey = SelectorKey(ident: rsock.int, flags: FLAG_USER)
        nkey.key.fd = rsock.int
        nkey.key.data = cast[SelectorData](result)

        if s.fds.hasKeyOrPut(rsock, nkey):
          raise newException(ValueError, "Re-use of non closed descriptor")
        s.selectAdd(rsock, EVENT_READ)
        
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
      var selector = ev.selector
      selector.unregister(ev.rsock)
      discard winlean.closesocket(ev.rsock)
      discard winlean.closesocket(ev.wsock)
      when hasThreadSupport:
        deallocShared(cast[pointer](ev))
      else:
        GC_unref(ev)

    template processEndgame(s: Selector, rset: var TFdSet, wset: var TFdSet,
                            eset: var TFdSet, results: var openarray[ReadyKey]) =
      var rindex = 0
      for i in countup(0, rset.fd_count):
        let fd = rset.fd_array[i]
        if FD_ISSET(fd, rset):
          var events = EVENT_READ
          if FD_ISSET(fd, eset): events = events or EVENT_ERROR
          if FD_ISSET(fd, wset): events = events or EVENT_WRITE
          s.fds.withValue(fd, skey) do:
            if (skey.flags and FLAG_HANDLE) != 0:
              skey.key.events = events
            elif (skey.flags and FLAG_USER) != 0:
              var data: int = 0
              if winlean.recv(fd, cast[pointer](addr(data)),
                              sizeof(int).cint, 0) != sizeof(int):
                raiseOSError(osLastError())
              skey.key.events = EVENT_USER
            when hasThreadSupport:
              results[rindex].fd = skey.key.fd
              results[rindex].data = skey.key.data
              results[rindex].events = skey.key.events
            else:
              results[rindex] = addr(skey.key)
            inc(rindex)
      for i in countup(0, wset.fd_count):
        let fd = wset.fd_array[i]
        if FD_ISSET(fd, wset):
          var events = EVENT_WRITE
          if not FD_ISSET(fd, rset):
            if FD_ISSET(fd, eset): events = events or EVENT_ERROR
            s.fds.withValue(fd, skey) do:
              skey.key.events = events
              when hasThreadSupport:
                results[rindex].fd = skey.key.fd
                results[rindex].data = skey.key.data
                results[rindex].events = skey.key.events
              else:
                results[rindex] = addr(skey.key)
              inc(rindex)

    proc selectInto*(s: Selector, timeout: int,
                     results: var openarray[ReadyKey]): int =
      var tv = Timeval()
      var ptv = addr tv
      var rset, wset, eset: TFdSet

      if timeout != -1:
        tv.tv_sec = timeout.int32 div 1_000
        tv.tv_usec = (timeout.int32 %% 1_000) * 1_000
      else:
        ptv = nil

      when hasThreadSupport:
        withLock s.lock:
          rset = s.rSet
          wset = s.wSet
          eset = s.eSet
      else:
        rset = s.rSet
        wset = s.wSet
        eset = s.eSet

      var count = select(cint(0), addr(rset), addr(wset),
                         addr(eset), ptv).int
      if count > 0:
        s.processEndgame(rset, wset, eset, results)
      elif count == 0:
        discard
      else:
        raiseOSError(osLastError())
      result = count

    proc select*(s: Selector, timeout: int): seq[ReadyKey] =
      result = newSeq[ReadyKey](FD_SETSIZE)
      var count = selectInto(s, timeout, result)
      result.setLen(count)       

  #
  # Posix poll
  #

  else:
    const MAX_POLL_RESULT_EVENTS = 64
    const uncheckedSize = when defined(cpu16): 10_000 else: 100_000_000
    type
      pollFdList {.unchecked.} = ptr array[0..uncheckedSize, TPollFd]

      SelectorImpl* = object
        maxFD : uint
        pollcnt: int
        fds: fdList
        pollfds: pollFdList
        when hasThreadSupport:
          lock: Lock

    when hasThreadSupport:
      type Selector* = ptr SelectorImpl
    else:
      type Selector* = ref SelectorImpl

    type
      SelectEventImpl* = object
        rfd: cint
        wfd: cint
        selector: Selector

    when hasThreadSupport:
      type SelectEvent* = ptr SelectEventImpl
    else:
      type SelectEvent* = ref SelectEventImpl

    when hasThreadSupport:
      template withPollLock(s: Selector, body: untyped) =
        acquire(s.lock)
        {.locks: [s.lock].}:
          try:
            body
          finally:
            release(s.lock)
    else:
      template withPollLock(s, body: untyped) =
        body

    proc newSelector*(): Selector =
      var maxFD = getMaxFds()

      when hasThreadSupport:
        result = cast[Selector](allocShared0(sizeof(SelectorImpl)))
        result.maxFD = maxFD.uint
        result.fds = cast[fdList](allocShared0(maxFD * sizeof(SelectorKey)))
        result.pollfds = cast[pollFdList](allocShared0(maxFD * sizeof(TPollFd)))
        initLock(result.lock)
      else:
        result = Selector(maxFD: maxFD.uint)
        result.maxFD = maxFD.uint
        result.fds = newSeq[SelectorKey](maxFD)
        result.pollfds = cast[pollFdList](alloc0(maxFD * sizeof(TPollFd)))

    proc close*(s: Selector) =
      when hasThreadSupport:
        deinitLock(s.lock)
        deallocShared(cast[pointer](s.fds))
        deallocShared(cast[pointer](s.pollfds))
        deallocShared(cast[pointer](s))
      else:
        dealloc(cast[pointer](s.fds))
        dealloc(cast[pointer](s.pollfds))

    template pollAdd(s: Selector, sock: cint, event: int) =
      s.withPollLock() do:
        var pollev: cshort = 0
        if (event and EVENT_READ) != 0: pollev = pollev or POLLIN
        if (event and EVENT_WRITE) != 0: pollev = pollev or POLLOUT
        s.pollfds[s.pollcnt].fd = cint(sock)
        s.pollfds[s.pollcnt].events = pollev
        inc(s.pollcnt)

    template pollUpdate(s: Selector, sock: cint, event: int) =
      s.withPollLock() do:
        var i = 0
        var pollev: cshort = 0
        if (event and EVENT_READ) != 0: pollev = pollev or POLLIN
        if (event and EVENT_WRITE) != 0: pollev = pollev or POLLOUT

        while i < s.pollcnt:
          if s.pollfds[i].fd == sock:
            s.pollfds[i].events = pollev
            break
          inc(i)

        if i == s.pollcnt:
          raise newException(ValueError,
                             "Descriptor is not registered in queue")

    template pollRemove(s: Selector, sock: cint) =
      s.withPollLock() do:
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
            dec(s.pollcnt)
            break
          inc(i)

    proc registerHandle*(s: Selector, fd: SocketHandle, event: int,
                         data: SelectorData) =
      var fdi = int(fd)
      if fdi.uint < s.maxFD:
        if s.fds[fdi].ident == 0:
          s.fds[fdi].ident = fdi
          s.fds[fdi].flags = FLAG_HANDLE or event
          s.fds[fdi].param = 0
          s.fds[fdi].key.fd = fdi
          s.fds[fdi].key.data = data
          s.pollAdd(fdi.cint, event)
        else:
          raise newException(ValueError, "Re-use of non-closed descriptor")
      else:
        raise newException(ValueError, "Maximum file descriptors exceeded")

    proc updateHandle*(s: Selector, fd: SocketHandle, event: int) =
      var fdi = int(fd)
      if fdi.uint < s.maxFD:
        if s.fds[fdi].ident != 0:
          if (s.fds[fdi].flags and FLAG_HANDLE) != 0:
            var oe = s.fds[fdi].flags and EVENT_MASK
            if (oe xor event) != 0:
              s.pollUpdate(fd.cint, event)
              s.fds[fdi].flags = FLAG_HANDLE or event
          else:
            raise newException(ValueError,
                               "Could not update non-handle descriptor")
        else:
          raise newException(ValueError, "Re-use of non closed descriptor")
      else:
        raise newException(ValueError, "Maximum file descriptors exceeded")

    proc registerTimer*(s: Selector, timeout: int, oneshot: bool,
                        data: SelectorData): int {.discardable.} =
      raise newException(ValueError, "Not implemented")

    proc registerSignal*(s: Selector, signal: int,
                         data: SelectorData): int {.discardable.} =
      raise newException(ValueError, "Not implemented")

    proc registerProcess*(s: Selector, pid: int,
                          data: SelectorData): int {.discardable.} =
      raise newException(ValueError, "Not implemented")

    proc flush*(s: Selector) = discard

    proc unregister*(s: Selector, fd: int|SocketHandle|cint) =
      var fdi = int(fd)
      if fdi.uint < s.maxFD:
        s.fds[fdi].ident = 0
        s.fds[fdi].flags = 0
        s.pollRemove(fdi.cint)

    proc newEvent*(s: Selector): SelectEvent =
      var fds: array[2, cint]

      if posix.pipe(fds) == -1:
        raiseOSError(osLastError())

      var fdi = fds[0].int
      if fds[0].uint < s.maxFD and fds[1].uint < s.maxFD:
        if s.fds[fdi].ident == 0:
          setNonBlocking(fds[0])
          setNonBlocking(fds[1])

          when hasThreadSupport:
            result = cast[SelectEvent](allocShared0(sizeof(SelectEventImpl)))
          else:
            result = SelectEvent()
            GC_ref(result)
          result.selector = s
          result.rfd = fds[0]
          result.wfd = fds[1]
          s.fds[fdi].ident = fdi
          s.fds[fdi].flags = FLAG_USER
          s.fds[fdi].param = 0
          s.fds[fdi].key.fd = fdi
          s.fds[fdi].key.data = cast[SelectorData](result)
          s.pollAdd(fdi.cint, EVENT_READ)
        else:
          raise newException(ValueError, "Re-use of non-closed descriptor")
      else:
        raise newException(ValueError, "Maximum file descriptors exceeded")

    proc setEvent*(ev: SelectEvent) =
      var data: int = 1
      if posix.write(ev.wfd, addr data, sizeof(int)) != sizeof(int):
        raiseOSError(osLastError())

    proc close*(ev: SelectEvent) =
      var selector = ev.selector
      selector.unregister(int(ev.rfd))
      discard posix.close(cint(ev.rfd))
      discard posix.close(cint(ev.wfd))
      when hasThreadSupport:
        deallocShared(cast[pointer](ev))
      else:
        GC_unref(ev)

    template processEndgame(s: Selector, results: var openarray[ReadyKey],
                            count: int, maxcount: int) =
      var i = 0
      var k = 0
      var rindex = 0
      while (i < s.pollcnt) and (k < count) and (rindex < maxcount):
        let revents = s.pollfds[i].revents
        let fd = s.pollfds[i].fd
        if revents != 0:
          var events = 0
          if (revents and POLLIN) != 0:
            events = events or EVENT_READ
          if (revents and POLLOUT) != 0:
            events = events or EVENT_WRITE
          if (revents and POLLERR) != 0 or (revents and POLLHUP) != 0 or
             (revents and POLLNVAL) != 0:
            events = events and EVENT_ERROR
          var skey = addr(s.fds[fd])
          
          if (skey.flags and FLAG_USER) != 0:
            if (events and EVENT_READ) != 0:
              var data: int = 0
              if posix.read(fd, addr data, sizeof(int)) != sizeof(int):
                raiseOSError(osLastError())
              events = EVENT_USER

          when hasThreadSupport:
            results[rindex].fd = fd
            results[rindex].events = events
            results[rindex].data = skey.key.data
          else:
            skey.key.events = events
            results[rindex] = cast[ReadyKey](addr(skey.key))
          s.pollfds[i].revents = 0
          inc(rindex)
          inc(k)
        inc(i)

    proc selectInto*(s: Selector, timeout: int,
                     results: var openarray[ReadyKey]): int =
      var maxResults = MAX_POLL_RESULT_EVENTS
      if maxResults > len(results):
        maxResults = len(results)

      s.withPollLock() do:
        var count = posix.poll(addr(s.pollfds[0]), s.pollcnt.Tnfds, timeout)
        # echo("count = " & $count)
        if count > 0:
          s.processEndgame(results, count, maxResults)
          result = count
        elif count == 0:
          discard
        else:
          let err = osLastError()
          if err.cint == EINTR:
            discard
          else:
            raiseOSError(osLastError())

    proc select*(s: Selector, timeout: int): seq[ReadyKey] =
      result = newSeq[ReadyKey](MAX_POLL_RESULT_EVENTS)
      var count = selectInto(s, timeout, result)
      result.setLen(count)

  when not defined(windows):
    template withData*(s: Selector, fd: SocketHandle, value, body: untyped) =
      var fdi = int(fd)
      if fdi.uint < s.maxFD:
        if s.fds[fdi].ident != 0:
          var value {.inject.} = s.fds[fdi].key.data
          body
      else:
        raise newException(ValueError, "Maximum file descriptors exceeded")
    template withData*(s: Selector, fd: SocketHandle, value,
                       body1, body2: untyped) =
      var fdi = int(fd)
      if fdi.uint < s.maxFD:
        if s.fds[fdi].ident != 0:
          var value {.inject.} = s.fds[fdi].key.data
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

when not defined(nimdoc):
  when isMainModule:
    template processTest(t, x: untyped) =
      stdout.write(t)
      stdout.flushFile()
      if x:
        stdout.write(" OK\r\n")
      else:
        stdout.write(" FAILED\r\n")
    when not defined(windows):
      import osproc, nativesockets

      proc socket_notification_test(): bool =
        proc create_test_socket(): SocketHandle = 
          var sock = posix.socket(posix.AF_INET, posix.SOCK_STREAM,
                                  posix.IPPROTO_TCP)
          var x: int = fcntl(sock, F_GETFL, 0)
          if x == -1: raiseOSError(osLastError())
          else:
            var mode = x or O_NONBLOCK
            if fcntl(sock, F_SETFL, mode) == -1:
              raiseOSError(osLastError())
          result = sock

        var client_message = "SERVER HELLO =>"
        var server_message = "CLIENT HELLO"
        var buffer : array[128, char]

        var selector = newSelector()
        var client_socket = create_test_socket()
        var server_socket = create_test_socket()

        #echo("client socket = " & $client_socket.int)
        #echo("server socket = " & $server_socket.int)

        selector.registerHandle(server_socket, EVENT_READ, nil)
        selector.registerHandle(client_socket, EVENT_WRITE, nil)

        var option : int32 = 1
        if setsockopt(server_socket, cint(SOL_SOCKET), cint(SO_REUSEADDR),
                      addr(option), sizeof(option).SockLen) < 0:
          raiseOSError(osLastError())

        var aiList = getAddrInfo("0.0.0.0", Port(13337))
        if bindAddr(server_socket, aiList.ai_addr,
                    aiList.ai_addrlen.Socklen) < 0'i32:
          dealloc(aiList)
          raiseOSError(osLastError())
        discard server_socket.listen()
        dealloc(aiList)

        aiList = getAddrInfo("127.0.0.1", Port(13337))
        discard posix.connect(client_socket, aiList.ai_addr,
                              aiList.ai_addrlen.Socklen)
        dealloc(aiList)
        var rc1 = selector.select(100)
        assert(len(rc1) == 2)

        var sockAddress: SockAddr
        var addrLen = sizeof(sockAddress).Socklen
        var server2_socket = accept(server_socket,
                                    cast[ptr SockAddr](addr(sockAddress)),
                                    addr(addrLen))
        assert(server2_socket != osInvalidSocket)
        #echo("server2_socket = " & $server2_socket.int)
        selector.registerHandle(server2_socket, EVENT_READ, nil)

        if posix.send(client_socket, addr(client_message[0]),
                      len(client_message), 0) == -1:
          raiseOSError(osLastError())

        selector.updateHandle(client_socket, EVENT_READ)

        var rc2 = selector.select(100)
        assert(len(rc2) == 1)

        var read_count = posix.recv(server2_socket, addr (buffer[0]), 128, 0)
        if read_count == -1:
          raiseOSError(osLastError())

        assert(read_count == len(client_message))
        var test1 = true
        for i in 0..<read_count:
          if client_message[i] != buffer[i]:
            test1 = false
            break
        assert(test1)

        selector.updateHandle(server2_socket, EVENT_WRITE)
        var rc3 = selector.select(0)
        assert(len(rc3) == 1)
        if posix.send(server2_socket, addr(server_message[0]),
                      len(server_message), 0) == -1:
          raiseOSError(osLastError())
        selector.updateHandle(server2_socket, EVENT_READ)

        var rc4 = selector.select(100)
        assert(len(rc4) == 1)
        read_count = posix.recv(client_socket, addr(buffer[0]), 128, 0)
        if read_count == -1:
          raiseOSError(osLastError())

        assert(read_count == len(server_message))
        var test2 = true
        for i in 0..<read_count:
          if server_message[i] != buffer[i]:
            test2 = false
            break
        assert(test2)

        selector.unregister(server_socket)
        selector.unregister(server2_socket)
        selector.unregister(client_socket)
        discard posix.close(server_socket)
        discard posix.close(server2_socket)
        discard posix.close(client_socket)
        close(selector)
        result = true
     
      proc event_notification_test(): bool =
        var selector = newSelector()
        var event = selector.newEvent()
        when hasThreadSupport:
          var data = cast[SelectorData](allocShared0(sizeof(int)))
        else:
          var data = SelectorData()
        selector.registerEvent(event, data)
        selector.flush()
        event.setEvent()
        var rc1 = selector.select(0)
        event.setEvent()
        var rc2 = selector.select(0)
        var rc3 = selector.select(0)
        assert(len(rc1) == 1 and len(rc2) == 1 and len(rc3) == 0)
        var ev1 = rc1[0].data
        var ev2 = rc2[0].data
        assert(ev1 == data and ev2 == data)
        event.close()
        selector.close()
        result = true
      when supportedPlatform:
        proc timer_notification_test(): bool =
          var selector = newSelector()
          var timer = selector.registerTimer(100, false, nil)
          var rc1 = selector.select(140)
          var rc2 = selector.select(140)
          assert(len(rc1) == 1 and len(rc2) == 1)
          selector.unregister(timer)
          selector.flush()
          selector.registerTimer(100, true, nil)
          var rc3 = selector.select(120)
          var rc4 = selector.select(120)
          assert(len(rc3) == 1 and len(rc4) == 0)
          selector.close()
          result = true
        proc process_notification_test(): bool =
          var selector = newSelector()
          var process2 = startProcess("/bin/sleep", "", ["2"], nil,
                               {poStdErrToStdOut, poUsePath})
          discard startProcess("/bin/sleep", "", ["1"], nil,
                               {poStdErrToStdOut, poUsePath})

          selector.registerProcess(process2.processID, nil)
          var rc1 = selector.select(3000)
          var rc2 = selector.select(3000)
          var r = len(rc1) + len(rc2)
          assert(r == 1)
          result = true
        proc signal_notification_test(): bool =
          var sigset1n, sigset1o, sigset2n, sigset2o: Sigset
          var pid = posix.getpid()

          discard sigemptyset(sigset1n)
          discard sigemptyset(sigset1o)
          discard sigemptyset(sigset2n)
          discard sigemptyset(sigset2o)

          when hasThreadSupport:
            if pthread_sigmask(SIG_BLOCK, sigset1n, sigset1o) == -1:
              raiseOSError(osLastError())
          else:
            if sigprocmask(SIG_BLOCK, sigset1n, sigset1o) == -1:
              raiseOSError(osLastError())

          var selector = newSelector()
          var s1 = selector.registerSignal(SIGUSR1, nil)
          var s2 = selector.registerSignal(SIGUSR2, nil)
          var s3 = selector.registerSignal(SIGTERM, nil)
          selector.flush()

          posix.signal(SIGUSR1, SIG_IGN)
          posix.signal(SIGUSR2, SIG_IGN)
          posix.signal(SIGTERM, SIG_IGN)

          discard posix.kill(pid, SIGUSR1)
          discard posix.kill(pid, SIGUSR2)
          discard posix.kill(pid, SIGTERM)
          var rc = selector.select(0)
          selector.unregister(s1)
          selector.unregister(s2)
          selector.unregister(s3)

          when hasThreadSupport:
            if pthread_sigmask(SIG_BLOCK, sigset2n, sigset2o) == -1:
              raiseOSError(osLastError())
          else:
            if sigprocmask(SIG_BLOCK, sigset2n, sigset2o) == -1:
              raiseOSError(osLastError())

          assert(len(rc) == 3)
          assert(equalMem(addr sigset1o, addr sigset2o, sizeof(Sigset)))
          result = true

      processTest("Socket notification test...", socket_notification_test())
      processTest("User event notification test...", event_notification_test())
      when supportedPlatform:
        processTest("Timer notification test...", timer_notification_test())
        processTest("Process notification test...", process_notification_test())
        processTest("Signal notification test...", signal_notification_test())
    else:
      import nativesockets

      proc socket_notification_test(): bool =
        proc create_test_socket(): SocketHandle = 
          var sock = newNativeSocket()
          setBlocking(sock, false)
          result = sock

        var client_message = "SERVER HELLO =>"
        var server_message = "CLIENT HELLO"
        var buffer : array[128, char]

        var selector = newSelector()
        var client_socket = create_test_socket()
        var server_socket = create_test_socket()

        selector.registerHandle(server_socket, EVENT_READ, nil)
        selector.registerHandle(client_socket, EVENT_WRITE, nil)

        var option : int32 = 1
        if setsockopt(server_socket, cint(SOL_SOCKET), cint(SO_REUSEADDR),
                      addr(option), sizeof(option).SockLen) < 0:
          raiseOSError(osLastError())

        var aiList = getAddrInfo("0.0.0.0", Port(13337))
        if bindAddr(server_socket, aiList.ai_addr,
                    aiList.ai_addrlen.Socklen) < 0'i32:
          dealloc(aiList)
          raiseOSError(osLastError())
        discard server_socket.listen()
        dealloc(aiList)

        aiList = getAddrInfo("127.0.0.1", Port(13337))
        discard connect(client_socket, aiList.ai_addr,
                        aiList.ai_addrlen.Socklen)
        dealloc(aiList)
        # for some reason Windows select doesn't return both
        # descriptors from first call, so we need to make 2 calls
        discard selector.select(100)
        var rcm = selector.select(100)
        assert(len(rcm) == 2)

        var sockAddress = SockAddr()
        var addrLen = sizeof(sockAddress).Socklen
        var server2_socket = accept(server_socket,
                                    cast[ptr SockAddr](addr(sockAddress)),
                                    addr(addrLen))
        assert(server2_socket != osInvalidSocket)
        selector.registerHandle(server2_socket, EVENT_READ, nil)

        if send(client_socket, cast[pointer](addr(client_message[0])),
                cint(len(client_message)), 0) == -1:
          raiseOSError(osLastError())

        selector.updateHandle(client_socket, EVENT_READ)

        var rc2 = selector.select(0)
        assert(len(rc2) == 1)

        var read_count = recv(server2_socket, addr (buffer[0]), 128, 0)
        if read_count == -1:
          raiseOSError(osLastError())

        assert(read_count == len(client_message))
        var test1 = true
        for i in 0..<read_count:
          if client_message[i] != buffer[i]:
            test1 = false
            break
        assert(test1)

        if send(server2_socket, cast[pointer](addr(server_message[0])),
                      cint(len(server_message)), 0) == -1:
          raiseOSError(osLastError())

        var rc3 = selector.select(0)
        assert(len(rc3) == 1)
        read_count = recv(client_socket, addr(buffer[0]), 128, 0)
        if read_count == -1:
          raiseOSError(osLastError())

        assert(read_count == len(server_message))
        var test2 = true
        for i in 0..<read_count:
          if server_message[i] != buffer[i]:
            test2 = false
            break
        assert(test2)

        selector.unregister(server_socket)
        selector.unregister(server2_socket)
        selector.unregister(client_socket)
        close(server_socket)
        close(server2_socket)
        close(client_socket)
        close(selector)
        result = true
      proc event_notification_test(): bool =
        var selector = newSelector()
        var event = selector.newEvent()
        event.setEvent()
        var rc1 = selector.select(0)
        event.setEvent()
        var rc2 = selector.select(0)
        var rc3 = selector.select(0)
        assert(len(rc1) == 1 and len(rc2) == 1 and len(rc3) == 0)
        var ev1 = cast[SelectEvent](rc1[0].data)
        var ev2 = cast[SelectEvent](rc2[0].data)
        assert(ev1 == event and ev2 == event)
        event.close()
        selector.close()
        result = true

      processTest("Socket notification test...", socket_notification_test())
      processTest("User event notification test...", event_notification_test())