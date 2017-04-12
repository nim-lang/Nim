type
  Tflock* {.importc: "struct flock", final, pure,
            header: "<fcntl.h>".} = object ## flock type
    l_type*: cshort   ## Type of lock; F_RDLCK, F_WRLCK, F_UNLCK.
    l_whence*: cshort ## Flag for starting offset.
    l_start*: Off     ## Relative offset in bytes.
    l_len*: Off       ## Size; if 0 then until EOF.
    l_pid*: Pid      ## Process ID of the process holding the lock;
                      ## returned with F_GETLK.
