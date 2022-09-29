#
#
#            Nim's Runtime Library
#        (c) Copyright 2013 Dominik Picheta
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

from posix import SocketHandle

const
  EPOLLIN* = 0x00000001
  EPOLLPRI* = 0x00000002
  EPOLLOUT* = 0x00000004
  EPOLLERR* = 0x00000008
  EPOLLHUP* = 0x00000010
  EPOLLRDNORM* = 0x00000040
  EPOLLRDBAND* = 0x00000080
  EPOLLWRNORM* = 0x00000100
  EPOLLWRBAND* = 0x00000200
  EPOLLMSG* = 0x00000400
  EPOLLRDHUP* = 0x00002000
  EPOLLEXCLUSIVE* = 1 shl 28
  EPOLLWAKEUP* = 1 shl 29
  EPOLLONESHOT* = 1 shl 30
  EPOLLET* = 1 shl 31

# Valid opcodes ( "op" parameter ) to issue to epoll_ctl().

const
  EPOLL_CTL_ADD* = 1          # Add a file descriptor to the interface.
  EPOLL_CTL_DEL* = 2          # Remove a file descriptor from the interface.
  EPOLL_CTL_MOD* = 3          # Change file descriptor epoll_event structure.

# https://github.com/torvalds/linux/blob/ff6992735ade75aae3e35d16b17da1008d753d28/include/uapi/linux/eventpoll.h#L77
when defined(linux) and defined(amd64):
  {.pragma: epollPacked, packed.}
else:
  {.pragma: epollPacked.}

type
  EpollData* {.importc: "epoll_data_t",
      header: "<sys/epoll.h>", pure, final, union.} = object
    `ptr`* {.importc: "ptr".}: pointer
    fd* {.importc: "fd".}: cint
    u32* {.importc: "u32".}: uint32
    u64* {.importc: "u64".}: uint64

  EpollEvent* {.importc: "struct epoll_event", header: "<sys/epoll.h>", pure, final, epollPacked.} = object
    events*: uint32 # Epoll events
    data*: EpollData # User data variable

proc epoll_create*(size: cint): cint {.importc: "epoll_create",
    header: "<sys/epoll.h>".}
  ## Creates an epoll instance.  Returns an fd for the new instance.
  ##
  ## The "size" parameter is a hint specifying the number of file
  ## descriptors to be associated with the new instance.  The fd
  ## returned by epoll_create() should be closed with close().

proc epoll_create1*(flags: cint): cint {.importc: "epoll_create1",
    header: "<sys/epoll.h>".}
  ## Same as epoll_create but with an FLAGS parameter.  The unused SIZE
  ## parameter has been dropped.

proc epoll_ctl*(epfd: cint; op: cint; fd: cint | SocketHandle; event: ptr EpollEvent): cint {.
    importc: "epoll_ctl", header: "<sys/epoll.h>".}
  ## Manipulate an epoll instance "epfd". Returns `0` in case of success,
  ## `-1` in case of error (the "errno" variable will contain the specific error code).
  ##
  ## The "op" parameter is one of the `EPOLL_CTL_*`
  ## constants defined above. The "fd" parameter is the target of the
  ## operation. The "event" parameter describes which events the caller
  ## is interested in and any associated user data.

proc epoll_wait*(epfd: cint; events: ptr EpollEvent; maxevents: cint;
                 timeout: cint): cint {.importc: "epoll_wait",
    header: "<sys/epoll.h>".}
  ## Wait for events on an epoll instance "epfd". Returns the number of
  ## triggered events returned in "events" buffer. Or -1 in case of
  ## error with the "errno" variable set to the specific error code. The
  ## "events" parameter is a buffer that will contain triggered
  ## events. The "maxevents" is the maximum number of events to be
  ## returned ( usually size of "events" ). The "timeout" parameter
  ## specifies the maximum wait time in milliseconds (-1 == infinite).
  ##
  ## This function is a cancellation point and therefore not marked with
  ## __THROW.


#proc epoll_pwait*(epfd: cint; events: ptr EpollEvent; maxevents: cint;
#                  timeout: cint; ss: ptr sigset_t): cint {.
#    importc: "epoll_pwait", header: "<sys/epoll.h>".}
# Same as epoll_wait, but the thread's signal mask is temporarily
# and atomically replaced with the one provided as parameter.
#
# This function is a cancellation point and therefore not marked with
# __THROW.
