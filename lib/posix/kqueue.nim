#
#
#            Nim's Runtime Library
#        (c) Copyright 2015 Adam Strzelecki
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

{.deadCodeElim:on.}

from posix import Timespec

# Filters:
const
  EVFILT_READ*     = -1
  EVFILT_WRITE*    = -2
  EVFILT_AIO*      = -3
  EVFILT_VNODE*    = -4
  EVFILT_PROC*     = -5
  EVFILT_SIGNAL*   = -6
  EVFILT_TIMER*    = -7
  EVFILT_MACHPORT* = -8
  EVFILT_FS*       = -9
  EVFILT_USER*     = -10
  # -11 is unused
  EVFILT_VM*       = -12

# Actions:
const
  EV_ADD*      = 0x0001 ## Add event to queue (implies enable).
                        ## Re-adding an existing element modifies it.
  EV_DELETE*   = 0x0002 ## Delete event from queue.
  EV_ENABLE*   = 0x0004 ## Enable event.
  EV_DISABLE*  = 0x0008 ## Disable event (not reported).

# Flags:
const
  EV_ONESHOT*  = 0x0010 ## Only report one occurrence.
  EV_CLEAR*    = 0x0020 ## Clear event state after reporting.
  EV_RECEIPT*  = 0x0040 ## Force EV_ERROR on success, data == 0
  EV_DISPATCH* = 0x0080 ## Disable event after reporting.

# Return values:
const
  EV_EOF*      = 0x8000 ## EOF detected
  EV_ERROR*    = 0x4000 ## Error, data contains errno

type
  KEvent* {.importc: "struct kevent",
            header: "<sys/event.h>", pure, final.} = object
    ident*: cuint    ## identifier for this event  (uintptr_t)
    filter*: cshort  ## filter for event
    flags*: cushort  ## general flags
    fflags*: cuint   ## filter-specific flags
    data*: cuint     ## filter-specific data  (intptr_t)
    #udata*: ptr void ## opaque user data identifier

proc kqueue*(): cint {.importc: "kqueue", header: "<sys/event.h>".}
  ## Creates new queue and returns its descriptor.

proc kevent*(kqFD: cint,
             changelist: ptr KEvent, nchanges: cint,
             eventlist: ptr KEvent, nevents: cint, timeout: ptr Timespec): cint
     {.importc: "kevent", header: "<sys/event.h>".}
  ## Manipulates queue for given ``kqFD`` descriptor.

proc EV_SET*(event: ptr KEvent, ident: cuint, filter: cshort, flags: cushort,
             fflags: cuint, data: cuint, udata: ptr void)
     {.importc: "EV_SET", header: "<sys/event.h>".}
  ## Fills event with given data.
