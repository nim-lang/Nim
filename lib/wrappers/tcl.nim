#
#
#            Nimrod's Runtime Library
#        (c) Copyright 2009 Andreas Rumpf
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

when defined(WIN32): 
  const dllName = "tcl(85|84|83|82|81|80).dll"
elif defined(macosx): 
  const dllName = "libtcl(8.5|8.4|8.3|8.2|8.1).dynlib"
else:
  const dllName = "libtcl(8.5|8.4|8.3|8.2|8.1).so.(1|0)"

const 
  TCL_DESTROYED* = 0xDEADDEAD
  TCL_OK* = 0
  TCL_ERROR* = 1
  TCL_RETURN* = 2
  TCL_BREAK* = 3
  TCL_CONTINUE* = 4
  TCL_RESULT_SIZE* = 200
  MAX_ARGV* = 0x00007FFF
  TCL_VERSION_MAJOR* = 0
  TCL_VERSION_MINOR* = 0
  TCL_NO_EVAL* = 0x00010000
  TCL_EVAL_GLOBAL* = 0x00020000 # Flag values passed to variable-related procedures. *
  TCL_GLOBAL_ONLY* = 1
  TCL_NAMESPACE_ONLY* = 2
  TCL_APPEND_VALUE* = 4
  TCL_LIST_ELEMENT* = 8
  TCL_TRACE_READS* = 0x00000010
  TCL_TRACE_WRITES* = 0x00000020
  TCL_TRACE_UNSETS* = 0x00000040
  TCL_TRACE_DESTROYED* = 0x00000080
  TCL_INTERP_DESTROYED* = 0x00000100
  TCL_LEAVE_ERR_MSG* = 0x00000200
  TCL_PARSE_PART1* = 0x00000400 # Types for linked variables: *
  TCL_LINK_INT* = 1
  TCL_LINK_DOUBLE* = 2
  TCL_LINK_BOOLEAN* = 3
  TCL_LINK_STRING* = 4
  TCL_LINK_READ_ONLY* = 0x00000080
  TCL_SMALL_HASH_TABLE* = 4   # Hash Table *
  TCL_STRING_KEYS* = 0
  TCL_ONE_WORD_KEYS* = 1      # Const/enums Tcl_QueuePosition *
                              # typedef enum {
  TCL_QUEUE_TAIL* = 0
  TCL_QUEUE_HEAD* = 1
  TCL_QUEUE_MARK* = 2         #} Tcl_QueuePosition;
                              # Event Flags
  TCL_DONT_WAIT* = 1 shl 1
  TCL_WINDOW_EVENTS* = 1 shl 2
  TCL_FILE_EVENTS* = 1 shl 3
  TCL_TIMER_EVENTS* = 1 shl 4
  TCL_IDLE_EVENTS* = 1 shl 5  # WAS 0x10 ???? *
  TCL_ALL_EVENTS* = not TCL_DONT_WAIT 

  TCL_VOLATILE* = 1
  TCL_STATIC* = 0
  TCL_DYNAMIC* = 3            # Channel
  TCL_STDIN* = 1 shl 1
  TCL_STDOUT* = 1 shl 2
  TCL_STDERR* = 1 shl 3
  TCL_ENFORCE_MODE* = 1 shl 4
  TCL_READABLE* = 1 shl 1
  TCL_WRITABLE* = 1 shl 2
  TCL_EXCEPTION* = 1 shl 3    # POSIX *
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
  Tcl_Argv* = cstringArray
  Tcl_ClientData* = pointer
  Tcl_FreeProc* = proc (theBlock: pointer){.cdecl.}
  PTcl_Interp* = ptr Tcl_Interp
  Tcl_Interp*{.final.} = object  #  Event Definitions  *
    result*: cstring # Do not access this directly. Use
                     #                          * Tcl_GetStringResult since result
                     #                          * may be pointing to an object
                     #                          *
    freeProc*: Tcl_FreeProc
    errorLine*: int

  TTcl_EventSetupProc* = proc (clientData: Tcl_ClientData, flags: int){.cdecl.}
  TTcl_EventCheckProc* = TTcl_EventSetupProc
  PTcl_Event* = ptr Tcl_Event
  TTcl_EventProc* = proc (evPtr: PTcl_Event, flags: int): int{.cdecl.}
  Tcl_Event*{.final.} = object 
    prc*: TTcl_EventProc
    nextPtr*: PTcl_Event
    ClientData*: TObject      # ClientData is just pointer.*
  
  PTcl_Time* = ptr Tcl_Time
  Tcl_Time*{.final.} = object 
    sec*: int32               # Seconds. * 
    usec*: int32              # Microseconds. * 
  
  Tcl_TimerToken* = pointer
  PInteger* = ptr int
  PTcl_HashTable* = pointer
  PTcl_HashEntry* = ptr Tcl_HashEntry
  PPTcl_HashEntry* = ptr PTcl_HashEntry
  Tcl_HashEntry*{.final.} = object  
    nextPtr*: PTcl_HashEntry
    tablePtr*: PTcl_HashTable
    bucketPtr*: PPTcl_HashEntry
    clientData*: Tcl_ClientData
    key*: cstring

  Tcl_HashFindProc* = proc (tablePtr: PTcl_HashTable, key: cstring): PTcl_HashEntry{.
      cdecl.}
  Tcl_HashCreateProc* = proc (tablePtr: PTcl_HashTable, key: cstring, 
                              newPtr: PInteger): PTcl_HashEntry{.cdecl.}
  PHashTable* = ptr Tcl_HashTable
  Tcl_HashTable*{.final.} = object 
    buckets*: ppTcl_HashEntry
    staticBuckets*: array[0..TCL_SMALL_HASH_TABLE - 1, PTcl_HashEntry]
    numBuckets*: int
    numEntries*: int
    rebuildSize*: int
    downShift*: int
    mask*: int
    keyType*: int
    findProc*: Tcl_HashFindProc
    createProc*: Tcl_HashCreateProc

  PTcl_HashSearch* = ptr Tcl_HashSearch
  Tcl_HashSearch*{.final.} = object 
    tablePtr*: PTcl_HashTable
    nextIndex*: int
    nextEntryPtr*: PTcl_HashEntry

  TTclAppInitProc* = proc (interp: pTcl_Interp): int{.cdecl.}
  TTclPackageInitProc* = proc (interp: pTcl_Interp): int{.cdecl.}
  TTclCmdProc* = proc (clientData: Tcl_ClientData, interp: pTcl_Interp, 
                       argc: int, argv: Tcl_Argv): int{.cdecl.}
  TTclVarTraceProc* = proc (clientData: Tcl_ClientData, interp: pTcl_Interp, 
                            varName: cstring, elemName: cstring, flags: int): cstring{.
      cdecl.}
  TTclFreeProc* = proc (theBlock: pointer){.cdecl.}
  TTclInterpDeleteProc* = proc (clientData: Tcl_ClientData, interp: pTcl_Interp){.
      cdecl.}
  TTclCmdDeleteProc* = proc (clientData: Tcl_ClientData){.cdecl.}
  TTclNamespaceDeleteProc* = proc (clientData: Tcl_ClientData){.cdecl.}

const 
  TCL_DSTRING_STATIC_SIZE* = 200

type 
  PTcl_DString* = ptr Tcl_DString
  Tcl_DString*{.final.} = object 
    str*: cstring
    len*: int
    spaceAvl*: int
    staticSpace*: array[0..TCL_DSTRING_STATIC_SIZE - 1, char]

  PTcl_Channel* = ptr Tcl_Channel
  Tcl_Channel*{.final.} = object 
  TTclDriverBlockModeProc* = proc (instanceData: Tcl_ClientData, mode: int): int{.
      cdecl.}
  TTclDriverCloseProc* = proc (instanceData: Tcl_ClientData, interp: PTcl_Interp): int{.
      cdecl.}
  TTclDriverInputProc* = proc (instanceData: Tcl_ClientData, buf: cstring, 
                               toRead: int, errorCodePtr: PInteger): int{.cdecl.}
  TTclDriverOutputProc* = proc (instanceData: Tcl_ClientData, buf: cstring, 
                                toWrite: int, errorCodePtr: PInteger): int{.
      cdecl.}
  TTclDriverSeekProc* = proc (instanceData: Tcl_ClientData, offset: int32, 
                              mode: int, errorCodePtr: PInteger): int{.cdecl.}
  TTclDriverSetOptionProc* = proc (instanceData: Tcl_ClientData, 
                                   interp: PTcl_Interp, optionName: cstring, 
                                   value: cstring): int{.cdecl.}
  TTclDriverGetOptionProc* = proc (instanceData: Tcl_ClientData, 
                                   interp: pTcl_Interp, optionName: cstring, 
                                   dsPtr: PTcl_DString): int{.cdecl.}
  TTclDriverWatchProc* = proc (instanceData: Tcl_ClientData, mask: int){.cdecl.}
  TTclDriverGetHandleProc* = proc (instanceData: Tcl_ClientData, direction: int, 
                                   handlePtr: var Tcl_ClientData): int{.cdecl.}
  PTcl_ChannelType* = ptr Tcl_ChannelType
  Tcl_ChannelType*{.final.} = object 
    typeName*: cstring
    blockModeProc*: TTclDriverBlockModeProc
    closeProc*: TTclDriverCloseProc
    inputProc*: TTclDriverInputProc
    ouputProc*: TTclDriverOutputProc
    seekProc*: TTclDriverSeekProc
    setOptionProc*: TTclDriverSetOptionProc
    getOptionProc*: TTclDriverGetOptionProc
    watchProc*: TTclDriverWatchProc
    getHandleProc*: TTclDriverGetHandleProc

  TTclChannelProc* = proc (clientData: Tcl_ClientData, mask: int){.cdecl.}
  PTcl_Obj* = ptr Tcl_Obj
  PPTcl_Obj* = ptr PTcl_Obj
  Tcl_Obj*{.final.} = object 
    refCount*: int            # ...
  
  TTclObjCmdProc* = proc (clientData: Tcl_ClientData, interp: PTcl_Interp, 
                          objc: int, PPObj: PPTcl_Obj): int{.cdecl.}
  PTcl_Namespace* = ptr Tcl_Namespace
  Tcl_Namespace*{.final.} = object 
    name*: cstring
    fullName*: cstring
    clientData*: Tcl_ClientData
    deleteProc*: TTclNamespaceDeleteProc
    parentPtr*: PTcl_Namespace

  PTcl_CallFrame* = ptr Tcl_CallFrame
  Tcl_CallFrame*{.final.} = object 
    nsPtr*: PTcl_Namespace
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

  PTcl_CmdInfo* = ptr Tcl_CmdInfo
  Tcl_CmdInfo*{.final.} = object 
    isNativeObjectProc*: int
    objProc*: TTclObjCmdProc
    objClientData*: Tcl_ClientData
    prc*: TTclCmdProc
    clientData*: Tcl_ClientData
    deleteProc*: TTclCmdDeleteProc
    deleteData*: Tcl_ClientData
    namespacePtr*: pTcl_Namespace

  pTcl_Command* = ptr Tcl_Command
  Tcl_Command*{.final.} = object  #       hPtr            : pTcl_HashEntry;
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
  TTclPanicProc* = proc (fmt, arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8: cstring){.
      cdecl.}                 # 1/15/97 orig. Tcl style
  TTclClientDataProc* = proc (clientData: Tcl_ClientData){.cdecl.}
  TTclIdleProc* = proc (clientData: Tcl_ClientData){.cdecl.}
  TTclTimerProc* = TTclIdleProc
  TTclCreateCloseHandler* = proc (channel: pTcl_Channel, 
                                  prc: TTclClientDataProc, 
                                  clientData: Tcl_ClientData){.cdecl.}
  TTclDeleteCloseHandler* = TTclCreateCloseHandler
  TTclEventDeleteProc* = proc (evPtr: pTcl_Event, clientData: Tcl_ClientData): int{.
      cdecl.}

proc Tcl_Alloc*(size: int): cstring{.cdecl, dynlib: dllName, importc.}
proc Tcl_CreateInterp*(): pTcl_Interp{.cdecl, dynlib: dllName, importc.}
proc Tcl_DeleteInterp*(interp: pTcl_Interp){.cdecl, dynlib: dllName, importc.}
proc Tcl_ResetResult*(interp: pTcl_Interp){.cdecl, dynlib: dllName, importc.}
proc Tcl_Eval*(interp: pTcl_Interp, script: cstring): int{.cdecl, 
    dynlib: dllName, importc.}
proc Tcl_EvalFile*(interp: pTcl_Interp, filename: cstring): int{.cdecl, 
    dynlib: dllName, importc.}
proc Tcl_AddErrorInfo*(interp: pTcl_Interp, message: cstring){.cdecl, 
    dynlib: dllName, importc.}
proc Tcl_BackgroundError*(interp: pTcl_Interp){.cdecl, dynlib: dllName, 
    importc.}
proc Tcl_CreateCommand*(interp: pTcl_Interp, name: cstring, 
                        cmdProc: TTclCmdProc, clientData: Tcl_ClientData, 
                        deleteProc: TTclCmdDeleteProc): pTcl_Command{.cdecl, 
    dynlib: dllName, importc.}
proc Tcl_DeleteCommand*(interp: pTcl_Interp, name: cstring): int{.cdecl, 
    dynlib: dllName, importc.}
proc Tcl_CallWhenDeleted*(interp: pTcl_Interp, prc: TTclInterpDeleteProc, 
                          clientData: Tcl_ClientData){.cdecl, 
    dynlib: dllName, importc.}
proc Tcl_DontCallWhenDeleted*(interp: pTcl_Interp, prc: TTclInterpDeleteProc, 
                              clientData: Tcl_ClientData){.cdecl, 
    dynlib: dllName, importc.}
proc Tcl_CommandComplete*(cmd: cstring): int{.cdecl, dynlib: dllName, 
    importc.}
proc Tcl_LinkVar*(interp: pTcl_Interp, varName: cstring, varAddr: pointer, 
                  typ: int): int{.cdecl, dynlib: dllName, importc.}
proc Tcl_UnlinkVar*(interp: pTcl_Interp, varName: cstring){.cdecl, 
    dynlib: dllName, importc.}
proc Tcl_TraceVar*(interp: pTcl_Interp, varName: cstring, flags: int, 
                   prc: TTclVarTraceProc, clientData: Tcl_ClientData): int{.
    cdecl, dynlib: dllName, importc.}
proc Tcl_TraceVar2*(interp: pTcl_Interp, varName: cstring, elemName: cstring, 
                    flags: int, prc: TTclVarTraceProc, 
                    clientData: Tcl_ClientData): int{.cdecl, 
    dynlib: dllName, importc.}
proc Tcl_UntraceVar*(interp: pTcl_Interp, varName: cstring, flags: int, 
                     prc: TTclVarTraceProc, clientData: Tcl_ClientData){.cdecl, 
    dynlib: dllName, importc.}
proc Tcl_UntraceVar2*(interp: pTcl_Interp, varName: cstring, elemName: cstring, 
                      flags: int, prc: TTclVarTraceProc, 
                      clientData: Tcl_ClientData){.cdecl, dynlib: dllName, 
    importc.}
proc Tcl_GetVar*(interp: pTcl_Interp, varName: cstring, flags: int): cstring{.
    cdecl, dynlib: dllName, importc.}
proc Tcl_GetVar2*(interp: pTcl_Interp, varName: cstring, elemName: cstring, 
                  flags: int): cstring{.cdecl, dynlib: dllName, importc.}
proc Tcl_SetVar*(interp: pTcl_Interp, varName: cstring, newValue: cstring, 
                 flags: int): cstring{.cdecl, dynlib: dllName, importc.}
proc Tcl_SetVar2*(interp: pTcl_Interp, varName: cstring, elemName: cstring, 
                  newValue: cstring, flags: int): cstring{.cdecl, 
    dynlib: dllName, importc.}
proc Tcl_UnsetVar*(interp: pTcl_Interp, varName: cstring, flags: int): int{.
    cdecl, dynlib: dllName, importc.}
proc Tcl_UnsetVar2*(interp: pTcl_Interp, varName: cstring, elemName: cstring, 
                    flags: int): int{.cdecl, dynlib: dllName, importc.}
proc Tcl_SetResult*(interp: pTcl_Interp, newValue: cstring, 
                    freeProc: TTclFreeProc){.cdecl, dynlib: dllName, importc.}
proc Tcl_FirstHashEntry*(hashTbl: pTcl_HashTable, searchInfo: var Tcl_HashSearch): pTcl_HashEntry{.
    cdecl, dynlib: dllName, importc.}
proc Tcl_NextHashEntry*(searchInfo: var Tcl_HashSearch): pTcl_HashEntry{.cdecl, 
    dynlib: dllName, importc.}
proc Tcl_InitHashTable*(hashTbl: pTcl_HashTable, keyType: int){.cdecl, 
    dynlib: dllName, importc.}
proc Tcl_StringMatch*(str: cstring, pattern: cstring): int{.cdecl, 
    dynlib: dllName, importc.}

proc Tcl_GetErrno*(): int{.cdecl, dynlib: dllName, importc.}
proc Tcl_SetErrno*(val: int){.cdecl, dynlib: dllName, importc.}
proc Tcl_SetPanicProc*(prc: TTclPanicProc){.cdecl, dynlib: dllName, importc.}
proc Tcl_PkgProvide*(interp: pTcl_Interp, name: cstring, version: cstring): int{.
    cdecl, dynlib: dllName, importc.}
proc Tcl_StaticPackage*(interp: pTcl_Interp, pkgName: cstring, 
                        initProc: TTclPackageInitProc, 
                        safeInitProc: TTclPackageInitProc){.cdecl, 
    dynlib: dllName, importc.}
proc Tcl_CreateEventSource*(setupProc: TTcl_EventSetupProc, 
                            checkProc: TTcl_EventCheckProc, 
                            clientData: Tcl_ClientData){.cdecl, 
    dynlib: dllName, importc.}
proc Tcl_DeleteEventSource*(setupProc: TTcl_EventSetupProc, 
                            checkProc: TTcl_EventCheckProc, 
                            clientData: Tcl_ClientData){.cdecl, 
    dynlib: dllName, importc.}
proc Tcl_QueueEvent*(evPtr: pTcl_Event, pos: int){.cdecl, dynlib: dllName, 
    importc.}
proc Tcl_SetMaxBlockTime*(timePtr: pTcl_Time){.cdecl, dynlib: dllName, 
    importc.}
proc Tcl_DeleteEvents*(prc: TTclEventDeleteProc, clientData: Tcl_ClientData){.
    cdecl, dynlib: dllName, importc.}
proc Tcl_DoOneEvent*(flags: int): int{.cdecl, dynlib: dllName, importc.}
proc Tcl_DoWhenIdle*(prc: TTclIdleProc, clientData: Tcl_ClientData){.cdecl, 
    dynlib: dllName, importc.}
proc Tcl_CancelIdleCall*(prc: TTclIdleProc, clientData: Tcl_ClientData){.cdecl, 
    dynlib: dllName, importc.}
proc Tcl_CreateTimerHandler*(milliseconds: int, prc: TTclTimerProc, 
                             clientData: Tcl_ClientData): Tcl_TimerToken{.cdecl, 
    dynlib: dllName, importc.}
proc Tcl_DeleteTimerHandler*(token: Tcl_TimerToken){.cdecl, dynlib: dllName, 
    importc.}
  #    procedure Tcl_CreateModalTimeout(milliseconds: integer; prc: TTclTimerProc; clientData: Tcl_ClientData); cdecl; external dllName;
  #    procedure Tcl_DeleteModalTimeout(prc: TTclTimerProc; clientData: Tcl_ClientData); cdecl; external dllName;
proc Tcl_SplitList*(interp: pTcl_Interp, list: cstring, argcPtr: var int, 
                    argvPtr: var Tcl_Argv): int{.cdecl, dynlib: dllName, 
    importc.}
proc Tcl_Merge*(argc: int, argv: Tcl_Argv): cstring{.cdecl, dynlib: dllName, 
    importc.}
proc Tcl_Free*(p: cstring){.cdecl, dynlib: dllName, importc.}
proc Tcl_Init*(interp: pTcl_Interp): int{.cdecl, dynlib: dllName, importc.}
  #    procedure Tcl_InterpDeleteProc(clientData: Tcl_ClientData; interp: pTcl_Interp); cdecl; external dllName;
proc Tcl_GetAssocData*(interp: pTcl_Interp, key: cstring, 
                       prc: var TTclInterpDeleteProc): Tcl_ClientData{.cdecl, 
    dynlib: dllName, importc.}
proc Tcl_DeleteAssocData*(interp: pTcl_Interp, key: cstring){.cdecl, 
    dynlib: dllName, importc.}
proc Tcl_SetAssocData*(interp: pTcl_Interp, key: cstring, 
                       prc: TTclInterpDeleteProc, clientData: Tcl_ClientData){.
    cdecl, dynlib: dllName, importc.}
proc Tcl_IsSafe*(interp: pTcl_Interp): int{.cdecl, dynlib: dllName, importc.}
proc Tcl_MakeSafe*(interp: pTcl_Interp): int{.cdecl, dynlib: dllName, 
    importc.}
proc Tcl_CreateSlave*(interp: pTcl_Interp, slaveName: cstring, isSafe: int): pTcl_Interp{.
    cdecl, dynlib: dllName, importc.}
proc Tcl_GetSlave*(interp: pTcl_Interp, slaveName: cstring): pTcl_Interp{.cdecl, 
    dynlib: dllName, importc.}
proc Tcl_GetMaster*(interp: pTcl_Interp): pTcl_Interp{.cdecl, 
    dynlib: dllName, importc.}
proc Tcl_GetInterpPath*(askingInterp: pTcl_Interp, slaveInterp: pTcl_Interp): int{.
    cdecl, dynlib: dllName, importc.}
proc Tcl_CreateAlias*(slaveInterp: pTcl_Interp, srcCmd: cstring, 
                      targetInterp: pTcl_Interp, targetCmd: cstring, argc: int, 
                      argv: Tcl_Argv): int{.cdecl, dynlib: dllName, importc.}
proc Tcl_GetAlias*(interp: pTcl_Interp, srcCmd: cstring, 
                   targetInterp: var pTcl_Interp, targetCmd: var cstring, 
                   argc: var int, argv: var Tcl_Argv): int{.cdecl, 
    dynlib: dllName, importc.}
proc Tcl_ExposeCommand*(interp: pTcl_Interp, hiddenCmdName: cstring, 
                        cmdName: cstring): int{.cdecl, dynlib: dllName, 
    importc.}
proc Tcl_HideCommand*(interp: pTcl_Interp, cmdName: cstring, 
                      hiddenCmdName: cstring): int{.cdecl, dynlib: dllName, 
    importc.}
proc Tcl_EventuallyFree*(clientData: Tcl_ClientData, freeProc: TTclFreeProc){.
    cdecl, dynlib: dllName, importc.}
proc Tcl_Preserve*(clientData: Tcl_ClientData){.cdecl, dynlib: dllName, 
    importc.}
proc Tcl_Release*(clientData: Tcl_ClientData){.cdecl, dynlib: dllName, 
    importc.}
proc Tcl_InterpDeleted*(interp: pTcl_Interp): int{.cdecl, dynlib: dllName, 
    importc.}
proc Tcl_GetCommandInfo*(interp: pTcl_Interp, cmdName: cstring, 
                         info: var Tcl_CmdInfo): int{.cdecl, 
    dynlib: dllName, importc.}
proc Tcl_SetCommandInfo*(interp: pTcl_Interp, cmdName: cstring, 
                         info: var Tcl_CmdInfo): int{.cdecl, 
    dynlib: dllName, importc.}
proc Tcl_FindExecutable*(path: cstring){.cdecl, dynlib: dllName, importc.}
proc Tcl_GetStringResult*(interp: pTcl_Interp): cstring{.cdecl, 
    dynlib: dllName, importc.}
  #v1.0
proc Tcl_FindCommand*(interp: pTcl_Interp, cmdName: cstring, 
                      contextNsPtr: pTcl_Namespace, flags: int): Tcl_Command{.
    cdecl, dynlib: dllName, importc.}
  #v1.0
proc Tcl_DeleteCommandFromToken*(interp: pTcl_Interp, cmd: pTcl_Command): int{.
    cdecl, dynlib: dllName, importc.}
proc Tcl_CreateNamespace*(interp: pTcl_Interp, name: cstring, 
                          clientData: Tcl_ClientData, 
                          deleteProc: TTclNamespaceDeleteProc): pTcl_Namespace{.
    cdecl, dynlib: dllName, importc.}
  #v1.0
proc Tcl_DeleteNamespace*(namespacePtr: pTcl_Namespace){.cdecl, 
    dynlib: dllName, importc.}
proc Tcl_FindNamespace*(interp: pTcl_Interp, name: cstring, 
                        contextNsPtr: pTcl_Namespace, flags: int): pTcl_Namespace{.
    cdecl, dynlib: dllName, importc.}
proc Tcl_Export*(interp: pTcl_Interp, namespacePtr: pTcl_Namespace, 
                 pattern: cstring, resetListFirst: int): int{.cdecl, 
    dynlib: dllName, importc.}
proc Tcl_Import*(interp: pTcl_Interp, namespacePtr: pTcl_Namespace, 
                 pattern: cstring, allowOverwrite: int): int{.cdecl, 
    dynlib: dllName, importc.}
proc Tcl_GetCurrentNamespace*(interp: pTcl_Interp): pTcl_Namespace{.cdecl, 
    dynlib: dllName, importc.}
proc Tcl_GetGlobalNamespace*(interp: pTcl_Interp): pTcl_Namespace{.cdecl, 
    dynlib: dllName, importc.}
proc Tcl_PushCallFrame*(interp: pTcl_Interp, callFramePtr: var Tcl_CallFrame, 
                        namespacePtr: pTcl_Namespace, isProcCallFrame: int): int{.
    cdecl, dynlib: dllName, importc.}
proc Tcl_PopCallFrame*(interp: pTcl_Interp){.cdecl, dynlib: dllName, importc.}
proc Tcl_VarEval*(interp: pTcl_Interp): int{.cdecl, varargs, 
    dynlib: dllName, importc.}
  # For TkConsole.c *
proc Tcl_RecordAndEval*(interp: pTcl_Interp, cmd: cstring, flags: int): int{.
    cdecl, dynlib: dllName, importc.}
proc Tcl_GlobalEval*(interp: pTcl_Interp, command: cstring): int{.cdecl, 
    dynlib: dllName, importc.}
proc Tcl_DStringFree*(dsPtr: pTcl_DString){.cdecl, dynlib: dllName, importc.}
proc Tcl_DStringAppend*(dsPtr: pTcl_DString, str: cstring, length: int): cstring{.
    cdecl, dynlib: dllName, importc.}
proc Tcl_DStringAppendElement*(dsPtr: pTcl_DString, str: cstring): cstring{.
    cdecl, dynlib: dllName, importc.}
proc Tcl_DStringInit*(dsPtr: pTcl_DString){.cdecl, dynlib: dllName, importc.}
proc Tcl_AppendResult*(interp: pTcl_Interp){.cdecl, varargs, 
    dynlib: dllName, importc.}
  # actually a "C" var array
proc Tcl_SetStdChannel*(channel: pTcl_Channel, typ: int){.cdecl, 
    dynlib: dllName, importc.}
proc Tcl_SetChannelOption*(interp: pTcl_Interp, chan: pTcl_Channel, 
                           optionName: cstring, newValue: cstring): int{.cdecl, 
    dynlib: dllName, importc.}
proc Tcl_GetChannelOption*(interp: pTcl_Interp, chan: pTcl_Channel, 
                           optionName: cstring, dsPtr: pTcl_DString): int{.
    cdecl, dynlib: dllName, importc.}
proc Tcl_CreateChannel*(typePtr: pTcl_ChannelType, chanName: cstring, 
                        instanceData: Tcl_ClientData, mask: int): pTcl_Channel{.
    cdecl, dynlib: dllName, importc.}
proc Tcl_RegisterChannel*(interp: pTcl_Interp, channel: pTcl_Channel){.cdecl, 
    dynlib: dllName, importc.}
proc Tcl_UnregisterChannel*(interp: pTcl_Interp, channel: pTcl_Channel): int{.
    cdecl, dynlib: dllName, importc.}
proc Tcl_CreateChannelHandler*(chan: pTcl_Channel, mask: int, 
                               prc: TTclChannelProc, clientData: Tcl_ClientData){.
    cdecl, dynlib: dllName, importc.}
proc Tcl_GetChannel*(interp: pTcl_Interp, chanName: cstring, modePtr: pInteger): pTcl_Channel{.
    cdecl, dynlib: dllName, importc.}
proc Tcl_GetStdChannel*(typ: int): pTcl_Channel{.cdecl, dynlib: dllName, 
    importc.}
proc Tcl_Gets*(chan: pTcl_Channel, dsPtr: pTcl_DString): int{.cdecl, 
    dynlib: dllName, importc.}
proc Tcl_Write*(chan: pTcl_Channel, s: cstring, slen: int): int{.cdecl, 
    dynlib: dllName, importc.}
proc Tcl_Flush*(chan: pTcl_Channel): int{.cdecl, dynlib: dllName, importc.}
  #    TclWinLoadLibrary      = function(name: PChar): HMODULE; cdecl; external dllName;
proc Tcl_CreateExitHandler*(prc: TTclClientDataProc, clientData: Tcl_ClientData){.
    cdecl, dynlib: dllName, importc.}
proc Tcl_DeleteExitHandler*(prc: TTclClientDataProc, clientData: Tcl_ClientData){.
    cdecl, dynlib: dllName, importc.}
proc Tcl_GetStringFromObj*(pObj: pTcl_Obj, pLen: pInteger): cstring{.cdecl, 
    dynlib: dllName, importc.}
proc Tcl_CreateObjCommand*(interp: pTcl_Interp, name: cstring, 
                           cmdProc: TTclObjCmdProc, clientData: Tcl_ClientData, 
                           deleteProc: TTclCmdDeleteProc): pTcl_Command{.cdecl, 
    dynlib: dllName, importc.}
proc Tcl_NewStringObj*(bytes: cstring, length: int): pTcl_Obj{.cdecl, 
    dynlib: dllName, importc.}
  #    procedure TclFreeObj(pObj: pTcl_Obj); cdecl; external dllName;
proc Tcl_EvalObj*(interp: pTcl_Interp, pObj: pTcl_Obj): int{.cdecl, 
    dynlib: dllName, importc.}
proc Tcl_GlobalEvalObj*(interp: pTcl_Interp, pObj: pTcl_Obj): int{.cdecl, 
    dynlib: dllName, importc.}
proc TclRegComp*(exp: cstring): pointer{.cdecl, dynlib: dllName, importc.}
proc TclRegExec*(prog: pointer, str: cstring, start: cstring): int{.cdecl, 
    dynlib: dllName, importc.}
proc TclRegError*(msg: cstring){.cdecl, dynlib: dllName, importc.}
proc TclGetRegError*(): cstring{.cdecl, dynlib: dllName, importc.}
proc Tcl_RegExpRange*(prog: pointer, index: int, head: var cstring, 
                      tail: var cstring){.cdecl, dynlib: dllName, importc.}

proc Tcl_GetCommandTable*(interp: pTcl_Interp): pHashTable =
  if interp != nil: 
    result = cast[pHashTable](cast[int](interp) + sizeof(Tcl_Interp) + 
      sizeof(pointer))

proc Tcl_CreateHashEntry*(tablePtr: pTcl_HashTable, key: cstring, 
                          newPtr: pInteger): pTcl_HashEntry =
  result = cast[pHashTable](tablePtr).createProc(tablePtr, key, newPtr)
                          
proc Tcl_FindHashEntry*(tablePtr: pTcl_HashTable, 
                        key: cstring): pTcl_HashEntry =
  result = cast[pHashTable](tablePtr).findProc(tablePtr, key)

proc Tcl_SetHashValue*(h: pTcl_HashEntry, clientData: Tcl_ClientData) =
  h.clientData = clientData

proc Tcl_GetHashValue*(h: pTcl_HashEntry): Tcl_ClientData =
  result = h.clientData

proc Tcl_IncrRefCount*(pObj: pTcl_Obj) =
  inc(pObj.refCount)

proc Tcl_DecrRefCount*(pObj: pTcl_Obj) =
  dec(pObj.refCount)
  if pObj.refCount <= 0: 
    dealloc(pObj)

proc Tcl_IsShared*(pObj: pTcl_Obj): bool = 
  return pObj.refCount > 1

proc Tcl_GetHashKey*(hashTbl: pTcl_HashTable, 
                     hashEntry: pTcl_HashEntry): cstring = 
  if hashTbl == nil or hashEntry == nil: 
    result = nil
  else: 
    result = hashEntry.key
  
