discard """
  exitcode: 1
  outputsub: "SIGABRT: Abnormal termination."
"""

# Boehm calls `abort` when it finds a double free, while it still holds its
# allocator lock. The signal handler must write its message and end the
# program instead of waiting for that lock (#26513).

proc alarm(seconds: cuint): cuint {.importc, header: "<unistd.h>".}

# testament does not stop a test that hangs; if the handler waits, SIGALRM
# ends the program without the message above
discard alarm(30)

let p = allocShared(1_000_000)
deallocShared(p)
deallocShared(p)
