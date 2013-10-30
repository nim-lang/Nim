#
#
#            Nimrod's Runtime Library
#        (c) Copyright 2010 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## This module is a wrapper for the TCL programming language.

#
#  tcl.h --
#
#  This header file describes the externally-visible facilities of the Tcl
#  interpreter.
#
#  Translated to Pascal Copyright (c) 2002 by Max Artemev
#  aka Bert Raccoon (bert@furry.ru, bert_raccoon@freemail.ru)
#
#
#  Copyright (c) 1998-2000 by Scriptics Corporation.
#  Copyright (c) 1994-1998 Sun Microsystems, Inc.
#  Copyright (c) 1993-1996 Lucent Technologies.
#  Copyright (c) 1987-1994 John Ousterhout, The Regents of the
#                          University of California, Berkeley.
#
#  ***********************************************************************
#  This program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
#  ***********************************************************************
#

{.deadCodeElim: on.}

when defined(WIN32):
  const
    dllName = "tcl(85|84|83|82|81|80).dll"
elif defined(macosx):
  const
    dllName = "libtcl(8.5|8.4|8.3|8.2|8.1).dylib"
else:
  const
    dllName = "libtcl(8.5|8.4|8.3|8.2|8.1).so(|.1|.0)"
const
  TCL_DESTROYED* = 0xDEADDEAD
  TCL_OK* = 0
  TCL_ERROR* = 1
  TCL_RETURN* = 2
  TCL_BREAK* = 3
  TCL_CONTINUE* = 4
  RESULT_SIZE* = 200
  MAX_ARGV* = 0x00007FFF
  VERSION_MAJOR* = 0
  VERSION_MINOR* = 0
  NO_EVAL* = 0x00010000
  EVAL_GLOBAL* = 0x00020000 # Flag values passed to variable-related proc
  GLOBAL_ONLY* = 1
  NAMESPACE_ONLY* = 2
  APPEND_VALUE* = 4
  LIST_ELEMENT* = 8
  TRACE_READS* = 0x00000010
  TRACE_WRITES* = 0x00000020
  TRACE_UNSETS* = 0x00000040
  TRACE_DESTROYED* = 0x00000080
  INTERP_DESTROYED* = 0x00000100
  LEAVE_ERR_MSG* = 0x00000200
  PARSE_PART1* = 0x00000400 # Types for linked variables: *
  LINK_INT* = 1
  LINK_DOUBLE* = 2
  LINK_BOOLEAN* = 3
  LINK_STRING* = 4
  LINK_READ_ONLY* = 0x00000080
  SMALL_HASH_TABLE* = 4   # Hash Table *
  STRING_KEYS* = 0
  ONE_WORD_KEYS* = 1      # Const/enums Tcl_QueuePosition *

  QUEUE_TAIL* = 0
  QUEUE_HEAD* = 1
  QUEUE_MARK* = 2         # Tcl_QueuePosition;
                          # Event Flags
  DONT_WAIT* = 1 shl 1
  WINDOW_EVENTS* = 1 shl 2
  FILE_EVENTS* = 1 shl 3
  TIMER_EVENTS* = 1 shl 4
  IDLE_EVENTS* = 1 shl 5  # WAS 0x10 ???? *
  ALL_EVENTS* = not DONT_WAIT
  VOLATILE* = 1
  TCL_STATIC* = 0
  DYNAMIC* = 3            # Channel
  TCL_STDIN* = 1 shl 1
  TCL_STDOUT* = 1 shl 2
  TCL_STDERR* = 1 shl 3
  ENFORCE_MODE* = 1 shl 4
  READABLE* = 1 shl 1
  WRITABLE* = 1 shl 2
  EXCEPTION* = 1 shl 3    # POSIX *
  EPERM* = 1 # Operation not permitted; only the owner of the file (or other
             # resource) or processes with special privileges can perform the
             # operation.
             #
  ENOENT* = 2 # No such file or directory.  This is a "file doesn't exist" error
              # for ordinary files that are referenced in contexts where they are
              # expected to already exist.
              #
  ESRCH* = 3                  # No process matches the specified process ID. *
  EINTR* = 4 # Interrupted function call; an asynchronous signal occurred and
             # prevented completion of the call.  When this happens, you should
             # try the call again.
             #
  EIO* = 5                    # Input/output error; usually used for physical read or write errors. *
  ENXIO* = 6 # No such device or address.  The system tried to use the device
             # represented by a file you specified, and it couldn't find the
             # device.  This can mean that the device file was installed
             # incorrectly, or that the physical device is missing or not
             # correctly attached to the computer.
             #
  E2BIG* = 7 # Argument list too long; used when the arguments passed to a new
             # program being executed with one of the `exec' functions (*note
             # Executing a File::.) occupy too much memory space.  This condition
             # never arises in the GNU system.
             #
  ENOEXEC* = 8 # Invalid executable file format.  This condition is detected by the
               # `exec' functions; see *Note Executing a File::.
               #
  EBADF* = 9 # Bad file descriptor; for example, I/O on a descriptor that has been
             # closed or reading from a descriptor open only for writing (or vice
             # versa).
             #
  ECHILD* = 10 # There are no child processes.  This error happens on operations
               # that are supposed to manipulate child processes, when there aren't
               # any processes to manipulate.
               #
  EDEADLK* = 11 # Deadlock avoided; allocating a system resource would have resulted
                # in a deadlock situation.  The system does not guarantee that it
                # will notice all such situations.  This error means you got lucky
                # and the system noticed; it might just hang.  *Note File Locks::,
                # for an example.
                #
  ENOMEM* = 12 # No memory available.  The system cannot allocate more virtual
               # memory because its capacity is full.
               #
  EACCES* = 13 # Permission denied; the file permissions do not allow the attempted
               # operation.
               #
  EFAULT* = 14 # Bad address; an invalid pointer was detected.  In the GNU system,
               # this error never happens; you get a signal instead.
               #
  ENOTBLK* = 15 # A file that isn't a block special file was given in a situation
                # that requires one.  For example, trying to mount an ordinary file
                # as a file system in Unix gives this error.
                #
  EBUSY* = 16 # Resource busy; a system resource that can't be shared is already
              # in use.  For example, if you try to delete a file that is the root
              # of a currently mounted filesystem, you get this error.
              #
  EEXIST* = 17 # File exists; an existing file was specified in a context where it
               # only makes sense to specify a new file.
               #
  EXDEV* = 18 # An attempt to make an improper link across file systems was
              # detected.  This happens not only when you use `link' (*note Hard
              # Links::.) but also when you rename a file with `rename' (*note
              # Renaming Files::.).
              #
  ENODEV* = 19 # The wrong type of device was given to a function that expects a
               # particular sort of device.
               #
  ENOTDIR* = 20 # A file that isn't a directory was specified when a directory is
                # required.
                #
  EISDIR* = 21 # File is a directory; you cannot open a directory for writing, or
               # create or remove hard links to it.
               #
  EINVAL* = 22 # Invalid argument.  This is used to indicate various kinds of
               # problems with passing the wrong argument to a library function.
               #
  EMFILE* = 24 # The current process has too many files open and can't open any
               # more.  Duplicate descriptors do count toward this limit.
               #
               # In BSD and GNU, the number of open files is controlled by a
               # resource limit that can usually be increased.  If you get this
               # error, you might want to increase the `RLIMIT_NOFILE' limit or
               # make it unlimited; *note Limits on Resources::..
               #
  ENFILE* = 23 # There are too many distinct file openings in the entire system.
               # Note that any number of linked channels count as just one file
               # opening; see *Note Linked Channels::.  This error never occurs in
               # the GNU system.
               #
  ENOTTY* = 25 # Inappropriate I/O control operation, such as trying to set terminal
               # modes on an ordinary file.
               #
  ETXTBSY* = 26 # An attempt to execute a file that is currently open for writing, or
                # write to a file that is currently being executed.  Often using a
                # debugger to run a program is considered having it open for writing
                # and will cause this error.  (The name stands for "text file
                # busy".)  This is not an error in the GNU system; the text is
                # copied as necessary.
                #
  EFBIG* = 27 # File too big; the size of a file would be larger than allowed by
              # the system.
              #
  ENOSPC* = 28 # No space left on device; write operation on a file failed because
               # the disk is full.
               #
  ESPIPE* = 29                # Invalid seek operation (such as on a pipe).  *
  EROFS* = 30                 # An attempt was made to modify something on a read-only file system.  *
  EMLINK* = 31 # Too many links; the link count of a single file would become too
               # large.  `rename' can cause this error if the file being renamed
               # already has as many links as it can take (*note Renaming Files::.).
               #
  EPIPE* = 32 # Broken pipe; there is no process reading from the other end of a
              # pipe.  Every library function that returns this error code also
              # generates a `SIGPIPE' signal; this signal terminates the program
              # if not handled or blocked.  Thus, your program will never actually
              # see `EPIPE' unless it has handled or blocked `SIGPIPE'.
              #
  EDOM* = 33 # Domain error; used by mathematical functions when an argument
             # value does not fall into the domain over which the function is
             # defined.
             #
  ERANGE* = 34 # Range error; used by mathematical functions when the result value
               # is not representable because of overflow or underflow.
               #
  EAGAIN* = 35 # Resource temporarily unavailable; the call might work if you try
               # again later.  The macro `EWOULDBLOCK' is another name for `EAGAIN';
               # they are always the same in the GNU C library.
               #
  EWOULDBLOCK* = EAGAIN # In the GNU C library, this is another name for `EAGAIN' (above).
                        # The values are always the same, on every operating system.
                        # C libraries in many older Unix systems have `EWOULDBLOCK' as a
                        # separate error code.
                        #
  EINPROGRESS* = 36 # An operation that cannot complete immediately was initiated on an
                    # object that has non-blocking mode selected.  Some functions that
                    # must always block (such as `connect'; *note Connecting::.) never
                    # return `EAGAIN'.  Instead, they return `EINPROGRESS' to indicate
                    # that the operation has begun and will take some time.  Attempts to
                    # manipulate the object before the call completes return `EALREADY'.
                    # You can use the `select' function to find out when the pending
                    # operation has completed; *note Waiting for I/O::..
                    #
  EALREADY* = 37 # An operation is already in progress on an object that has
                 # non-blocking mode selected.
                 #
  ENOTSOCK* = 38              # A file that isn't a socket was specified when a socket is required.  *
  EDESTADDRREQ* = 39 # No default destination address was set for the socket.  You get
                     # this error when you try to transmit data over a connectionless
                     # socket, without first specifying a destination for the data with
                     # `connect'.
                     #
  EMSGSIZE* = 40 # The size of a message sent on a socket was larger than the
                 # supported maximum size.
                 #
  EPROTOTYPE* = 41 # The socket type does not support the requested communications
                   # protocol.
                   #
  ENOPROTOOPT* = 42 # You specified a socket option that doesn't make sense for the
                    # particular protocol being used by the socket.  *Note Socket
                    # Options::.
                    #
  EPROTONOSUPPORT* = 43 # The socket domain does not support the requested communications
                        # protocol (perhaps because the requested protocol is completely
                        # invalid.) *Note Creating a Socket::.
                        #
  ESOCKTNOSUPPORT* = 44       # The socket type is not supported.  *
  EOPNOTSUPP* = 45 # The operation you requested is not supported.  Some socket
                   # functions don't make sense for all types of sockets, and others
                   # may not be implemented for all communications protocols.  In the
                   # GNU system, this error can happen for many calls when the object
                   # does not support the particular operation; it is a generic
                   # indication that the server knows nothing to do for that call.
                   #
  EPFNOSUPPORT* = 46 # The socket communications protocol family you requested is not
                     # supported.
                     #
  EAFNOSUPPORT* = 47 # The address family specified for a socket is not supported; it is
                     # inconsistent with the protocol being used on the socket.  *Note
                     # Sockets::.
                     #
  EADDRINUSE* = 48 # The requested socket address is already in use.  *Note Socket
                   # Addresses::.
                   #
  EADDRNOTAVAIL* = 49 # The requested socket address is not available; for example, you
                      # tried to give a socket a name that doesn't match the local host
                      # name.  *Note Socket Addresses::.
                      #
  ENETDOWN* = 50              # A socket operation failed because the network was down.  *
  ENETUNREACH* = 51 # A socket operation failed because the subnet containing the remote
                    # host was unreachable.
                    #
  ENETRESET* = 52             # A network connection was reset because the remote host crashed.  *
  ECONNABORTED* = 53          # A network connection was aborted locally. *
  ECONNRESET* = 54 # A network connection was closed for reasons outside the control of
                   # the local host, such as by the remote machine rebooting or an
                   # unrecoverable protocol violation.
                   #
  ENOBUFS* = 55 # The kernel's buffers for I/O operations are all in use.  In GNU,
                # this error is always synonymous with `ENOMEM'; you may get one or
                # the other from network operations.
                #
  EISCONN* = 56 # You tried to connect a socket that is already connected.  *Note
                # Connecting::.
                #
  ENOTCONN* = 57 # The socket is not connected to anything.  You get this error when
                 # you try to transmit data over a socket, without first specifying a
                 # destination for the data.  For a connectionless socket (for
                 # datagram protocols, such as UDP), you get `EDESTADDRREQ' instead.
                 #
  ESHUTDOWN* = 58             # The socket has already been shut down.  *
  ETOOMANYREFS* = 59          # ???  *
  ETIMEDOUT* = 60 # A socket operation with a specified timeout received no response
                  # during the timeout period.
                  #
  ECONNREFUSED* = 61 # A remote host refused to allow the network connection (typically
                     # because it is not running the requested service).
                     #
  ELOOP* = 62 # Too many levels of symbolic links were encountered in looking up a
              # file name.  This often indicates a cycle of symbolic links.
              #
  ENAMETOOLONG* = 63 # Filename too long (longer than `PATH_MAX'; *note Limits for
                     # Files::.) or host name too long (in `gethostname' or
                     # `sethostname'; *note Host Identification::.).
                     #
  EHOSTDOWN* = 64             # The remote host for a requested network connection is down.  *
  EHOSTUNREACH* = 65 # The remote host for a requested network connection is not
                     # reachable.
                     #
  ENOTEMPTY* = 66 # Directory not empty, where an empty directory was expected.
                  # Typically, this error occurs when you are trying to delete a
                  # directory.
                  #
  EPROCLIM* = 67 # This means that the per-user limit on new process would be
                 # exceeded by an attempted `fork'.  *Note Limits on Resources::, for
                 # details on the `RLIMIT_NPROC' limit.
                 #
  EUSERS* = 68                # The file quota system is confused because there are too many users.  *
  EDQUOT* = 69                # The user's disk quota was exceeded.  *
  ESTALE* = 70 # Stale NFS file handle.  This indicates an internal confusion in
               # the NFS system which is due to file system rearrangements on the
               # server host.  Repairing this condition usually requires unmounting
               # and remounting the NFS file system on the local host.
               #
  EREMOTE* = 71 # An attempt was made to NFS-mount a remote file system with a file
                # name that already specifies an NFS-mounted file.  (This is an
                # error on some operating systems, but we expect it to work properly
                # on the GNU system, making this error code impossible.)
                #
  EBADRPC* = 72               # ???  *
  ERPCMISMATCH* = 73          # ???  *
  EPROGUNAVAIL* = 74          # ???  *
  EPROGMISMATCH* = 75         # ???  *
  EPROCUNAVAIL* = 76          # ???  *
  ENOLCK* = 77 # No locks available.  This is used by the file locking facilities;
               # see *Note File Locks::.  This error is never generated by the GNU
               # system, but it can result from an operation to an NFS server
               # running another operating system.
               #
  ENOSYS* = 78 # Function not implemented.  Some functions have commands or options
               # defined that might not be supported in all implementations, and
               # this is the kind of error you get if you request them and they are
               # not supported.
               #
  EFTYPE* = 79 # Inappropriate file type or format.  The file was the wrong type
               # for the operation, or a data file had the wrong format.
               # On some systems `chmod' returns this error if you try to set the
               # sticky bit on a non-directory file; *note Setting Permissions::..
               #

type
  TArgv* = cstringArray
  TClientData* = pointer
  TFreeProc* = proc (theBlock: pointer){.cdecl.}
  PInterp* = ptr TInterp
  TInterp*{.final.} = object  #  Event Definitions
    result*: cstring # Do not access this directly. Use
                     # Tcl_GetStringResult since result
                     # may be pointing to an object
    freeProc*: TFreeProc
    errorLine*: int

  TEventSetupProc* = proc (clientData: TClientData, flags: int){.cdecl.}
  TEventCheckProc* = TEventSetupProc
  PEvent* = ptr TEvent
  TEventProc* = proc (evPtr: PEvent, flags: int): int{.cdecl.}
  TEvent*{.final.} = object
    prc*: TEventProc
    nextPtr*: PEvent
    ClientData*: TObject      # ClientData is just pointer.*

  PTime* = ptr TTime
  TTime*{.final.} = object
    sec*: int32               # Seconds. *
    usec*: int32              # Microseconds. *

  TTimerToken* = pointer
  PInteger* = ptr int
  PHashTable* = ptr THashTable
  PHashEntry* = ptr THashEntry
  PPHashEntry* = ptr PHashEntry
  THashEntry*{.final.} = object
    nextPtr*: PHashEntry
    tablePtr*: PHashTable
    bucketPtr*: PPHashEntry
    clientData*: TClientData
    key*: cstring

  THashFindProc* = proc (tablePtr: PHashTable, key: cstring): PHashEntry{.
      cdecl.}
  THashCreateProc* = proc (tablePtr: PHashTable, key: cstring,
                              newPtr: PInteger): PHashEntry{.cdecl.}
  THashTable*{.final.} = object
    buckets*: ppHashEntry
    staticBuckets*: array[0..SMALL_HASH_TABLE - 1, PHashEntry]
    numBuckets*: int
    numEntries*: int
    rebuildSize*: int
    downShift*: int
    mask*: int
    keyType*: int
    findProc*: THashFindProc
    createProc*: THashCreateProc

  PHashSearch* = ptr THashSearch
  THashSearch*{.final.} = object
    tablePtr*: PHashTable
    nextIndex*: int
    nextEntryPtr*: PHashEntry

  TAppInitProc* = proc (interp: pInterp): int{.cdecl.}
  TPackageInitProc* = proc (interp: pInterp): int{.cdecl.}
  TCmdProc* = proc (clientData: TClientData, interp: pInterp, argc: int,
                    argv: TArgv): int{.cdecl.}
  TVarTraceProc* = proc (clientData: TClientData, interp: pInterp,
                         varName: cstring, elemName: cstring, flags: int): cstring{.
      cdecl.}
  TInterpDeleteProc* = proc (clientData: TClientData, interp: pInterp){.cdecl.}
  TCmdDeleteProc* = proc (clientData: TClientData){.cdecl.}
  TNamespaceDeleteProc* = proc (clientData: TClientData){.cdecl.}

const
  DSTRING_STATIC_SIZE* = 200

type
  PDString* = ptr TDString
  TDString*{.final.} = object
    str*: cstring
    len*: int
    spaceAvl*: int
    staticSpace*: array[0..DSTRING_STATIC_SIZE - 1, char]

  PChannel* = ptr TChannel
  TChannel*{.final.} = object
  TDriverBlockModeProc* = proc (instanceData: TClientData, mode: int): int{.
      cdecl.}
  TDriverCloseProc* = proc (instanceData: TClientData, interp: PInterp): int{.
      cdecl.}
  TDriverInputProc* = proc (instanceData: TClientData, buf: cstring,
                            toRead: int, errorCodePtr: PInteger): int{.cdecl.}
  TDriverOutputProc* = proc (instanceData: TClientData, buf: cstring,
                             toWrite: int, errorCodePtr: PInteger): int{.cdecl.}
  TDriverSeekProc* = proc (instanceData: TClientData, offset: int32,
                           mode: int, errorCodePtr: PInteger): int{.cdecl.}
  TDriverSetOptionProc* = proc (instanceData: TClientData, interp: PInterp,
                                optionName: cstring, value: cstring): int{.cdecl.}
  TDriverGetOptionProc* = proc (instanceData: TClientData, interp: pInterp,
                                optionName: cstring, dsPtr: PDString): int{.
      cdecl.}
  TDriverWatchProc* = proc (instanceData: TClientData, mask: int){.cdecl.}
  TDriverGetHandleProc* = proc (instanceData: TClientData, direction: int,
                                handlePtr: var TClientData): int{.cdecl.}
  PChannelType* = ptr TChannelType
  TChannelType*{.final.} = object
    typeName*: cstring
    blockModeProc*: TDriverBlockModeProc
    closeProc*: TDriverCloseProc
    inputProc*: TDriverInputProc
    ouputProc*: TDriverOutputProc
    seekProc*: TDriverSeekProc
    setOptionProc*: TDriverSetOptionProc
    getOptionProc*: TDriverGetOptionProc
    watchProc*: TDriverWatchProc
    getHandleProc*: TDriverGetHandleProc

  TChannelProc* = proc (clientData: TClientData, mask: int){.cdecl.}
  PObj* = ptr TObj
  PPObj* = ptr PObj
  TObj*{.final.} = object
    refCount*: int            # ...

  TObjCmdProc* = proc (clientData: TClientData, interp: PInterp, objc: int,
                       PPObj: PPObj): int{.cdecl.}
  PNamespace* = ptr TNamespace
  TNamespace*{.final.} = object
    name*: cstring
    fullName*: cstring
    clientData*: TClientData
    deleteProc*: TNamespaceDeleteProc
    parentPtr*: PNamespace

  PCallFrame* = ptr TCallFrame
  TCallFrame*{.final.} = object
    nsPtr*: PNamespace
    dummy1*: int
    dummy2*: int
    dummy3*: cstring
    dummy4*: cstring
    dummy5*: cstring
    dummy6*: int
    dummy7*: cstring
    dummy8*: cstring
    dummy9*: int
    dummy10*: cstring

  PCmdInfo* = ptr TCmdInfo
  TCmdInfo*{.final.} = object
    isNativeObjectProc*: int
    objProc*: TObjCmdProc
    objClientData*: TClientData
    prc*: TCmdProc
    clientData*: TClientData
    deleteProc*: TCmdDeleteProc
    deleteData*: TClientData
    namespacePtr*: pNamespace

  pCommand* = ptr TCommand
  TCommand*{.final.} = object     #       hPtr            : pTcl_HashEntry;
                                  #        nsPtr           : pTcl_Namespace;
                                  #        refCount        : integer;
                                  #        isCmdEpoch      : integer;
                                  #        compileProc     : pointer;
                                  #        objProc         : pointer;
                                  #        objClientData   : Tcl_ClientData;
                                  #        proc            : pointer;
                                  #        clientData      : Tcl_ClientData;
                                  #        deleteProc      : TTclCmdDeleteProc;
                                  #        deleteData      : Tcl_ClientData;
                                  #        deleted         : integer;
                                  #        importRefPtr    : pointer;
                                  #

type
  TPanicProc* = proc (fmt, arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8: cstring){.
      cdecl.}                 # 1/15/97 orig. Tcl style
  TClientDataProc* = proc (clientData: TClientData){.cdecl.}
  TIdleProc* = proc (clientData: TClientData){.cdecl.}
  TTimerProc* = TIdleProc
  TCreateCloseHandler* = proc (channel: pChannel, prc: TClientDataProc,
                               clientData: TClientData){.cdecl.}
  TDeleteCloseHandler* = TCreateCloseHandler
  TEventDeleteProc* = proc (evPtr: pEvent, clientData: TClientData): int{.
      cdecl.}

proc Alloc*(size: int): cstring{.cdecl, dynlib: dllName,
                                     importc: "Tcl_Alloc".}
proc CreateInterp*(): pInterp{.cdecl, dynlib: dllName,
                                   importc: "Tcl_CreateInterp".}
proc DeleteInterp*(interp: pInterp){.cdecl, dynlib: dllName,
    importc: "Tcl_DeleteInterp".}
proc ResetResult*(interp: pInterp){.cdecl, dynlib: dllName,
                                        importc: "Tcl_ResetResult".}
proc Eval*(interp: pInterp, script: cstring): int{.cdecl, dynlib: dllName,
    importc: "Tcl_Eval".}
proc EvalFile*(interp: pInterp, filename: cstring): int{.cdecl,
    dynlib: dllName, importc: "Tcl_EvalFile".}
proc AddErrorInfo*(interp: pInterp, message: cstring){.cdecl,
    dynlib: dllName, importc: "Tcl_AddErrorInfo".}
proc BackgroundError*(interp: pInterp){.cdecl, dynlib: dllName,
    importc: "Tcl_BackgroundError".}
proc CreateCommand*(interp: pInterp, name: cstring, cmdProc: TCmdProc,
                        clientData: TClientData, deleteProc: TCmdDeleteProc): pCommand{.
    cdecl, dynlib: dllName, importc: "Tcl_CreateCommand".}
proc DeleteCommand*(interp: pInterp, name: cstring): int{.cdecl,
    dynlib: dllName, importc: "Tcl_DeleteCommand".}
proc CallWhenDeleted*(interp: pInterp, prc: TInterpDeleteProc,
                          clientData: TClientData){.cdecl, dynlib: dllName,
    importc: "Tcl_CallWhenDeleted".}
proc DontCallWhenDeleted*(interp: pInterp, prc: TInterpDeleteProc,
                              clientData: TClientData){.cdecl,
    dynlib: dllName, importc: "Tcl_DontCallWhenDeleted".}
proc CommandComplete*(cmd: cstring): int{.cdecl, dynlib: dllName,
    importc: "Tcl_CommandComplete".}
proc LinkVar*(interp: pInterp, varName: cstring, varAddr: pointer, typ: int): int{.
    cdecl, dynlib: dllName, importc: "Tcl_LinkVar".}
proc UnlinkVar*(interp: pInterp, varName: cstring){.cdecl, dynlib: dllName,
    importc: "Tcl_UnlinkVar".}
proc TraceVar*(interp: pInterp, varName: cstring, flags: int,
                   prc: TVarTraceProc, clientData: TClientData): int{.cdecl,
    dynlib: dllName, importc: "Tcl_TraceVar".}
proc TraceVar2*(interp: pInterp, varName: cstring, elemName: cstring,
                    flags: int, prc: TVarTraceProc, clientData: TClientData): int{.
    cdecl, dynlib: dllName, importc: "Tcl_TraceVar2".}
proc UntraceVar*(interp: pInterp, varName: cstring, flags: int,
                     prc: TVarTraceProc, clientData: TClientData){.cdecl,
    dynlib: dllName, importc: "Tcl_UntraceVar".}
proc UntraceVar2*(interp: pInterp, varName: cstring, elemName: cstring,
                      flags: int, prc: TVarTraceProc, clientData: TClientData){.
    cdecl, dynlib: dllName, importc: "Tcl_UntraceVar2".}
proc GetVar*(interp: pInterp, varName: cstring, flags: int): cstring{.cdecl,
    dynlib: dllName, importc: "Tcl_GetVar".}
proc GetVar2*(interp: pInterp, varName: cstring, elemName: cstring,
                  flags: int): cstring{.cdecl, dynlib: dllName,
                                        importc: "Tcl_GetVar2".}
proc SetVar*(interp: pInterp, varName: cstring, newValue: cstring,
                 flags: int): cstring{.cdecl, dynlib: dllName,
                                       importc: "Tcl_SetVar".}
proc SetVar2*(interp: pInterp, varName: cstring, elemName: cstring,
                  newValue: cstring, flags: int): cstring{.cdecl,
    dynlib: dllName, importc: "Tcl_SetVar2".}
proc UnsetVar*(interp: pInterp, varName: cstring, flags: int): int{.cdecl,
    dynlib: dllName, importc: "Tcl_UnsetVar".}
proc UnsetVar2*(interp: pInterp, varName: cstring, elemName: cstring,
                    flags: int): int{.cdecl, dynlib: dllName,
                                      importc: "Tcl_UnsetVar2".}
proc SetResult*(interp: pInterp, newValue: cstring, freeProc: TFreeProc){.
    cdecl, dynlib: dllName, importc: "Tcl_SetResult".}
proc FirstHashEntry*(hashTbl: pHashTable, searchInfo: var THashSearch): pHashEntry{.
    cdecl, dynlib: dllName, importc: "Tcl_FirstHashEntry".}
proc NextHashEntry*(searchInfo: var THashSearch): pHashEntry{.cdecl,
    dynlib: dllName, importc: "Tcl_NextHashEntry".}
proc InitHashTable*(hashTbl: pHashTable, keyType: int){.cdecl,
    dynlib: dllName, importc: "Tcl_InitHashTable".}
proc StringMatch*(str: cstring, pattern: cstring): int{.cdecl,
    dynlib: dllName, importc: "Tcl_StringMatch".}
proc GetErrno*(): int{.cdecl, dynlib: dllName, importc: "Tcl_GetErrno".}
proc SetErrno*(val: int){.cdecl, dynlib: dllName, importc: "Tcl_SetErrno".}
proc SetPanicProc*(prc: TPanicProc){.cdecl, dynlib: dllName,
    importc: "Tcl_SetPanicProc".}
proc PkgProvide*(interp: pInterp, name: cstring, version: cstring): int{.
    cdecl, dynlib: dllName, importc: "Tcl_PkgProvide".}
proc StaticPackage*(interp: pInterp, pkgName: cstring,
                        initProc: TPackageInitProc,
                        safeInitProc: TPackageInitProc){.cdecl, dynlib: dllName,
    importc: "Tcl_StaticPackage".}
proc CreateEventSource*(setupProc: TEventSetupProc,
                            checkProc: TEventCheckProc,
                            clientData: TClientData){.cdecl, dynlib: dllName,
    importc: "Tcl_CreateEventSource".}
proc DeleteEventSource*(setupProc: TEventSetupProc,
                            checkProc: TEventCheckProc,
                            clientData: TClientData){.cdecl, dynlib: dllName,
    importc: "Tcl_DeleteEventSource".}
proc QueueEvent*(evPtr: pEvent, pos: int){.cdecl, dynlib: dllName,
    importc: "Tcl_QueueEvent".}
proc SetMaxBlockTime*(timePtr: pTime){.cdecl, dynlib: dllName,
    importc: "Tcl_SetMaxBlockTime".}
proc DeleteEvents*(prc: TEventDeleteProc, clientData: TClientData){.
    cdecl, dynlib: dllName, importc: "Tcl_DeleteEvents".}
proc DoOneEvent*(flags: int): int{.cdecl, dynlib: dllName,
                                       importc: "Tcl_DoOneEvent".}
proc DoWhenIdle*(prc: TIdleProc, clientData: TClientData){.cdecl,
    dynlib: dllName, importc: "Tcl_DoWhenIdle".}
proc CancelIdleCall*(prc: TIdleProc, clientData: TClientData){.cdecl,
    dynlib: dllName, importc: "Tcl_CancelIdleCall".}
proc CreateTimerHandler*(milliseconds: int, prc: TTimerProc,
                             clientData: TClientData): TTimerToken{.cdecl,
    dynlib: dllName, importc: "Tcl_CreateTimerHandler".}
proc DeleteTimerHandler*(token: TTimerToken){.cdecl, dynlib: dllName,
    importc: "Tcl_DeleteTimerHandler".}
  #    procedure Tcl_CreateModalTimeout(milliseconds: integer; prc: TTclTimerProc; clientData: Tcl_ClientData); cdecl; external dllName;
  #    procedure Tcl_DeleteModalTimeout(prc: TTclTimerProc; clientData: Tcl_ClientData); cdecl; external dllName;
proc SplitList*(interp: pInterp, list: cstring, argcPtr: var int,
                    argvPtr: var TArgv): int{.cdecl, dynlib: dllName,
    importc: "Tcl_SplitList".}
proc Merge*(argc: int, argv: TArgv): cstring{.cdecl, dynlib: dllName,
    importc: "Tcl_Merge".}
proc Free*(p: cstring){.cdecl, dynlib: dllName, importc: "Tcl_Free".}
proc Init*(interp: pInterp): int{.cdecl, dynlib: dllName,
                                      importc: "Tcl_Init".}
  #    procedure Tcl_InterpDeleteProc(clientData: Tcl_ClientData; interp: pTcl_Interp); cdecl; external dllName;
proc GetAssocData*(interp: pInterp, key: cstring, prc: var TInterpDeleteProc): TClientData{.
    cdecl, dynlib: dllName, importc: "Tcl_GetAssocData".}
proc DeleteAssocData*(interp: pInterp, key: cstring){.cdecl,
    dynlib: dllName, importc: "Tcl_DeleteAssocData".}
proc SetAssocData*(interp: pInterp, key: cstring, prc: TInterpDeleteProc,
                       clientData: TClientData){.cdecl, dynlib: dllName,
    importc: "Tcl_SetAssocData".}
proc IsSafe*(interp: pInterp): int{.cdecl, dynlib: dllName,
                                        importc: "Tcl_IsSafe".}
proc MakeSafe*(interp: pInterp): int{.cdecl, dynlib: dllName,
    importc: "Tcl_MakeSafe".}
proc CreateSlave*(interp: pInterp, slaveName: cstring, isSafe: int): pInterp{.
    cdecl, dynlib: dllName, importc: "Tcl_CreateSlave".}
proc GetSlave*(interp: pInterp, slaveName: cstring): pInterp{.cdecl,
    dynlib: dllName, importc: "Tcl_GetSlave".}
proc GetMaster*(interp: pInterp): pInterp{.cdecl, dynlib: dllName,
    importc: "Tcl_GetMaster".}
proc GetInterpPath*(askingInterp: pInterp, slaveInterp: pInterp): int{.
    cdecl, dynlib: dllName, importc: "Tcl_GetInterpPath".}
proc CreateAlias*(slaveInterp: pInterp, srcCmd: cstring,
                      targetInterp: pInterp, targetCmd: cstring, argc: int,
                      argv: TArgv): int{.cdecl, dynlib: dllName,
    importc: "Tcl_CreateAlias".}
proc GetAlias*(interp: pInterp, srcCmd: cstring, targetInterp: var pInterp,
                   targetCmd: var cstring, argc: var int, argv: var TArgv): int{.
    cdecl, dynlib: dllName, importc: "Tcl_GetAlias".}
proc ExposeCommand*(interp: pInterp, hiddenCmdName: cstring,
                        cmdName: cstring): int{.cdecl, dynlib: dllName,
    importc: "Tcl_ExposeCommand".}
proc HideCommand*(interp: pInterp, cmdName: cstring, hiddenCmdName: cstring): int{.
    cdecl, dynlib: dllName, importc: "Tcl_HideCommand".}
proc EventuallyFree*(clientData: TClientData, freeProc: TFreeProc){.
    cdecl, dynlib: dllName, importc: "Tcl_EventuallyFree".}
proc Preserve*(clientData: TClientData){.cdecl, dynlib: dllName,
    importc: "Tcl_Preserve".}
proc Release*(clientData: TClientData){.cdecl, dynlib: dllName,
    importc: "Tcl_Release".}
proc InterpDeleted*(interp: pInterp): int{.cdecl, dynlib: dllName,
    importc: "Tcl_InterpDeleted".}
proc GetCommandInfo*(interp: pInterp, cmdName: cstring,
                         info: var TCmdInfo): int{.cdecl, dynlib: dllName,
    importc: "Tcl_GetCommandInfo".}
proc SetCommandInfo*(interp: pInterp, cmdName: cstring,
                         info: var TCmdInfo): int{.cdecl, dynlib: dllName,
    importc: "Tcl_SetCommandInfo".}
proc FindExecutable*(path: cstring){.cdecl, dynlib: dllName,
    importc: "Tcl_FindExecutable".}
proc GetStringResult*(interp: pInterp): cstring{.cdecl, dynlib: dllName,
    importc: "Tcl_GetStringResult".}
  #v1.0
proc FindCommand*(interp: pInterp, cmdName: cstring,
                      contextNsPtr: pNamespace, flags: int): TCommand{.cdecl,
    dynlib: dllName, importc: "Tcl_FindCommand".}
  #v1.0
proc DeleteCommandFromToken*(interp: pInterp, cmd: pCommand): int{.cdecl,
    dynlib: dllName, importc: "Tcl_DeleteCommandFromToken".}
proc CreateNamespace*(interp: pInterp, name: cstring,
                          clientData: TClientData,
                          deleteProc: TNamespaceDeleteProc): pNamespace{.cdecl,
    dynlib: dllName, importc: "Tcl_CreateNamespace".}
  #v1.0
proc DeleteNamespace*(namespacePtr: pNamespace){.cdecl, dynlib: dllName,
    importc: "Tcl_DeleteNamespace".}
proc FindNamespace*(interp: pInterp, name: cstring,
                        contextNsPtr: pNamespace, flags: int): pNamespace{.
    cdecl, dynlib: dllName, importc: "Tcl_FindNamespace".}
proc Tcl_Export*(interp: pInterp, namespacePtr: pNamespace, pattern: cstring,
                 resetListFirst: int): int{.cdecl, dynlib: dllName,
    importc: "Tcl_Export".}
proc Tcl_Import*(interp: pInterp, namespacePtr: pNamespace, pattern: cstring,
                 allowOverwrite: int): int{.cdecl, dynlib: dllName,
    importc: "Tcl_Import".}
proc GetCurrentNamespace*(interp: pInterp): pNamespace{.cdecl,
    dynlib: dllName, importc: "Tcl_GetCurrentNamespace".}
proc GetGlobalNamespace*(interp: pInterp): pNamespace{.cdecl,
    dynlib: dllName, importc: "Tcl_GetGlobalNamespace".}
proc PushCallFrame*(interp: pInterp, callFramePtr: var TCallFrame,
                        namespacePtr: pNamespace, isProcCallFrame: int): int{.
    cdecl, dynlib: dllName, importc: "Tcl_PushCallFrame".}
proc PopCallFrame*(interp: pInterp){.cdecl, dynlib: dllName,
    importc: "Tcl_PopCallFrame".}
proc VarEval*(interp: pInterp): int{.cdecl, varargs, dynlib: dllName,
    importc: "Tcl_VarEval".}
  # For TkConsole.c *
proc RecordAndEval*(interp: pInterp, cmd: cstring, flags: int): int{.cdecl,
    dynlib: dllName, importc: "Tcl_RecordAndEval".}
proc GlobalEval*(interp: pInterp, command: cstring): int{.cdecl,
    dynlib: dllName, importc: "Tcl_GlobalEval".}
proc DStringFree*(dsPtr: pDString){.cdecl, dynlib: dllName,
                                        importc: "Tcl_DStringFree".}
proc DStringAppend*(dsPtr: pDString, str: cstring, length: int): cstring{.
    cdecl, dynlib: dllName, importc: "Tcl_DStringAppend".}
proc DStringAppendElement*(dsPtr: pDString, str: cstring): cstring{.cdecl,
    dynlib: dllName, importc: "Tcl_DStringAppendElement".}
proc DStringInit*(dsPtr: pDString){.cdecl, dynlib: dllName,
                                        importc: "Tcl_DStringInit".}
proc AppendResult*(interp: pInterp){.cdecl, varargs, dynlib: dllName,
    importc: "Tcl_AppendResult".}
  # actually a "C" var array
proc SetStdChannel*(channel: pChannel, typ: int){.cdecl, dynlib: dllName,
    importc: "Tcl_SetStdChannel".}
proc SetChannelOption*(interp: pInterp, chan: pChannel, optionName: cstring,
                           newValue: cstring): int{.cdecl, dynlib: dllName,
    importc: "Tcl_SetChannelOption".}
proc GetChannelOption*(interp: pInterp, chan: pChannel, optionName: cstring,
                           dsPtr: pDString): int{.cdecl, dynlib: dllName,
    importc: "Tcl_GetChannelOption".}
proc CreateChannel*(typePtr: pChannelType, chanName: cstring,
                        instanceData: TClientData, mask: int): pChannel{.
    cdecl, dynlib: dllName, importc: "Tcl_CreateChannel".}
proc RegisterChannel*(interp: pInterp, channel: pChannel){.cdecl,
    dynlib: dllName, importc: "Tcl_RegisterChannel".}
proc UnregisterChannel*(interp: pInterp, channel: pChannel): int{.cdecl,
    dynlib: dllName, importc: "Tcl_UnregisterChannel".}
proc CreateChannelHandler*(chan: pChannel, mask: int, prc: TChannelProc,
                               clientData: TClientData){.cdecl,
    dynlib: dllName, importc: "Tcl_CreateChannelHandler".}
proc GetChannel*(interp: pInterp, chanName: cstring, modePtr: pInteger): pChannel{.
    cdecl, dynlib: dllName, importc: "Tcl_GetChannel".}
proc GetStdChannel*(typ: int): pChannel{.cdecl, dynlib: dllName,
    importc: "Tcl_GetStdChannel".}
proc Gets*(chan: pChannel, dsPtr: pDString): int{.cdecl, dynlib: dllName,
    importc: "Tcl_Gets".}
proc Write*(chan: pChannel, s: cstring, slen: int): int{.cdecl,
    dynlib: dllName, importc: "Tcl_Write".}
proc Flush*(chan: pChannel): int{.cdecl, dynlib: dllName,
                                      importc: "Tcl_Flush".}
  #    TclWinLoadLibrary      = function(name: PChar): HMODULE; cdecl; external dllName;
proc CreateExitHandler*(prc: TClientDataProc, clientData: TClientData){.
    cdecl, dynlib: dllName, importc: "Tcl_CreateExitHandler".}
proc DeleteExitHandler*(prc: TClientDataProc, clientData: TClientData){.
    cdecl, dynlib: dllName, importc: "Tcl_DeleteExitHandler".}
proc GetStringFromObj*(pObj: pObj, pLen: pInteger): cstring{.cdecl,
    dynlib: dllName, importc: "Tcl_GetStringFromObj".}
proc CreateObjCommand*(interp: pInterp, name: cstring, cmdProc: TObjCmdProc,
                           clientData: TClientData,
                           deleteProc: TCmdDeleteProc): pCommand{.cdecl,
    dynlib: dllName, importc: "Tcl_CreateObjCommand".}
proc NewStringObj*(bytes: cstring, length: int): pObj{.cdecl,
    dynlib: dllName, importc: "Tcl_NewStringObj".}
  #    procedure TclFreeObj(pObj: pTcl_Obj); cdecl; external dllName;
proc EvalObj*(interp: pInterp, pObj: pObj): int{.cdecl, dynlib: dllName,
    importc: "Tcl_EvalObj".}
proc GlobalEvalObj*(interp: pInterp, pObj: pObj): int{.cdecl,
    dynlib: dllName, importc: "Tcl_GlobalEvalObj".}
proc RegComp*(exp: cstring): pointer{.cdecl, dynlib: dllName,
    importc: "TclRegComp".}

proc RegExec*(prog: pointer, str: cstring, start: cstring): int{.cdecl,
    dynlib: dllName, importc: "TclRegExec".}

proc RegError*(msg: cstring){.cdecl, dynlib: dllName, importc: "TclRegError".}

proc GetRegError*(): cstring{.cdecl, dynlib: dllName,
                              importc: "TclGetRegError".}

proc RegExpRange*(prog: pointer, index: int, head: var cstring,
                      tail: var cstring){.cdecl, dynlib: dllName,
    importc: "Tcl_RegExpRange".}

proc GetCommandTable*(interp: pInterp): pHashTable =
  if interp != nil:
    result = cast[pHashTable](cast[int](interp) + sizeof(Interp) +
        sizeof(pointer))

proc CreateHashEntry*(tablePtr: pHashTable, key: cstring,
                      newPtr: pInteger): pHashEntry =
  result = cast[pHashTable](tablePtr).createProc(tablePtr, key, newPtr)

proc FindHashEntry*(tablePtr: pHashTable, key: cstring): pHashEntry =
  result = cast[pHashTable](tablePtr).findProc(tablePtr, key)

proc SetHashValue*(h: pHashEntry, clientData: TClientData) =
  h.clientData = clientData

proc GetHashValue*(h: pHashEntry): TClientData =
  result = h.clientData

proc IncrRefCount*(pObj: pObj) =
  inc(pObj.refCount)

proc DecrRefCount*(pObj: pObj) =
  dec(pObj.refCount)
  if pObj.refCount <= 0:
    dealloc(pObj)

proc IsShared*(pObj: pObj): bool =
  return pObj.refCount > 1

proc GetHashKey*(hashTbl: pHashTable, hashEntry: pHashEntry): cstring =
  if hashTbl == nil or hashEntry == nil:
    result = nil
  else:
    result = hashEntry.key
