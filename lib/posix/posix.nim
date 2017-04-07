#
#
#            Nim's Runtime Library
#        (c) Copyright 2012 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

# Until std_arg!!
# done: ipc, pwd, stat, semaphore, sys/types, sys/utsname, pthread, unistd,
# statvfs, mman, time, wait, signal, nl_types, sched, spawn, select, ucontext,
# net/if, sys/socket, sys/uio, netinet/in, netinet/tcp, netdb

## This is a raw POSIX interface module. It does not not provide any
## convenience: cstrings are used instead of proper Nim strings and
## return codes indicate errors. If you want exceptions
## and a proper Nim-like interface, use the OS module or write a wrapper.

## Coding conventions:
## ALL types are named the same as in the POSIX standard except that they start
## with 'T' or 'P' (if they are pointers) and without the '_t' suffix to be
## consistent with Nim conventions. If an identifier is a Nim keyword
## the \`identifier\` notation is used.
##
## This library relies on the header files of your C compiler. The
## resulting C code will just ``#include <XYZ.h>`` and *not* define the
## symbols declared here.

when defined(linux) and defined(amd64):
  include posix_linux_amd64
else:
  include posix_other
