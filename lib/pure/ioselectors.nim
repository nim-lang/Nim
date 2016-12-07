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
## Fully supported OS: MacOSX, FreeBSD, OpenBSD, NetBSD, Linux (except
## for Android).
##
## Partially supported OS: Windows (only sockets and user events),
## Solaris (files, sockets, handles and user events).
## Android (files, sockets, handles and user events).
##
## TODO: ``/dev/poll``, ``event ports`` and filesystem events.

import os

const hasThreadSupport = compileOption("threads") and defined(threadsafe)

const ioselSupportedPlatform* = defined(macosx) or defined(freebsd) or
                                defined(netbsd) or defined(openbsd) or
                                (defined(linux) and not defined(android))
  ## This constant is used to determine whether the destination platform is
  ## fully supported by ``ioselectors`` module.

const bsdPlatform = defined(macosx) or defined(freebsd) or
                    defined(netbsd) or defined(openbsd)


when defined(nimdoc):
  type
    Selector*[T] = ref object
      ## An object which holds descriptors to be checked for read/write status

    Event* {.pure.} = enum
      ## An enum which hold event types
      Read,        ## Descriptor is available for read
      Write,       ## Descriptor is available for write
      Timer,       ## Timer descriptor is completed
      Signal,      ## Signal is raised
      Process,     ## Process is finished
      Vnode,       ## BSD specific file change happens
      User,        ## User event is raised
      Error,       ## Error happens while waiting, for descriptor
      VnodeWrite,  ## NOTE_WRITE (BSD specific, write to file occurred)
      VnodeDelete, ## NOTE_DELETE (BSD specific, unlink of file occurred)
      VnodeExtend, ## NOTE_EXTEND (BSD specific, file extended)
      VnodeAttrib, ## NOTE_ATTRIB (BSD specific, file attributes changed)
      VnodeLink,   ## NOTE_LINK (BSD specific, file link count changed)
      VnodeRename, ## NOTE_RENAME (BSD specific, file renamed)
      VnodeRevoke  ## NOTE_REVOKE (BSD specific, file revoke occurred)

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

  proc registerVnode*[T](s: Selector[T], fd: cint, events: set[Event],
                         data: T) =
    ## Registers selector BSD/MacOSX specific vnode events for file
    ## descriptor ``fd`` and events ``events``.
    ## ``data`` application-defined data, which to be passed, when
    ## vnode event happens.
    ##
    ## This function is supported only by BSD and MacOSX.

  proc newSelectEvent*(): SelectEvent =
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
    ## This function is useful only for BSD and MacOS, because
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
  when hasThreadSupport:
    import locks

    type
      SharedArray {.unchecked.}[T] = array[0..100, T]

    proc allocSharedArray[T](nsize: int): ptr SharedArray[T] =
      result = cast[ptr SharedArray[T]](allocShared0(sizeof(T) * nsize))

    proc deallocSharedArray[T](sa: ptr SharedArray[T]) =
      deallocShared(cast[pointer](sa))
  type
    Event* {.pure.} = enum
      Read, Write, Timer, Signal, Process, Vnode, User, Error, Oneshot,
      VnodeWrite, VnodeDelete, VnodeExtend, VnodeAttrib, VnodeLink,
      VnodeRename, VnodeRevoke

    ReadyKey*[T] = object
      fd* : int
      events*: set[Event]
      data*: T

    SelectorKey[T] = object
      ident: int
      events: set[Event]
      param: int
      key: ReadyKey[T]

  when not defined(windows):
    import posix
    proc setNonBlocking(fd: cint) {.inline.} =
      var x = fcntl(fd, F_GETFL, 0)
      if x == -1:
        raiseOSError(osLastError())
      else:
        var mode = x or O_NONBLOCK
        if fcntl(fd, F_SETFL, mode) == -1:
          raiseOSError(osLastError())

    template setKey(s, pident, pkeyfd, pevents, pparam, pdata) =
      var skey = addr(s.fds[pident])
      skey.ident = pident
      skey.events = pevents
      skey.param = pparam
      skey.key.fd = pkeyfd
      skey.key.data = pdata

  when ioselSupportedPlatform:
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

  when defined(linux):
    include ioselects/ioselectors_epoll
  elif bsdPlatform:
    include ioselects/ioselectors_kqueue
  elif defined(windows):
    include ioselects/ioselectors_select
  elif defined(solaris):
    include ioselects/ioselectors_poll # need to replace it with event ports
  else:
    include ioselects/ioselectors_poll
