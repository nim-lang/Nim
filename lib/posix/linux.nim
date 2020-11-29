import posix

const
  CSIGNAL* = 0x000000FF
  CLONE_VM* = 0x00000100
  CLONE_FS* = 0x00000200
  CLONE_FILES* = 0x00000400
  CLONE_SIGHAND* = 0x00000800
  CLONE_PTRACE* = 0x00002000
  CLONE_VFORK* = 0x00004000
  CLONE_PARENT* = 0x00008000
  CLONE_THREAD* = 0x00010000
  CLONE_NEWNS* = 0x00020000
  CLONE_SYSVSEM* = 0x00040000
  CLONE_SETTLS* = 0x00080000
  CLONE_PARENT_SETTID* = 0x00100000
  CLONE_CHILD_CLEARTID* = 0x00200000
  CLONE_DETACHED* = 0x00400000
  CLONE_UNTRACED* = 0x00800000
  CLONE_CHILD_SETTID* = 0x01000000
  CLONE_STOPPED* = 0x02000000

# fn should be of type proc (a2: pointer): void {.cdecl.}
proc clone*(fn: pointer; child_stack: pointer; flags: cint;
            arg: pointer; ptid: ptr Pid; tls: pointer;
            ctid: ptr Pid): cint {.importc, header: "<sched.h>".}

proc pipe2*(a: array[0..1, cint], flags: cint): cint {.importc, header: "<unistd.h>".}
