#
#
#            Nim's Runtime Library
#        (c) Copyright 2020 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

# we need to cache current threadId to not perform syscall all the time
var threadId {.threadvar.}: int

when defined(windows):
  proc getCurrentThreadId(): int32 {.
    stdcall, dynlib: "kernel32", importc: "GetCurrentThreadId".}

  proc getThreadId*(): int =
    ## Gets the ID of the currently running thread.
    if threadId == 0:
      threadId = int(getCurrentThreadId())
    result = threadId

elif defined(linux):
  proc syscall(arg: clong): clong {.varargs, importc: "syscall", header: "<unistd.h>".}
  when defined(amd64):
    const NR_gettid = clong(186)
  else:
    var NR_gettid {.importc: "__NR_gettid", header: "<sys/syscall.h>".}: clong

  proc getThreadId*(): int =
    ## Gets the ID of the currently running thread.
    if threadId == 0:
      threadId = int(syscall(NR_gettid))
    result = threadId

elif defined(dragonfly):
  proc lwp_gettid(): int32 {.importc, header: "unistd.h".}

  proc getThreadId*(): int =
    ## Gets the ID of the currently running thread.
    if threadId == 0:
      threadId = int(lwp_gettid())
    result = threadId

elif defined(openbsd):
  proc getthrid(): int32 {.importc: "getthrid", header: "<unistd.h>".}

  proc getThreadId*(): int =
    ## Gets the ID of the currently running thread.
    if threadId == 0:
      threadId = int(getthrid())
    result = threadId

elif defined(netbsd):
  proc lwp_self(): int32 {.importc: "_lwp_self", header: "<lwp.h>".}

  proc getThreadId*(): int =
    ## Gets the ID of the currently running thread.
    if threadId == 0:
      threadId = int(lwp_self())
    result = threadId

elif defined(freebsd):
  proc syscall(arg: cint, arg0: ptr cint): cint {.varargs, importc: "syscall", header: "<unistd.h>".}
  var SYS_thr_self {.importc:"SYS_thr_self", header:"<sys/syscall.h>".}: cint

  proc getThreadId*(): int =
    ## Gets the ID of the currently running thread.
    var tid = 0.cint
    if threadId == 0:
      discard syscall(SYS_thr_self, addr tid)
      threadId = tid
    result = threadId

elif defined(macosx):
  proc syscall(arg: cint): cint {.varargs, importc: "syscall", header: "<unistd.h>".}
  var SYS_thread_selfid {.importc:"SYS_thread_selfid", header:"<sys/syscall.h>".}: cint

  proc getThreadId*(): int =
    ## Gets the ID of the currently running thread.
    if threadId == 0:
      threadId = int(syscall(SYS_thread_selfid))
    result = threadId

elif defined(solaris):
  type thread_t {.importc: "thread_t", header: "<thread.h>".} = distinct int
  proc thr_self(): thread_t {.importc, header: "<thread.h>".}

  proc getThreadId*(): int =
    ## Gets the ID of the currently running thread.
    if threadId == 0:
      threadId = int(thr_self())
    result = threadId

elif defined(haiku):
  type thr_id {.importc: "thread_id", header: "<OS.h>".} = distinct int32
  proc find_thread(name: cstring): thr_id {.importc, header: "<OS.h>".}

  proc getThreadId*(): int =
    ## Gets the ID of the currently running thread.
    if threadId == 0:
      threadId = int(find_thread(nil))
    result = threadId
