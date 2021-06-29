#
#
#            Nim's Runtime Library
#        (c) Copyright 2016 Eugene Kabanov
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

from posix import Timespec

when defined(macosx) or defined(freebsd) or defined(openbsd) or
     defined(dragonfly):
  const
    EVFILT_READ*     = -1
    EVFILT_WRITE*    = -2
    EVFILT_AIO*      = -3 ## attached to aio requests
    EVFILT_VNODE*    = -4 ## attached to vnodes
    EVFILT_PROC*     = -5 ## attached to struct proc
    EVFILT_SIGNAL*   = -6 ## attached to struct proc
    EVFILT_TIMER*    = -7 ## timers
elif defined(netbsd):
  const
    EVFILT_READ*     = 0
    EVFILT_WRITE*    = 1
    EVFILT_AIO*      = 2 ## attached to aio requests
    EVFILT_VNODE*    = 3 ## attached to vnodes
    EVFILT_PROC*     = 4 ## attached to struct proc
    EVFILT_SIGNAL*   = 5 ## attached to struct proc
    EVFILT_TIMER*    = 6 ## timers (in ms)
when defined(macosx):
  const
    EVFILT_MACHPORT* = -8  ## Mach portsets
    EVFILT_FS*       = -9  ## filesystem events
    EVFILT_USER*     = -10 ## user events
    EVFILT_VM        = -12 ## virtual memory events
elif defined(freebsd):
  const
    EVFILT_FS*       = -9  ## filesystem events
    EVFILT_LIO*      = -10 ## attached to lio requests
    EVFILT_USER*     = -11 ## user events
elif defined(dragonfly):
  const
    EVFILT_EXCEPT*   = -8  ## exceptional conditions
    EVFILT_USER*     = -9  ## user events
    EVFILT_FS*       = -10 ## filesystem events

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

  EV_SYSFLAGS* = 0xF000 ## Reserved by system
  EV_DROP*     = 0x1000 ## Not should be dropped
  EV_FLAG1*    = 0x2000 ## Filter-specific flag

# Return values:
const
  EV_EOF*      = 0x8000 ## EOF detected
  EV_ERROR*    = 0x4000 ## Error, data contains errno
  EV_NODATA*   = 0x1000 ## EOF and no more data

when defined(macosx) or defined(freebsd) or defined(dragonfly):
  # EVFILT_USER is not supported by OpenBSD and NetBSD
  #
  # data/hint flags/masks for EVFILT_USER, shared with userspace
  #
  # On input, the top two bits of fflags specifies how the lower twenty four
  # bits should be applied to the stored value of fflags.
  #
  # On output, the top two bits will always be set to NOTE_FFNOP and the
  # remaining twenty four bits will contain the stored fflags value.
  const
    NOTE_FFNOP*      = 0x00000000'u32 ## ignore input fflags
    NOTE_FFAND*      = 0x40000000'u32 ## AND fflags
    NOTE_FFOR*       = 0x80000000'u32 ## OR fflags
    NOTE_FFCOPY*     = 0xc0000000'u32 ## copy fflags
    NOTE_FFCTRLMASK* = 0xc0000000'u32 ## masks for operations
    NOTE_FFLAGSMASK* = 0x00ffffff'u32

    NOTE_TRIGGER*    = 0x01000000'u32 ## Cause the event to be triggered
                                      ## for output.

# data/hint flags for EVFILT_{READ|WRITE}, shared with userspace
const
  NOTE_LOWAT*      = 0x0001 ## low water mark

# data/hint flags for EVFILT_VNODE, shared with userspace
const
  NOTE_DELETE*     = 0x0001 ## vnode was removed
  NOTE_WRITE*      = 0x0002 ## data contents changed
  NOTE_EXTEND*     = 0x0004 ## size increased
  NOTE_ATTRIB*     = 0x0008 ## attributes changed
  NOTE_LINK*       = 0x0010 ## link count changed
  NOTE_RENAME*     = 0x0020 ## vnode was renamed
  NOTE_REVOKE*     = 0x0040 ## vnode access was revoked

# data/hint flags for EVFILT_PROC, shared with userspace
const
  NOTE_EXIT*       = 0x80000000'u32 ## process exited
  NOTE_FORK*       = 0x40000000'u32 ## process forked
  NOTE_EXEC*       = 0x20000000'u32 ## process exec'd
  NOTE_PCTRLMASK*  = 0xf0000000'u32 ## mask for hint bits
  NOTE_PDATAMASK*  = 0x000fffff'u32 ## mask for pid

# additional flags for EVFILT_PROC
const
  NOTE_TRACK*      = 0x00000001'u32 ## follow across forks
  NOTE_TRACKERR*   = 0x00000002'u32 ## could not track child
  NOTE_CHILD*      = 0x00000004'u32 ## am a child process

when defined(macosx) or defined(freebsd):
  # additional flags for EVFILE_TIMER
  const
    NOTE_SECONDS*    = 0x00000001'u32 ## data is seconds
    NOTE_MSECONDS*   = 0x00000002'u32 ## data is milliseconds
    NOTE_USECONDS*   = 0x00000004'u32 ## data is microseconds
    NOTE_NSECONDS*   = 0x00000008'u32 ## data is nanoseconds
else:
  # NetBSD and OpenBSD doesn't support NOTE_{TIME} constants, but
  # support EVFILT_TIMER with granularity of milliseconds.
  const
    NOTE_MSECONDS*   = 0x00000000'u32

type
  ## This define not fully satisfy NetBSD "struct kevent"
  ## but it works and tested.
  KEvent* {.importc: "struct kevent",
            header: """#include <sys/types.h>
                       #include <sys/event.h>
                       #include <sys/time.h>""", pure, final.} = object
    ident*  : uint     ## identifier for this event  (uintptr_t)
    filter* : cshort   ## filter for event
    flags*  : cushort  ## general flags
    fflags* : cuint    ## filter-specific flags
    data*   : int      ## filter-specific data  (intptr_t)
    udata*  : pointer  ## opaque user data identifier

proc kqueue*(): cint {.importc: "kqueue", header: "<sys/event.h>".}
  ## Creates new queue and returns its descriptor.

proc kevent*(kqFD: cint,
             changelist: ptr KEvent, nchanges: cint,
             eventlist: ptr KEvent, nevents: cint, timeout: ptr Timespec): cint
     {.importc: "kevent", header: "<sys/event.h>".}
  ## Manipulates queue for given `kqFD` descriptor.

proc EV_SET*(event: ptr KEvent, ident: uint, filter: cshort, flags: cushort,
             fflags: cuint, data: int, udata: pointer)
     {.importc: "EV_SET", header: "<sys/event.h>".}
  ## Fills event with given data.
