import posix

## Flags of `clone` syscall.
## See `clone syscall manual
## <https://man7.org/linux/man-pages/man2/clone.2.html>`_ for more information.
const
  CSIGNAL* = 0x000000FF'i32
  CLONE_VM* = 0x00000100'i32
  CLONE_FS* = 0x00000200'i32
  CLONE_FILES* = 0x00000400'i32
  CLONE_SIGHAND* = 0x00000800'i32
  CLONE_PIDFD* = 0x00001000'i32
  CLONE_PTRACE* = 0x00002000'i32
  CLONE_VFORK* = 0x00004000'i32
  CLONE_PARENT* = 0x00008000'i32
  CLONE_THREAD* = 0x00010000'i32
  CLONE_NEWNS* = 0x00020000'i32
  CLONE_SYSVSEM* = 0x00040000'i32
  CLONE_SETTLS* = 0x00080000'i32
  CLONE_PARENT_SETTID* = 0x00100000'i32
  CLONE_CHILD_CLEARTID* = 0x00200000'i32
  CLONE_DETACHED* = 0x00400000'i32
  CLONE_UNTRACED* = 0x00800000'i32
  CLONE_CHILD_SETTID* = 0x01000000'i32
  CLONE_NEWCGROUP* = 0x02000000'i32
  CLONE_NEWUTS* = 0x04000000'i32
  CLONE_NEWIPC* = 0x08000000'i32
  CLONE_NEWUSER* = 0x10000000'i32
  CLONE_NEWPID* = 0x20000000'i32
  CLONE_NEWNET* = 0x40000000'i32
  CLONE_IO* = 0x80000000'i32
  CLONE_STOPPED* {.deprecated.} = 0x02000000'i32

# fn should be of type proc (a2: pointer) {.cdecl.}
proc clone*(fn: pointer; child_stack: pointer; flags: cint;
            arg: pointer; ptid: ptr Pid; tls: pointer;
            ctid: ptr Pid): cint {.importc, header: "<sched.h>".}

proc pipe2*(a: array[0..1, cint], flags: cint): cint {.importc, header: "<unistd.h>".}
