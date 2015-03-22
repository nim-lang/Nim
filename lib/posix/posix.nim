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

{.deadCodeElim:on.}

from times import Time

const
  hasSpawnH = not defined(haiku) # should exist for every Posix system nowadays
  hasAioH = defined(linux)

when false:
  const
    C_IRUSR = 0c000400 ## Read by owner.
    C_IWUSR = 0c000200 ## Write by owner.
    C_IXUSR = 0c000100 ## Execute by owner.
    C_IRGRP = 0c000040 ## Read by group.
    C_IWGRP = 0c000020 ## Write by group.
    C_IXGRP = 0c000010 ## Execute by group.
    C_IROTH = 0c000004 ## Read by others.
    C_IWOTH = 0c000002 ## Write by others.
    C_IXOTH = 0c000001 ## Execute by others.
    C_ISUID = 0c004000 ## Set user ID.
    C_ISGID = 0c002000 ## Set group ID.
    C_ISVTX = 0c001000 ## On directories, restricted deletion flag.
    C_ISDIR = 0c040000 ## Directory.
    C_ISFIFO = 0c010000 ##FIFO.
    C_ISREG = 0c100000 ## Regular file.
    C_ISBLK = 0c060000 ## Block special.
    C_ISCHR = 0c020000 ## Character special.
    C_ISCTG = 0c110000 ## Reserved.
    C_ISLNK = 0c120000 ## Symbolic link.</p>
    C_ISSOCK = 0c140000 ## Socket.

const
  MM_NULLLBL* = nil
  MM_NULLSEV* = 0
  MM_NULLMC* = 0
  MM_NULLTXT* = nil
  MM_NULLACT* = nil
  MM_NULLTAG* = nil

  STDERR_FILENO* = 2 ## File number of stderr;
  STDIN_FILENO* = 0  ## File number of stdin;
  STDOUT_FILENO* = 1 ## File number of stdout;

  DT_UNKNOWN* = 0 ## Unknown file type.
  DT_FIFO* = 1    ## Named pipe, or FIFO.
  DT_CHR* = 2     ## Character device.
  DT_DIR* = 4     ## Directory.
  DT_BLK* = 6     ## Block device.
  DT_REG* = 8     ## Regular file.
  DT_LNK* = 10    ## Symbolic link.
  DT_SOCK* = 12   ## UNIX domain socket.
  DT_WHT* = 14

type
  TDIR* {.importc: "DIR", header: "<dirent.h>",
          incompleteStruct.} = object
    ## A type representing a directory stream.

type
  SocketHandle* = distinct cint # The type used to represent socket descriptors

{.deprecated: [TSocketHandle: SocketHandle].}

type
  Tdirent* {.importc: "struct dirent",
             header: "<dirent.h>", final, pure.} = object ## dirent_t struct
    d_ino*: Tino  ## File serial number.
    when defined(linux) or defined(macosx) or defined(bsd):
      d_off*: TOff  ## Not an offset. Value that ``telldir()`` would return.
      d_reclen*: cshort ## Length of this record. (not POSIX)
      d_type*: int8 ## Type of file; not supported by all filesystem types.
                    ## (not POSIX)
    d_name*: array [0..255, char] ## Name of entry.

  Tflock* {.importc: "struct flock", final, pure,
            header: "<fcntl.h>".} = object ## flock type
    l_type*: cshort   ## Type of lock; F_RDLCK, F_WRLCK, F_UNLCK.
    l_whence*: cshort ## Flag for starting offset.
    l_start*: TOff    ## Relative offset in bytes.
    l_len*: TOff      ## Size; if 0 then until EOF.
    l_pid*: TPid      ## Process ID of the process holding the lock;
                      ## returned with F_GETLK.

  TFTW* {.importc: "struct FTW", header: "<ftw.h>", final, pure.} = object
    base*: cint
    level*: cint

  TGlob* {.importc: "glob_t", header: "<glob.h>",
           final, pure.} = object ## glob_t
    gl_pathc*: int          ## Count of paths matched by pattern.
    gl_pathv*: cstringArray ## Pointer to a list of matched pathnames.
    gl_offs*: int           ## Slots to reserve at the beginning of gl_pathv.

  TGroup* {.importc: "struct group", header: "<grp.h>",
            final, pure.} = object ## struct group
    gr_name*: cstring     ## The name of the group.
    gr_gid*: TGid         ## Numerical group ID.
    gr_mem*: cstringArray ## Pointer to a null-terminated array of character
                          ## pointers to member names.

  Ticonv* {.importc: "iconv_t", header: "<iconv.h>", final, pure.} =
    object ## Identifies the conversion from one codeset to another.

  Tlconv* {.importc: "struct lconv", header: "<locale.h>", final,
            pure.} = object
    currency_symbol*: cstring
    decimal_point*: cstring
    frac_digits*: char
    grouping*: cstring
    int_curr_symbol*: cstring
    int_frac_digits*: char
    int_n_cs_precedes*: char
    int_n_sep_by_space*: char
    int_n_sign_posn*: char
    int_p_cs_precedes*: char
    int_p_sep_by_space*: char
    int_p_sign_posn*: char
    mon_decimal_point*: cstring
    mon_grouping*: cstring
    mon_thousands_sep*: cstring
    negative_sign*: cstring
    n_cs_precedes*: char
    n_sep_by_space*: char
    n_sign_posn*: char
    positive_sign*: cstring
    p_cs_precedes*: char
    p_sep_by_space*: char
    p_sign_posn*: char
    thousands_sep*: cstring

  TMqd* {.importc: "mqd_t", header: "<mqueue.h>", final, pure.} = object
  TMqAttr* {.importc: "struct mq_attr",
             header: "<mqueue.h>",
             final, pure.} = object ## message queue attribute
    mq_flags*: int   ## Message queue flags.
    mq_maxmsg*: int  ## Maximum number of messages.
    mq_msgsize*: int ## Maximum message size.
    mq_curmsgs*: int ## Number of messages currently queued.

  TPasswd* {.importc: "struct passwd", header: "<pwd.h>",
             final, pure.} = object ## struct passwd
    pw_name*: cstring   ## User's login name.
    pw_uid*: Tuid       ## Numerical user ID.
    pw_gid*: TGid       ## Numerical group ID.
    pw_dir*: cstring    ## Initial working directory.
    pw_shell*: cstring  ## Program to use as shell.

  Tblkcnt* {.importc: "blkcnt_t", header: "<sys/types.h>".} = int
    ## used for file block counts
  Tblksize* {.importc: "blksize_t", header: "<sys/types.h>".} = int
    ## used for block sizes
  TClock* {.importc: "clock_t", header: "<sys/types.h>".} = int
  TClockId* {.importc: "clockid_t", header: "<sys/types.h>".} = int
  TDev* {.importc: "dev_t", header: "<sys/types.h>".} = int
  Tfsblkcnt* {.importc: "fsblkcnt_t", header: "<sys/types.h>".} = int
  Tfsfilcnt* {.importc: "fsfilcnt_t", header: "<sys/types.h>".} = int
  TGid* {.importc: "gid_t", header: "<sys/types.h>".} = int
  Tid* {.importc: "id_t", header: "<sys/types.h>".} = int
  Tino* {.importc: "ino_t", header: "<sys/types.h>".} = int
  TKey* {.importc: "key_t", header: "<sys/types.h>".} = int
  TMode* {.importc: "mode_t", header: "<sys/types.h>".} = cint
  TNlink* {.importc: "nlink_t", header: "<sys/types.h>".} = int
  TOff* {.importc: "off_t", header: "<sys/types.h>".} = int64
  TPid* {.importc: "pid_t", header: "<sys/types.h>".} = int
  Tpthread_attr* {.importc: "pthread_attr_t", header: "<sys/types.h>".} = int
  Tpthread_barrier* {.importc: "pthread_barrier_t",
                      header: "<sys/types.h>".} = int
  Tpthread_barrierattr* {.importc: "pthread_barrierattr_t",
                          header: "<sys/types.h>".} = int
  Tpthread_cond* {.importc: "pthread_cond_t", header: "<sys/types.h>".} = int
  Tpthread_condattr* {.importc: "pthread_condattr_t",
                       header: "<sys/types.h>".} = int
  Tpthread_key* {.importc: "pthread_key_t", header: "<sys/types.h>".} = int
  Tpthread_mutex* {.importc: "pthread_mutex_t", header: "<sys/types.h>".} = int
  Tpthread_mutexattr* {.importc: "pthread_mutexattr_t",
                        header: "<sys/types.h>".} = int
  Tpthread_once* {.importc: "pthread_once_t", header: "<sys/types.h>".} = int
  Tpthread_rwlock* {.importc: "pthread_rwlock_t",
                     header: "<sys/types.h>".} = int
  Tpthread_rwlockattr* {.importc: "pthread_rwlockattr_t",
                         header: "<sys/types.h>".} = int
  Tpthread_spinlock* {.importc: "pthread_spinlock_t",
                       header: "<sys/types.h>".} = int
  Tpthread* {.importc: "pthread_t", header: "<sys/types.h>".} = int
  Tsuseconds* {.importc: "suseconds_t", header: "<sys/types.h>".} = int
  #Ttime* {.importc: "time_t", header: "<sys/types.h>".} = int
  Ttimer* {.importc: "timer_t", header: "<sys/types.h>".} = int
  Ttrace_attr* {.importc: "trace_attr_t", header: "<sys/types.h>".} = int
  Ttrace_event_id* {.importc: "trace_event_id_t",
                     header: "<sys/types.h>".} = int
  Ttrace_event_set* {.importc: "trace_event_set_t",
                      header: "<sys/types.h>".} = int
  Ttrace_id* {.importc: "trace_id_t", header: "<sys/types.h>".} = int
  Tuid* {.importc: "uid_t", header: "<sys/types.h>".} = int
  Tuseconds* {.importc: "useconds_t", header: "<sys/types.h>".} = int

  Tutsname* {.importc: "struct utsname",
              header: "<sys/utsname.h>",
              final, pure.} = object ## struct utsname
    sysname*,      ## Name of this implementation of the operating system.
      nodename*,   ## Name of this node within the communications
                   ## network to which this node is attached, if any.
      release*,    ## Current release level of this implementation.
      version*,    ## Current version level of this release.
      machine*: array [0..255, char] ## Name of the hardware type on which the
                                     ## system is running.

  TSem* {.importc: "sem_t", header: "<semaphore.h>", final, pure.} = object
  Tipc_perm* {.importc: "struct ipc_perm",
               header: "<sys/ipc.h>", final, pure.} = object ## struct ipc_perm
    uid*: Tuid    ## Owner's user ID.
    gid*: TGid    ## Owner's group ID.
    cuid*: Tuid   ## Creator's user ID.
    cgid*: TGid   ## Creator's group ID.
    mode*: TMode  ## Read/write permission.

  TStat* {.importc: "struct stat",
           header: "<sys/stat.h>", final, pure.} = object ## struct stat
    st_dev*: TDev          ## Device ID of device containing file.
    st_ino*: Tino          ## File serial number.
    st_mode*: TMode        ## Mode of file (see below).
    st_nlink*: TNlink      ## Number of hard links to the file.
    st_uid*: Tuid          ## User ID of file.
    st_gid*: TGid          ## Group ID of file.
    st_rdev*: TDev         ## Device ID (if file is character or block special).
    st_size*: TOff         ## For regular files, the file size in bytes.
                           ## For symbolic links, the length in bytes of the
                           ## pathname contained in the symbolic link.
                           ## For a shared memory object, the length in bytes.
                           ## For a typed memory object, the length in bytes.
                           ## For other file types, the use of this field is
                           ## unspecified.
    st_atime*: Time        ## Time of last access.
    st_mtime*: Time        ## Time of last data modification.
    st_ctime*: Time        ## Time of last status change.
    st_blksize*: Tblksize  ## A file system-specific preferred I/O block size
                           ## for this object. In some file system types, this
                           ## may vary from file to file.
    st_blocks*: Tblkcnt    ## Number of blocks allocated for this object.


  TStatvfs* {.importc: "struct statvfs", header: "<sys/statvfs.h>",
              final, pure.} = object ## struct statvfs
    f_bsize*: int        ## File system block size.
    f_frsize*: int       ## Fundamental file system block size.
    f_blocks*: Tfsblkcnt ## Total number of blocks on file system
                         ## in units of f_frsize.
    f_bfree*: Tfsblkcnt  ## Total number of free blocks.
    f_bavail*: Tfsblkcnt ## Number of free blocks available to
                         ## non-privileged process.
    f_files*: Tfsfilcnt  ## Total number of file serial numbers.
    f_ffree*: Tfsfilcnt  ## Total number of free file serial numbers.
    f_favail*: Tfsfilcnt ## Number of file serial numbers available to
                         ## non-privileged process.
    f_fsid*: int         ## File system ID.
    f_flag*: int         ## Bit mask of f_flag values.
    f_namemax*: int      ## Maximum filename length.

  Tposix_typed_mem_info* {.importc: "struct posix_typed_mem_info",
                           header: "<sys/mman.h>", final, pure.} = object
    posix_tmi_length*: int

  Ttm* {.importc: "struct tm", header: "<time.h>",
         final, pure.} = object ## struct tm
    tm_sec*: cint   ## Seconds [0,60].
    tm_min*: cint   ## Minutes [0,59].
    tm_hour*: cint  ## Hour [0,23].
    tm_mday*: cint  ## Day of month [1,31].
    tm_mon*: cint   ## Month of year [0,11].
    tm_year*: cint  ## Years since 1900.
    tm_wday*: cint  ## Day of week [0,6] (Sunday =0).
    tm_yday*: cint  ## Day of year [0,365].
    tm_isdst*: cint ## Daylight Savings flag.
  Ttimespec* {.importc: "struct timespec",
               header: "<time.h>", final, pure.} = object ## struct timespec
    tv_sec*: Time  ## Seconds.
    tv_nsec*: int  ## Nanoseconds.
  titimerspec* {.importc: "struct itimerspec", header: "<time.h>",
                 final, pure.} = object ## struct itimerspec
    it_interval*: Ttimespec ## Timer period.
    it_value*: Ttimespec    ## Timer expiration.

  Tsig_atomic* {.importc: "sig_atomic_t", header: "<signal.h>".} = cint
    ## Possibly volatile-qualified integer type of an object that can be
    ## accessed as an atomic entity, even in the presence of asynchronous
    ## interrupts.
  Tsigset* {.importc: "sigset_t", header: "<signal.h>", final, pure.} = object

  TsigEvent* {.importc: "struct sigevent",
               header: "<signal.h>", final, pure.} = object ## struct sigevent
    sigev_notify*: cint           ## Notification type.
    sigev_signo*: cint            ## Signal number.
    sigev_value*: TsigVal         ## Signal value.
    sigev_notify_function*: proc (x: TsigVal) {.noconv.} ## Notification func.
    sigev_notify_attributes*: ptr Tpthread_attr ## Notification attributes.

  TsigVal* {.importc: "union sigval",
             header: "<signal.h>", final, pure.} = object ## struct sigval
    sival_ptr*: pointer ## pointer signal value;
                        ## integer signal value not defined!
  TSigaction* {.importc: "struct sigaction",
                header: "<signal.h>", final, pure.} = object ## struct sigaction
    sa_handler*: proc (x: cint) {.noconv.}  ## Pointer to a signal-catching
                                            ## function or one of the macros
                                            ## SIG_IGN or SIG_DFL.
    sa_mask*: Tsigset ## Set of signals to be blocked during execution of
                      ## the signal handling function.
    sa_flags*: cint   ## Special flags.
    sa_sigaction*: proc (x: cint, y: var TsigInfo, z: pointer) {.noconv.}

  TStack* {.importc: "stack_t",
            header: "<signal.h>", final, pure.} = object ## stack_t
    ss_sp*: pointer  ## Stack base or pointer.
    ss_size*: int    ## Stack size.
    ss_flags*: cint  ## Flags.

  TSigStack* {.importc: "struct sigstack",
               header: "<signal.h>", final, pure.} = object ## struct sigstack
    ss_onstack*: cint ## Non-zero when signal stack is in use.
    ss_sp*: pointer   ## Signal stack pointer.

  TsigInfo* {.importc: "siginfo_t",
              header: "<signal.h>", final, pure.} = object ## siginfo_t
    si_signo*: cint    ## Signal number.
    si_code*: cint     ## Signal code.
    si_errno*: cint    ## If non-zero, an errno value associated with
                       ## this signal, as defined in <errno.h>.
    si_pid*: TPid      ## Sending process ID.
    si_uid*: Tuid      ## Real user ID of sending process.
    si_addr*: pointer  ## Address of faulting instruction.
    si_status*: cint   ## Exit value or signal.
    si_band*: int      ## Band event for SIGPOLL.
    si_value*: TsigVal ## Signal value.

  Tnl_item* {.importc: "nl_item", header: "<nl_types.h>".} = cint
  Tnl_catd* {.importc: "nl_catd", header: "<nl_types.h>".} = cint

  Tsched_param* {.importc: "struct sched_param",
                  header: "<sched.h>",
                  final, pure.} = object ## struct sched_param
    sched_priority*: cint
    sched_ss_low_priority*: cint     ## Low scheduling priority for
                                     ## sporadic server.
    sched_ss_repl_period*: Ttimespec ## Replenishment period for
                                     ## sporadic server.
    sched_ss_init_budget*: Ttimespec ## Initial budget for sporadic server.
    sched_ss_max_repl*: cint         ## Maximum pending replenishments for
                                     ## sporadic server.

  Timeval* {.importc: "struct timeval", header: "<sys/select.h>",
             final, pure.} = object ## struct timeval
    tv_sec*: int       ## Seconds.
    tv_usec*: int ## Microseconds.
  TFdSet* {.importc: "fd_set", header: "<sys/select.h>",
           final, pure.} = object
  Tmcontext* {.importc: "mcontext_t", header: "<ucontext.h>",
               final, pure.} = object
  Tucontext* {.importc: "ucontext_t", header: "<ucontext.h>",
               final, pure.} = object ## ucontext_t
    uc_link*: ptr Tucontext ## Pointer to the context that is resumed
                            ## when this context returns.
    uc_sigmask*: Tsigset    ## The set of signals that are blocked when this
                            ## context is active.
    uc_stack*: TStack       ## The stack used by this context.
    uc_mcontext*: Tmcontext ## A machine-specific representation of the saved
                            ## context.

when hasAioH:
  type
    Taiocb* {.importc: "struct aiocb", header: "<aio.h>",
              final, pure.} = object ## struct aiocb
      aio_fildes*: cint         ## File descriptor.
      aio_offset*: TOff         ## File offset.
      aio_buf*: pointer         ## Location of buffer.
      aio_nbytes*: int          ## Length of transfer.
      aio_reqprio*: cint        ## Request priority offset.
      aio_sigevent*: TsigEvent  ## Signal number and value.
      aio_lio_opcode: cint      ## Operation to be performed.

when hasSpawnH:
  type
    Tposix_spawnattr* {.importc: "posix_spawnattr_t",
                        header: "<spawn.h>", final, pure.} = object
    Tposix_spawn_file_actions* {.importc: "posix_spawn_file_actions_t",
                                 header: "<spawn.h>", final, pure.} = object

type
  Socklen* {.importc: "socklen_t", header: "<sys/socket.h>".} = cuint
  TSa_Family* {.importc: "sa_family_t", header: "<sys/socket.h>".} = cint

  SockAddr* {.importc: "struct sockaddr", header: "<sys/socket.h>",
              pure, final.} = object ## struct sockaddr
    sa_family*: TSa_Family         ## Address family.
    sa_data*: array [0..255, char] ## Socket address (variable-length data).

  Tsockaddr_storage* {.importc: "struct sockaddr_storage",
                       header: "<sys/socket.h>",
                       pure, final.} = object ## struct sockaddr_storage
    ss_family*: TSa_Family ## Address family.

  Tif_nameindex* {.importc: "struct if_nameindex", final,
                   pure, header: "<net/if.h>".} = object ## struct if_nameindex
    if_index*: cint   ## Numeric index of the interface.
    if_name*: cstring ## Null-terminated name of the interface.


  TIOVec* {.importc: "struct iovec", pure, final,
            header: "<sys/uio.h>".} = object ## struct iovec
    iov_base*: pointer ## Base address of a memory region for input or output.
    iov_len*: int    ## The size of the memory pointed to by iov_base.

  Tmsghdr* {.importc: "struct msghdr", pure, final,
             header: "<sys/socket.h>".} = object  ## struct msghdr
    msg_name*: pointer  ## Optional address.
    msg_namelen*: Socklen  ## Size of address.
    msg_iov*: ptr TIOVec    ## Scatter/gather array.
    msg_iovlen*: cint   ## Members in msg_iov.
    msg_control*: pointer  ## Ancillary data; see below.
    msg_controllen*: Socklen ## Ancillary data buffer len.
    msg_flags*: cint ## Flags on received message.


  Tcmsghdr* {.importc: "struct cmsghdr", pure, final,
              header: "<sys/socket.h>".} = object ## struct cmsghdr
    cmsg_len*: Socklen ## Data byte count, including the cmsghdr.
    cmsg_level*: cint   ## Originating protocol.
    cmsg_type*: cint    ## Protocol-specific type.

  TLinger* {.importc: "struct linger", pure, final,
             header: "<sys/socket.h>".} = object ## struct linger
    l_onoff*: cint  ## Indicates whether linger option is enabled.
    l_linger*: cint ## Linger time, in seconds.

  TInPort* = int16 ## unsigned!
  TInAddrScalar* = int32 ## unsigned!

  TInAddrT* {.importc: "in_addr_t", pure, final,
             header: "<netinet/in.h>".} = int32 ## unsigned!

  InAddr* {.importc: "struct in_addr", pure, final,
             header: "<netinet/in.h>".} = object ## struct in_addr
    s_addr*: TInAddrScalar

  Sockaddr_in* {.importc: "struct sockaddr_in", pure, final,
                  header: "<netinet/in.h>".} = object ## struct sockaddr_in
    sin_family*: TSa_Family ## AF_INET.
    sin_port*: TInPort      ## Port number.
    sin_addr*: InAddr      ## IP address.

  TIn6Addr* {.importc: "struct in6_addr", pure, final,
              header: "<netinet/in.h>".} = object ## struct in6_addr
    s6_addr*: array [0..15, char]

  Tsockaddr_in6* {.importc: "struct sockaddr_in6", pure, final,
                   header: "<netinet/in.h>".} = object ## struct sockaddr_in6
    sin6_family*: TSa_Family ## AF_INET6.
    sin6_port*: TInPort      ## Port number.
    sin6_flowinfo*: int32    ## IPv6 traffic class and flow information.
    sin6_addr*: TIn6Addr     ## IPv6 address.
    sin6_scope_id*: int32    ## Set of interfaces for a scope.

  Tipv6_mreq* {.importc: "struct ipv6_mreq", pure, final,
                header: "<netinet/in.h>".} = object ## struct ipv6_mreq
    ipv6mr_multiaddr*: TIn6Addr ## IPv6 multicast address.
    ipv6mr_interface*: cint     ## Interface index.

  Hostent* {.importc: "struct hostent", pure, final,
              header: "<netdb.h>".} = object ## struct hostent
    h_name*: cstring           ## Official name of the host.
    h_aliases*: cstringArray   ## A pointer to an array of pointers to
                               ## alternative host names, terminated by a
                               ## null pointer.
    h_addrtype*: cint          ## Address type.
    h_length*: cint            ## The length, in bytes, of the address.
    h_addr_list*: cstringArray ## A pointer to an array of pointers to network
                               ## addresses (in network byte order) for the
                               ## host, terminated by a null pointer.

  Tnetent* {.importc: "struct netent", pure, final,
              header: "<netdb.h>".} = object ## struct netent
    n_name*: cstring         ## Official, fully-qualified (including the
                             ## domain) name of the host.
    n_aliases*: cstringArray ## A pointer to an array of pointers to
                             ## alternative network names, terminated by a
                             ## null pointer.
    n_addrtype*: cint        ## The address type of the network.
    n_net*: int32            ## The network number, in host byte order.

  TProtoent* {.importc: "struct protoent", pure, final,
              header: "<netdb.h>".} = object ## struct protoent
    p_name*: cstring         ## Official name of the protocol.
    p_aliases*: cstringArray ## A pointer to an array of pointers to
                             ## alternative protocol names, terminated by
                             ## a null pointer.
    p_proto*: cint           ## The protocol number.

  Servent* {.importc: "struct servent", pure, final,
             header: "<netdb.h>".} = object ## struct servent
    s_name*: cstring         ## Official name of the service.
    s_aliases*: cstringArray ## A pointer to an array of pointers to
                             ## alternative service names, terminated by
                             ## a null pointer.
    s_port*: cint            ## The port number at which the service
                             ## resides, in network byte order.
    s_proto*: cstring        ## The name of the protocol to use when
                             ## contacting the service.

  AddrInfo* {.importc: "struct addrinfo", pure, final,
              header: "<netdb.h>".} = object ## struct addrinfo
    ai_flags*: cint         ## Input flags.
    ai_family*: cint        ## Address family of socket.
    ai_socktype*: cint      ## Socket type.
    ai_protocol*: cint      ## Protocol of socket.
    ai_addrlen*: Socklen   ## Length of socket address.
    ai_addr*: ptr SockAddr ## Socket address of socket.
    ai_canonname*: cstring  ## Canonical name of service location.
    ai_next*: ptr AddrInfo ## Pointer to next in list.

  TPollfd* {.importc: "struct pollfd", pure, final,
             header: "<poll.h>".} = object ## struct pollfd
    fd*: cint        ## The following descriptor being polled.
    events*: cshort  ## The input event flags (see below).
    revents*: cshort ## The output event flags (see below).

  Tnfds* {.importc: "nfds_t", header: "<poll.h>".} = cint

{.deprecated: [TSockaddr_in: Sockaddr_in, TAddrinfo: AddrInfo,
    TSockAddr: SockAddr, TSockLen: SockLen, TTimeval: Timeval,
    Thostent: Hostent, TServent: Servent,
    TInAddr: InAddr].}

var
  errno* {.importc, header: "<errno.h>".}: cint ## error variable
  h_errno* {.importc, header: "<netdb.h>".}: cint
  daylight* {.importc, header: "<time.h>".}: cint
  timezone* {.importc, header: "<time.h>".}: int

# Constants as variables:
when hasAioH:
  var
    AIO_ALLDONE* {.importc, header: "<aio.h>".}: cint
      ## A return value indicating that none of the requested operations
      ## could be canceled since they are already complete.
    AIO_CANCELED* {.importc, header: "<aio.h>".}: cint
      ## A return value indicating that all requested operations have
      ## been canceled.
    AIO_NOTCANCELED* {.importc, header: "<aio.h>".}: cint
      ## A return value indicating that some of the requested operations could
      ## not be canceled since they are in progress.
    LIO_NOP* {.importc, header: "<aio.h>".}: cint
      ## A lio_listio() element operation option indicating that no transfer is
      ## requested.
    LIO_NOWAIT* {.importc, header: "<aio.h>".}: cint
      ## A lio_listio() synchronization operation indicating that the calling
      ## thread is to continue execution while the lio_listio() operation is
      ## being performed, and no notification is given when the operation is
      ## complete.
    LIO_READ* {.importc, header: "<aio.h>".}: cint
      ## A lio_listio() element operation option requesting a read.
    LIO_WAIT* {.importc, header: "<aio.h>".}: cint
      ## A lio_listio() synchronization operation indicating that the calling
      ## thread is to suspend until the lio_listio() operation is complete.
    LIO_WRITE* {.importc, header: "<aio.h>".}: cint
      ## A lio_listio() element operation option requesting a write.

var
  RTLD_LAZY* {.importc, header: "<dlfcn.h>".}: cint
    ## Relocations are performed at an implementation-defined time.
  RTLD_NOW* {.importc, header: "<dlfcn.h>".}: cint
    ## Relocations are performed when the object is loaded.
  RTLD_GLOBAL* {.importc, header: "<dlfcn.h>".}: cint
    ## All symbols are available for relocation processing of other modules.
  RTLD_LOCAL* {.importc, header: "<dlfcn.h>".}: cint
    ## All symbols are not made available for relocation processing by
    ## other modules.

  E2BIG* {.importc, header: "<errno.h>".}: cint
      ## Argument list too long.
  EACCES* {.importc, header: "<errno.h>".}: cint
      ## Permission denied.
  EADDRINUSE* {.importc, header: "<errno.h>".}: cint
      ## Address in use.
  EADDRNOTAVAIL* {.importc, header: "<errno.h>".}: cint
      ## Address not available.
  EAFNOSUPPORT* {.importc, header: "<errno.h>".}: cint
      ## Address family not supported.
  EAGAIN* {.importc, header: "<errno.h>".}: cint
      ## Resource unavailable, try again (may be the same value as EWOULDBLOCK).
  EALREADY* {.importc, header: "<errno.h>".}: cint
      ## Connection already in progress.
  EBADF* {.importc, header: "<errno.h>".}: cint
      ## Bad file descriptor.
  EBADMSG* {.importc, header: "<errno.h>".}: cint
      ## Bad message.
  EBUSY* {.importc, header: "<errno.h>".}: cint
      ## Device or resource busy.
  ECANCELED* {.importc, header: "<errno.h>".}: cint
      ## Operation canceled.
  ECHILD* {.importc, header: "<errno.h>".}: cint
      ## No child processes.
  ECONNABORTED* {.importc, header: "<errno.h>".}: cint
      ## Connection aborted.
  ECONNREFUSED* {.importc, header: "<errno.h>".}: cint
      ## Connection refused.
  ECONNRESET* {.importc, header: "<errno.h>".}: cint
      ## Connection reset.
  EDEADLK* {.importc, header: "<errno.h>".}: cint
      ## Resource deadlock would occur.
  EDESTADDRREQ* {.importc, header: "<errno.h>".}: cint
      ## Destination address required.
  EDOM* {.importc, header: "<errno.h>".}: cint
      ## Mathematics argument out of domain of function.
  EDQUOT* {.importc, header: "<errno.h>".}: cint
      ## Reserved.
  EEXIST* {.importc, header: "<errno.h>".}: cint
      ## File exists.
  EFAULT* {.importc, header: "<errno.h>".}: cint
      ## Bad address.
  EFBIG* {.importc, header: "<errno.h>".}: cint
      ## File too large.
  EHOSTUNREACH* {.importc, header: "<errno.h>".}: cint
      ## Host is unreachable.
  EIDRM* {.importc, header: "<errno.h>".}: cint
      ## Identifier removed.
  EILSEQ* {.importc, header: "<errno.h>".}: cint
      ## Illegal byte sequence.
  EINPROGRESS* {.importc, header: "<errno.h>".}: cint
      ## Operation in progress.
  EINTR* {.importc, header: "<errno.h>".}: cint
      ## Interrupted function.
  EINVAL* {.importc, header: "<errno.h>".}: cint
      ## Invalid argument.
  EIO* {.importc, header: "<errno.h>".}: cint
      ## I/O error.
  EISCONN* {.importc, header: "<errno.h>".}: cint
      ## Socket is connected.
  EISDIR* {.importc, header: "<errno.h>".}: cint
      ## Is a directory.
  ELOOP* {.importc, header: "<errno.h>".}: cint
      ## Too many levels of symbolic links.
  EMFILE* {.importc, header: "<errno.h>".}: cint
      ## Too many open files.
  EMLINK* {.importc, header: "<errno.h>".}: cint
      ## Too many links.
  EMSGSIZE* {.importc, header: "<errno.h>".}: cint
      ## Message too large.
  EMULTIHOP* {.importc, header: "<errno.h>".}: cint
      ## Reserved.
  ENAMETOOLONG* {.importc, header: "<errno.h>".}: cint
      ## Filename too long.
  ENETDOWN* {.importc, header: "<errno.h>".}: cint
      ## Network is down.
  ENETRESET* {.importc, header: "<errno.h>".}: cint
      ## Connection aborted by network.
  ENETUNREACH* {.importc, header: "<errno.h>".}: cint
      ## Network unreachable.
  ENFILE* {.importc, header: "<errno.h>".}: cint
      ## Too many files open in system.
  ENOBUFS* {.importc, header: "<errno.h>".}: cint
      ## No buffer space available.
  ENODATA* {.importc, header: "<errno.h>".}: cint
      ## No message is available on the STREAM head read queue.
  ENODEV* {.importc, header: "<errno.h>".}: cint
      ## No such device.
  ENOENT* {.importc, header: "<errno.h>".}: cint
      ## No such file or directory.
  ENOEXEC* {.importc, header: "<errno.h>".}: cint
      ## Executable file format error.
  ENOLCK* {.importc, header: "<errno.h>".}: cint
      ## No locks available.
  ENOLINK* {.importc, header: "<errno.h>".}: cint
      ## Reserved.
  ENOMEM* {.importc, header: "<errno.h>".}: cint
      ## Not enough space.
  ENOMSG* {.importc, header: "<errno.h>".}: cint
      ## No message of the desired type.
  ENOPROTOOPT* {.importc, header: "<errno.h>".}: cint
      ## Protocol not available.
  ENOSPC* {.importc, header: "<errno.h>".}: cint
      ## No space left on device.
  ENOSR* {.importc, header: "<errno.h>".}: cint
      ## No STREAM resources.
  ENOSTR* {.importc, header: "<errno.h>".}: cint
      ## Not a STREAM.
  ENOSYS* {.importc, header: "<errno.h>".}: cint
      ## Function not supported.
  ENOTCONN* {.importc, header: "<errno.h>".}: cint
      ## The socket is not connected.
  ENOTDIR* {.importc, header: "<errno.h>".}: cint
      ## Not a directory.
  ENOTEMPTY* {.importc, header: "<errno.h>".}: cint
      ## Directory not empty.
  ENOTSOCK* {.importc, header: "<errno.h>".}: cint
      ## Not a socket.
  ENOTSUP* {.importc, header: "<errno.h>".}: cint
      ## Not supported.
  ENOTTY* {.importc, header: "<errno.h>".}: cint
      ## Inappropriate I/O control operation.
  ENXIO* {.importc, header: "<errno.h>".}: cint
      ## No such device or address.
  EOPNOTSUPP* {.importc, header: "<errno.h>".}: cint
      ## Operation not supported on socket.
  EOVERFLOW* {.importc, header: "<errno.h>".}: cint
      ## Value too large to be stored in data type.
  EPERM* {.importc, header: "<errno.h>".}: cint
      ## Operation not permitted.
  EPIPE* {.importc, header: "<errno.h>".}: cint
      ## Broken pipe.
  EPROTO* {.importc, header: "<errno.h>".}: cint
      ## Protocol error.
  EPROTONOSUPPORT* {.importc, header: "<errno.h>".}: cint
      ## Protocol not supported.
  EPROTOTYPE* {.importc, header: "<errno.h>".}: cint
      ## Protocol wrong type for socket.
  ERANGE* {.importc, header: "<errno.h>".}: cint
      ## Result too large.
  EROFS* {.importc, header: "<errno.h>".}: cint
      ## Read-only file system.
  ESPIPE* {.importc, header: "<errno.h>".}: cint
      ## Invalid seek.
  ESRCH* {.importc, header: "<errno.h>".}: cint
      ## No such process.
  ESTALE* {.importc, header: "<errno.h>".}: cint
      ## Reserved.
  ETIME* {.importc, header: "<errno.h>".}: cint
      ## Stream ioctl() timeout.
  ETIMEDOUT* {.importc, header: "<errno.h>".}: cint
      ## Connection timed out.
  ETXTBSY* {.importc, header: "<errno.h>".}: cint
      ## Text file busy.
  EWOULDBLOCK* {.importc, header: "<errno.h>".}: cint
      ## Operation would block (may be the same value as [EAGAIN]).
  EXDEV* {.importc, header: "<errno.h>".}: cint
      ## Cross-device link.

  F_DUPFD* {.importc, header: "<fcntl.h>".}: cint
    ## Duplicate file descriptor.
  F_GETFD* {.importc, header: "<fcntl.h>".}: cint
    ## Get file descriptor flags.
  F_SETFD* {.importc, header: "<fcntl.h>".}: cint
    ## Set file descriptor flags.
  F_GETFL* {.importc, header: "<fcntl.h>".}: cint
    ## Get file status flags and file access modes.
  F_SETFL* {.importc, header: "<fcntl.h>".}: cint
    ## Set file status flags.
  F_GETLK* {.importc, header: "<fcntl.h>".}: cint
    ## Get record locking information.
  F_SETLK* {.importc, header: "<fcntl.h>".}: cint
    ## Set record locking information.
  F_SETLKW* {.importc, header: "<fcntl.h>".}: cint
    ## Set record locking information; wait if blocked.
  F_GETOWN* {.importc, header: "<fcntl.h>".}: cint
    ## Get process or process group ID to receive SIGURG signals.
  F_SETOWN* {.importc, header: "<fcntl.h>".}: cint
    ## Set process or process group ID to receive SIGURG signals.
  FD_CLOEXEC* {.importc, header: "<fcntl.h>".}: cint
    ## Close the file descriptor upon execution of an exec family function.
  F_RDLCK* {.importc, header: "<fcntl.h>".}: cint
    ## Shared or read lock.
  F_UNLCK* {.importc, header: "<fcntl.h>".}: cint
    ## Unlock.
  F_WRLCK* {.importc, header: "<fcntl.h>".}: cint
    ## Exclusive or write lock.
  O_CREAT* {.importc, header: "<fcntl.h>".}: cint
    ## Create file if it does not exist.
  O_EXCL* {.importc, header: "<fcntl.h>".}: cint
    ## Exclusive use flag.
  O_NOCTTY* {.importc, header: "<fcntl.h>".}: cint
    ## Do not assign controlling terminal.
  O_TRUNC* {.importc, header: "<fcntl.h>".}: cint
    ## Truncate flag.
  O_APPEND* {.importc, header: "<fcntl.h>".}: cint
    ## Set append mode.
  O_DSYNC* {.importc, header: "<fcntl.h>".}: cint
    ## Write according to synchronized I/O data integrity completion.
  O_NONBLOCK* {.importc, header: "<fcntl.h>".}: cint
    ## Non-blocking mode.
  O_RSYNC* {.importc, header: "<fcntl.h>".}: cint
    ## Synchronized read I/O operations.
  O_SYNC* {.importc, header: "<fcntl.h>".}: cint
    ## Write according to synchronized I/O file integrity completion.
  O_ACCMODE* {.importc, header: "<fcntl.h>".}: cint
    ## Mask for file access modes.
  O_RDONLY* {.importc, header: "<fcntl.h>".}: cint
    ## Open for reading only.
  O_RDWR* {.importc, header: "<fcntl.h>".}: cint
    ## Open for reading and writing.
  O_WRONLY* {.importc, header: "<fcntl.h>".}: cint
    ## Open for writing only.
  POSIX_FADV_NORMAL* {.importc, header: "<fcntl.h>".}: cint
    ## The application has no advice to give on its behavior with
    ## respect to the specified data. It is the default characteristic
    ## if no advice is given for an open file.
  POSIX_FADV_SEQUENTIAL* {.importc, header: "<fcntl.h>".}: cint
    ## The application expects to access the specified data
    # sequentially from lower offsets to higher offsets.
  POSIX_FADV_RANDOM* {.importc, header: "<fcntl.h>".}: cint
    ## The application expects to access the specified data in a random order.
  POSIX_FADV_WILLNEED* {.importc, header: "<fcntl.h>".}: cint
    ## The application expects to access the specified data in the near future.
  POSIX_FADV_DONTNEED* {.importc, header: "<fcntl.h>".}: cint
    ## The application expects that it will not access the specified data
    ## in the near future.
  POSIX_FADV_NOREUSE* {.importc, header: "<fcntl.h>".}: cint
    ## The application expects to access the specified data once and
    ## then not reuse it thereafter.

when not defined(haiku) and not defined(OpenBSD):
  var
    MM_HARD* {.importc, header: "<fmtmsg.h>".}: cint
      ## Source of the condition is hardware.
    MM_SOFT* {.importc, header: "<fmtmsg.h>".}: cint
      ## Source of the condition is software.
    MM_FIRM* {.importc, header: "<fmtmsg.h>".}: cint
      ## Source of the condition is firmware.
    MM_APPL* {.importc, header: "<fmtmsg.h>".}: cint
      ## Condition detected by application.
    MM_UTIL* {.importc, header: "<fmtmsg.h>".}: cint
      ## Condition detected by utility.
    MM_OPSYS* {.importc, header: "<fmtmsg.h>".}: cint
      ## Condition detected by operating system.
    MM_RECOVER* {.importc, header: "<fmtmsg.h>".}: cint
      ## Recoverable error.
    MM_NRECOV* {.importc, header: "<fmtmsg.h>".}: cint
      ## Non-recoverable error.
    MM_HALT* {.importc, header: "<fmtmsg.h>".}: cint
      ## Error causing application to halt.
    MM_ERROR* {.importc, header: "<fmtmsg.h>".}: cint
      ## Application has encountered a non-fatal fault.
    MM_WARNING* {.importc, header: "<fmtmsg.h>".}: cint
      ## Application has detected unusual non-error condition.
    MM_INFO* {.importc, header: "<fmtmsg.h>".}: cint
      ## Informative message.
    MM_NOSEV* {.importc, header: "<fmtmsg.h>".}: cint
      ## No severity level provided for the message.
    MM_PRINT* {.importc, header: "<fmtmsg.h>".}: cint
      ## Display message on standard error.
    MM_CONSOLE* {.importc, header: "<fmtmsg.h>".}: cint
      ## Display message on system console.

    MM_OK* {.importc, header: "<fmtmsg.h>".}: cint
      ## The function succeeded.
    MM_NOTOK* {.importc, header: "<fmtmsg.h>".}: cint
      ## The function failed completely.
    MM_NOMSG* {.importc, header: "<fmtmsg.h>".}: cint
      ## The function was unable to generate a message on standard error,
      ## but otherwise succeeded.
    MM_NOCON* {.importc, header: "<fmtmsg.h>".}: cint
      ## The function was unable to generate a console message, but
      ## otherwise succeeded.

var
  FNM_NOMATCH* {.importc, header: "<fnmatch.h>".}: cint
    ## The string does not match the specified pattern.
  FNM_PATHNAME* {.importc, header: "<fnmatch.h>".}: cint
    ## Slash in string only matches slash in pattern.
  FNM_PERIOD* {.importc, header: "<fnmatch.h>".}: cint
    ## Leading period in string must be exactly matched by period in pattern.
  FNM_NOESCAPE* {.importc, header: "<fnmatch.h>".}: cint
    ## Disable backslash escaping.
  FNM_NOSYS* {.importc, header: "<fnmatch.h>".}: cint
    ## Reserved.

  FTW_F* {.importc, header: "<ftw.h>".}: cint
    ## File.
  FTW_D* {.importc, header: "<ftw.h>".}: cint
    ## Directory.
  FTW_DNR* {.importc, header: "<ftw.h>".}: cint
    ## Directory without read permission.
  FTW_DP* {.importc, header: "<ftw.h>".}: cint
    ## Directory with subdirectories visited.
  FTW_NS* {.importc, header: "<ftw.h>".}: cint
    ## Unknown type; stat() failed.
  FTW_SL* {.importc, header: "<ftw.h>".}: cint
    ## Symbolic link.
  FTW_SLN* {.importc, header: "<ftw.h>".}: cint
    ## Symbolic link that names a nonexistent file.

  FTW_PHYS* {.importc, header: "<ftw.h>".}: cint
    ## Physical walk, does not follow symbolic links. Otherwise, nftw()
    ## follows links but does not walk down any path that crosses itself.
  FTW_MOUNT* {.importc, header: "<ftw.h>".}: cint
    ## The walk does not cross a mount point.
  FTW_DEPTH* {.importc, header: "<ftw.h>".}: cint
    ## All subdirectories are visited before the directory itself.
  FTW_CHDIR* {.importc, header: "<ftw.h>".}: cint
    ## The walk changes to each directory before reading it.

  GLOB_APPEND* {.importc, header: "<glob.h>".}: cint
    ## Append generated pathnames to those previously obtained.
  GLOB_DOOFFS* {.importc, header: "<glob.h>".}: cint
    ## Specify how many null pointers to add to the beginning of gl_pathv.
  GLOB_ERR* {.importc, header: "<glob.h>".}: cint
    ## Cause glob() to return on error.
  GLOB_MARK* {.importc, header: "<glob.h>".}: cint
    ## Each pathname that is a directory that matches pattern has a
    ## slash appended.
  GLOB_NOCHECK* {.importc, header: "<glob.h>".}: cint
    ## If pattern does not match any pathname, then return a list
    ## consisting of only pattern.
  GLOB_NOESCAPE* {.importc, header: "<glob.h>".}: cint
    ## Disable backslash escaping.
  GLOB_NOSORT* {.importc, header: "<glob.h>".}: cint
    ## Do not sort the pathnames returned.
  GLOB_ABORTED* {.importc, header: "<glob.h>".}: cint
    ## The scan was stopped because GLOB_ERR was set or errfunc()
    ## returned non-zero.
  GLOB_NOMATCH* {.importc, header: "<glob.h>".}: cint
    ## The pattern does not match any existing pathname, and GLOB_NOCHECK
    ## was not set in flags.
  GLOB_NOSPACE* {.importc, header: "<glob.h>".}: cint
    ## An attempt to allocate memory failed.
  GLOB_NOSYS* {.importc, header: "<glob.h>".}: cint
    ## Reserved

  CODESET* {.importc, header: "<langinfo.h>".}: cint
    ## Codeset name.
  D_T_FMT* {.importc, header: "<langinfo.h>".}: cint
    ## String for formatting date and time.
  D_FMT * {.importc, header: "<langinfo.h>".}: cint
    ## Date format string.
  T_FMT* {.importc, header: "<langinfo.h>".}: cint
    ## Time format string.
  T_FMT_AMPM* {.importc, header: "<langinfo.h>".}: cint
    ## a.m. or p.m. time format string.
  AM_STR* {.importc, header: "<langinfo.h>".}: cint
    ## Ante-meridiem affix.
  PM_STR* {.importc, header: "<langinfo.h>".}: cint
    ## Post-meridiem affix.
  DAY_1* {.importc, header: "<langinfo.h>".}: cint
    ## Name of the first day of the week (for example, Sunday).
  DAY_2* {.importc, header: "<langinfo.h>".}: cint
    ## Name of the second day of the week (for example, Monday).
  DAY_3* {.importc, header: "<langinfo.h>".}: cint
    ## Name of the third day of the week (for example, Tuesday).
  DAY_4* {.importc, header: "<langinfo.h>".}: cint
    ## Name of the fourth day of the week (for example, Wednesday).
  DAY_5* {.importc, header: "<langinfo.h>".}: cint
    ## Name of the fifth day of the week (for example, Thursday).
  DAY_6* {.importc, header: "<langinfo.h>".}: cint
    ## Name of the sixth day of the week (for example, Friday).
  DAY_7* {.importc, header: "<langinfo.h>".}: cint
    ## Name of the seventh day of the week (for example, Saturday).
  ABDAY_1* {.importc, header: "<langinfo.h>".}: cint
    ## Abbreviated name of the first day of the week.
  ABDAY_2* {.importc, header: "<langinfo.h>".}: cint
  ABDAY_3* {.importc, header: "<langinfo.h>".}: cint
  ABDAY_4* {.importc, header: "<langinfo.h>".}: cint
  ABDAY_5* {.importc, header: "<langinfo.h>".}: cint
  ABDAY_6* {.importc, header: "<langinfo.h>".}: cint
  ABDAY_7* {.importc, header: "<langinfo.h>".}: cint
  MON_1* {.importc, header: "<langinfo.h>".}: cint
    ## Name of the first month of the year.
  MON_2* {.importc, header: "<langinfo.h>".}: cint
  MON_3* {.importc, header: "<langinfo.h>".}: cint
  MON_4* {.importc, header: "<langinfo.h>".}: cint
  MON_5* {.importc, header: "<langinfo.h>".}: cint
  MON_6* {.importc, header: "<langinfo.h>".}: cint
  MON_7* {.importc, header: "<langinfo.h>".}: cint
  MON_8* {.importc, header: "<langinfo.h>".}: cint
  MON_9* {.importc, header: "<langinfo.h>".}: cint
  MON_10* {.importc, header: "<langinfo.h>".}: cint
  MON_11* {.importc, header: "<langinfo.h>".}: cint
  MON_12* {.importc, header: "<langinfo.h>".}: cint
  ABMON_1* {.importc, header: "<langinfo.h>".}: cint
    ## Abbreviated name of the first month.
  ABMON_2* {.importc, header: "<langinfo.h>".}: cint
  ABMON_3* {.importc, header: "<langinfo.h>".}: cint
  ABMON_4* {.importc, header: "<langinfo.h>".}: cint
  ABMON_5* {.importc, header: "<langinfo.h>".}: cint
  ABMON_6* {.importc, header: "<langinfo.h>".}: cint
  ABMON_7* {.importc, header: "<langinfo.h>".}: cint
  ABMON_8* {.importc, header: "<langinfo.h>".}: cint
  ABMON_9* {.importc, header: "<langinfo.h>".}: cint
  ABMON_10* {.importc, header: "<langinfo.h>".}: cint
  ABMON_11* {.importc, header: "<langinfo.h>".}: cint
  ABMON_12* {.importc, header: "<langinfo.h>".}: cint
  ERA* {.importc, header: "<langinfo.h>".}: cint
    ## Era description segments.
  ERA_D_FMT* {.importc, header: "<langinfo.h>".}: cint
    ## Era date format string.
  ERA_D_T_FMT* {.importc, header: "<langinfo.h>".}: cint
    ## Era date and time format string.
  ERA_T_FMT* {.importc, header: "<langinfo.h>".}: cint
    ## Era time format string.
  ALT_DIGITS* {.importc, header: "<langinfo.h>".}: cint
    ## Alternative symbols for digits.
  RADIXCHAR* {.importc, header: "<langinfo.h>".}: cint
    ## Radix character.
  THOUSEP* {.importc, header: "<langinfo.h>".}: cint
    ## Separator for thousands.
  YESEXPR* {.importc, header: "<langinfo.h>".}: cint
    ## Affirmative response expression.
  NOEXPR* {.importc, header: "<langinfo.h>".}: cint
    ## Negative response expression.
  CRNCYSTR* {.importc, header: "<langinfo.h>".}: cint
    ## Local currency symbol, preceded by '-' if the symbol
    ## should appear before the value, '+' if the symbol should appear
    ## after the value, or '.' if the symbol should replace the radix
    ## character. If the local currency symbol is the empty string,
    ## implementations may return the empty string ( "" ).

  LC_ALL* {.importc, header: "<locale.h>".}: cint
  LC_COLLATE* {.importc, header: "<locale.h>".}: cint
  LC_CTYPE* {.importc, header: "<locale.h>".}: cint
  LC_MESSAGES* {.importc, header: "<locale.h>".}: cint
  LC_MONETARY* {.importc, header: "<locale.h>".}: cint
  LC_NUMERIC* {.importc, header: "<locale.h>".}: cint
  LC_TIME* {.importc, header: "<locale.h>".}: cint

  PTHREAD_BARRIER_SERIAL_THREAD* {.importc, header: "<pthread.h>".}: cint
  PTHREAD_CANCEL_ASYNCHRONOUS* {.importc, header: "<pthread.h>".}: cint
  PTHREAD_CANCEL_ENABLE* {.importc, header: "<pthread.h>".}: cint
  PTHREAD_CANCEL_DEFERRED* {.importc, header: "<pthread.h>".}: cint
  PTHREAD_CANCEL_DISABLE* {.importc, header: "<pthread.h>".}: cint
  PTHREAD_CANCELED* {.importc, header: "<pthread.h>".}: cint
  PTHREAD_COND_INITIALIZER* {.importc, header: "<pthread.h>".}: cint
  PTHREAD_CREATE_DETACHED* {.importc, header: "<pthread.h>".}: cint
  PTHREAD_CREATE_JOINABLE* {.importc, header: "<pthread.h>".}: cint
  PTHREAD_EXPLICIT_SCHED* {.importc, header: "<pthread.h>".}: cint
  PTHREAD_INHERIT_SCHED* {.importc, header: "<pthread.h>".}: cint
  PTHREAD_MUTEX_DEFAULT* {.importc, header: "<pthread.h>".}: cint
  PTHREAD_MUTEX_ERRORCHECK* {.importc, header: "<pthread.h>".}: cint
  PTHREAD_MUTEX_INITIALIZER* {.importc, header: "<pthread.h>".}: cint
  PTHREAD_MUTEX_NORMAL* {.importc, header: "<pthread.h>".}: cint
  PTHREAD_MUTEX_RECURSIVE* {.importc, header: "<pthread.h>".}: cint
  PTHREAD_ONCE_INIT* {.importc, header: "<pthread.h>".}: cint
  PTHREAD_PRIO_INHERIT* {.importc, header: "<pthread.h>".}: cint
  PTHREAD_PRIO_NONE* {.importc, header: "<pthread.h>".}: cint
  PTHREAD_PRIO_PROTECT* {.importc, header: "<pthread.h>".}: cint
  PTHREAD_PROCESS_SHARED* {.importc, header: "<pthread.h>".}: cint
  PTHREAD_PROCESS_PRIVATE* {.importc, header: "<pthread.h>".}: cint
  PTHREAD_SCOPE_PROCESS* {.importc, header: "<pthread.h>".}: cint
  PTHREAD_SCOPE_SYSTEM* {.importc, header: "<pthread.h>".}: cint

  POSIX_ASYNC_IO* {.importc: "_POSIX_ASYNC_IO", header: "<unistd.h>".}: cint
  POSIX_PRIO_IO* {.importc: "_POSIX_PRIO_IO", header: "<unistd.h>".}: cint
  POSIX_SYNC_IO* {.importc: "_POSIX_SYNC_IO", header: "<unistd.h>".}: cint
  F_OK* {.importc: "F_OK", header: "<unistd.h>".}: cint
  R_OK* {.importc: "R_OK", header: "<unistd.h>".}: cint
  W_OK* {.importc: "W_OK", header: "<unistd.h>".}: cint
  X_OK* {.importc: "X_OK", header: "<unistd.h>".}: cint

  CS_PATH* {.importc: "_CS_PATH", header: "<unistd.h>".}: cint
  CS_POSIX_V6_ILP32_OFF32_CFLAGS* {.importc: "_CS_POSIX_V6_ILP32_OFF32_CFLAGS",
    header: "<unistd.h>".}: cint
  CS_POSIX_V6_ILP32_OFF32_LDFLAGS* {.
    importc: "_CS_POSIX_V6_ILP32_OFF32_LDFLAGS", header: "<unistd.h>".}: cint
  CS_POSIX_V6_ILP32_OFF32_LIBS* {.importc: "_CS_POSIX_V6_ILP32_OFF32_LIBS",
    header: "<unistd.h>".}: cint
  CS_POSIX_V6_ILP32_OFFBIG_CFLAGS* {.
    importc: "_CS_POSIX_V6_ILP32_OFFBIG_CFLAGS", header: "<unistd.h>".}: cint
  CS_POSIX_V6_ILP32_OFFBIG_LDFLAGS* {.
    importc: "_CS_POSIX_V6_ILP32_OFFBIG_LDFLAGS", header: "<unistd.h>".}: cint
  CS_POSIX_V6_ILP32_OFFBIG_LIBS* {.
    importc: "_CS_POSIX_V6_ILP32_OFFBIG_LIBS", header: "<unistd.h>".}: cint
  CS_POSIX_V6_LP64_OFF64_CFLAGS* {.
    importc: "_CS_POSIX_V6_LP64_OFF64_CFLAGS", header: "<unistd.h>".}: cint
  CS_POSIX_V6_LP64_OFF64_LDFLAGS* {.
    importc: "_CS_POSIX_V6_LP64_OFF64_LDFLAGS", header: "<unistd.h>".}: cint
  CS_POSIX_V6_LP64_OFF64_LIBS* {.
    importc: "_CS_POSIX_V6_LP64_OFF64_LIBS", header: "<unistd.h>".}: cint
  CS_POSIX_V6_LPBIG_OFFBIG_CFLAGS* {.
    importc: "_CS_POSIX_V6_LPBIG_OFFBIG_CFLAGS", header: "<unistd.h>".}: cint
  CS_POSIX_V6_LPBIG_OFFBIG_LDFLAGS* {.
    importc: "_CS_POSIX_V6_LPBIG_OFFBIG_LDFLAGS", header: "<unistd.h>".}: cint
  CS_POSIX_V6_LPBIG_OFFBIG_LIBS* {.
    importc: "_CS_POSIX_V6_LPBIG_OFFBIG_LIBS", header: "<unistd.h>".}: cint
  CS_POSIX_V6_WIDTH_RESTRICTED_ENVS* {.
    importc: "_CS_POSIX_V6_WIDTH_RESTRICTED_ENVS", header: "<unistd.h>".}: cint
  F_LOCK* {.importc: "F_LOCK", header: "<unistd.h>".}: cint
  F_TEST* {.importc: "F_TEST", header: "<unistd.h>".}: cint
  F_TLOCK* {.importc: "F_TLOCK", header: "<unistd.h>".}: cint
  F_ULOCK* {.importc: "F_ULOCK", header: "<unistd.h>".}: cint
  PC_2_SYMLINKS* {.importc: "_PC_2_SYMLINKS", header: "<unistd.h>".}: cint
  PC_ALLOC_SIZE_MIN* {.importc: "_PC_ALLOC_SIZE_MIN",
    header: "<unistd.h>".}: cint
  PC_ASYNC_IO* {.importc: "_PC_ASYNC_IO", header: "<unistd.h>".}: cint
  PC_CHOWN_RESTRICTED* {.importc: "_PC_CHOWN_RESTRICTED",
    header: "<unistd.h>".}: cint
  PC_FILESIZEBITS* {.importc: "_PC_FILESIZEBITS", header: "<unistd.h>".}: cint
  PC_LINK_MAX* {.importc: "_PC_LINK_MAX", header: "<unistd.h>".}: cint
  PC_MAX_CANON* {.importc: "_PC_MAX_CANON", header: "<unistd.h>".}: cint

  PC_MAX_INPUT*{.importc: "_PC_MAX_INPUT", header: "<unistd.h>".}: cint
  PC_NAME_MAX*{.importc: "_PC_NAME_MAX", header: "<unistd.h>".}: cint
  PC_NO_TRUNC*{.importc: "_PC_NO_TRUNC", header: "<unistd.h>".}: cint
  PC_PATH_MAX*{.importc: "_PC_PATH_MAX", header: "<unistd.h>".}: cint
  PC_PIPE_BUF*{.importc: "_PC_PIPE_BUF", header: "<unistd.h>".}: cint
  PC_PRIO_IO*{.importc: "_PC_PRIO_IO", header: "<unistd.h>".}: cint
  PC_REC_INCR_XFER_SIZE*{.importc: "_PC_REC_INCR_XFER_SIZE",
    header: "<unistd.h>".}: cint
  PC_REC_MIN_XFER_SIZE*{.importc: "_PC_REC_MIN_XFER_SIZE",
    header: "<unistd.h>".}: cint
  PC_REC_XFER_ALIGN*{.importc: "_PC_REC_XFER_ALIGN", header: "<unistd.h>".}: cint
  PC_SYMLINK_MAX*{.importc: "_PC_SYMLINK_MAX", header: "<unistd.h>".}: cint
  PC_SYNC_IO*{.importc: "_PC_SYNC_IO", header: "<unistd.h>".}: cint
  PC_VDISABLE*{.importc: "_PC_VDISABLE", header: "<unistd.h>".}: cint
  SC_2_C_BIND*{.importc: "_SC_2_C_BIND", header: "<unistd.h>".}: cint
  SC_2_C_DEV*{.importc: "_SC_2_C_DEV", header: "<unistd.h>".}: cint
  SC_2_CHAR_TERM*{.importc: "_SC_2_CHAR_TERM", header: "<unistd.h>".}: cint
  SC_2_FORT_DEV*{.importc: "_SC_2_FORT_DEV", header: "<unistd.h>".}: cint
  SC_2_FORT_RUN*{.importc: "_SC_2_FORT_RUN", header: "<unistd.h>".}: cint
  SC_2_LOCALEDEF*{.importc: "_SC_2_LOCALEDEF", header: "<unistd.h>".}: cint
  SC_2_PBS*{.importc: "_SC_2_PBS", header: "<unistd.h>".}: cint
  SC_2_PBS_ACCOUNTING*{.importc: "_SC_2_PBS_ACCOUNTING",
    header: "<unistd.h>".}: cint
  SC_2_PBS_CHECKPOINT*{.importc: "_SC_2_PBS_CHECKPOINT",
    header: "<unistd.h>".}: cint
  SC_2_PBS_LOCATE*{.importc: "_SC_2_PBS_LOCATE", header: "<unistd.h>".}: cint
  SC_2_PBS_MESSAGE*{.importc: "_SC_2_PBS_MESSAGE", header: "<unistd.h>".}: cint
  SC_2_PBS_TRACK*{.importc: "_SC_2_PBS_TRACK", header: "<unistd.h>".}: cint
  SC_2_SW_DEV*{.importc: "_SC_2_SW_DEV", header: "<unistd.h>".}: cint
  SC_2_UPE*{.importc: "_SC_2_UPE", header: "<unistd.h>".}: cint
  SC_2_VERSION*{.importc: "_SC_2_VERSION", header: "<unistd.h>".}: cint
  SC_ADVISORY_INFO*{.importc: "_SC_ADVISORY_INFO", header: "<unistd.h>".}: cint
  SC_AIO_LISTIO_MAX*{.importc: "_SC_AIO_LISTIO_MAX", header: "<unistd.h>".}: cint
  SC_AIO_MAX*{.importc: "_SC_AIO_MAX", header: "<unistd.h>".}: cint
  SC_AIO_PRIO_DELTA_MAX*{.importc: "_SC_AIO_PRIO_DELTA_MAX",
    header: "<unistd.h>".}: cint
  SC_ARG_MAX*{.importc: "_SC_ARG_MAX", header: "<unistd.h>".}: cint
  SC_ASYNCHRONOUS_IO*{.importc: "_SC_ASYNCHRONOUS_IO",
    header: "<unistd.h>".}: cint
  SC_ATEXIT_MAX*{.importc: "_SC_ATEXIT_MAX", header: "<unistd.h>".}: cint
  SC_BARRIERS*{.importc: "_SC_BARRIERS", header: "<unistd.h>".}: cint
  SC_BC_BASE_MAX*{.importc: "_SC_BC_BASE_MAX", header: "<unistd.h>".}: cint
  SC_BC_DIM_MAX*{.importc: "_SC_BC_DIM_MAX", header: "<unistd.h>".}: cint
  SC_BC_SCALE_MAX*{.importc: "_SC_BC_SCALE_MAX", header: "<unistd.h>".}: cint
  SC_BC_STRING_MAX*{.importc: "_SC_BC_STRING_MAX", header: "<unistd.h>".}: cint
  SC_CHILD_MAX*{.importc: "_SC_CHILD_MAX", header: "<unistd.h>".}: cint
  SC_CLK_TCK*{.importc: "_SC_CLK_TCK", header: "<unistd.h>".}: cint
  SC_CLOCK_SELECTION*{.importc: "_SC_CLOCK_SELECTION",
    header: "<unistd.h>".}: cint
  SC_COLL_WEIGHTS_MAX*{.importc: "_SC_COLL_WEIGHTS_MAX",
    header: "<unistd.h>".}: cint
  SC_CPUTIME*{.importc: "_SC_CPUTIME", header: "<unistd.h>".}: cint
  SC_DELAYTIMER_MAX*{.importc: "_SC_DELAYTIMER_MAX", header: "<unistd.h>".}: cint
  SC_EXPR_NEST_MAX*{.importc: "_SC_EXPR_NEST_MAX", header: "<unistd.h>".}: cint
  SC_FSYNC*{.importc: "_SC_FSYNC", header: "<unistd.h>".}: cint
  SC_GETGR_R_SIZE_MAX*{.importc: "_SC_GETGR_R_SIZE_MAX",
    header: "<unistd.h>".}: cint
  SC_GETPW_R_SIZE_MAX*{.importc: "_SC_GETPW_R_SIZE_MAX",
    header: "<unistd.h>".}: cint
  SC_HOST_NAME_MAX*{.importc: "_SC_HOST_NAME_MAX", header: "<unistd.h>".}: cint
  SC_IOV_MAX*{.importc: "_SC_IOV_MAX", header: "<unistd.h>".}: cint
  SC_IPV6*{.importc: "_SC_IPV6", header: "<unistd.h>".}: cint
  SC_JOB_CONTROL*{.importc: "_SC_JOB_CONTROL", header: "<unistd.h>".}: cint
  SC_LINE_MAX*{.importc: "_SC_LINE_MAX", header: "<unistd.h>".}: cint
  SC_LOGIN_NAME_MAX*{.importc: "_SC_LOGIN_NAME_MAX", header: "<unistd.h>".}: cint
  SC_MAPPED_FILES*{.importc: "_SC_MAPPED_FILES", header: "<unistd.h>".}: cint
  SC_MEMLOCK*{.importc: "_SC_MEMLOCK", header: "<unistd.h>".}: cint
  SC_MEMLOCK_RANGE*{.importc: "_SC_MEMLOCK_RANGE", header: "<unistd.h>".}: cint
  SC_MEMORY_PROTECTION*{.importc: "_SC_MEMORY_PROTECTION",
    header: "<unistd.h>".}: cint
  SC_MESSAGE_PASSING*{.importc: "_SC_MESSAGE_PASSING",
    header: "<unistd.h>".}: cint
  SC_MONOTONIC_CLOCK*{.importc: "_SC_MONOTONIC_CLOCK",
    header: "<unistd.h>".}: cint
  SC_MQ_OPEN_MAX*{.importc: "_SC_MQ_OPEN_MAX", header: "<unistd.h>".}: cint
  SC_MQ_PRIO_MAX*{.importc: "_SC_MQ_PRIO_MAX", header: "<unistd.h>".}: cint
  SC_NGROUPS_MAX*{.importc: "_SC_NGROUPS_MAX", header: "<unistd.h>".}: cint
  SC_OPEN_MAX*{.importc: "_SC_OPEN_MAX", header: "<unistd.h>".}: cint
  SC_PAGE_SIZE*{.importc: "_SC_PAGE_SIZE", header: "<unistd.h>".}: cint
  SC_PRIORITIZED_IO*{.importc: "_SC_PRIORITIZED_IO", header: "<unistd.h>".}: cint
  SC_PRIORITY_SCHEDULING*{.importc: "_SC_PRIORITY_SCHEDULING",
    header: "<unistd.h>".}: cint
  SC_RAW_SOCKETS*{.importc: "_SC_RAW_SOCKETS", header: "<unistd.h>".}: cint
  SC_RE_DUP_MAX*{.importc: "_SC_RE_DUP_MAX", header: "<unistd.h>".}: cint
  SC_READER_WRITER_LOCKS*{.importc: "_SC_READER_WRITER_LOCKS",
    header: "<unistd.h>".}: cint
  SC_REALTIME_SIGNALS*{.importc: "_SC_REALTIME_SIGNALS",
    header: "<unistd.h>".}: cint
  SC_REGEXP*{.importc: "_SC_REGEXP", header: "<unistd.h>".}: cint
  SC_RTSIG_MAX*{.importc: "_SC_RTSIG_MAX", header: "<unistd.h>".}: cint
  SC_SAVED_IDS*{.importc: "_SC_SAVED_IDS", header: "<unistd.h>".}: cint
  SC_SEM_NSEMS_MAX*{.importc: "_SC_SEM_NSEMS_MAX", header: "<unistd.h>".}: cint
  SC_SEM_VALUE_MAX*{.importc: "_SC_SEM_VALUE_MAX", header: "<unistd.h>".}: cint
  SC_SEMAPHORES*{.importc: "_SC_SEMAPHORES", header: "<unistd.h>".}: cint
  SC_SHARED_MEMORY_OBJECTS*{.importc: "_SC_SHARED_MEMORY_OBJECTS",
    header: "<unistd.h>".}: cint
  SC_SHELL*{.importc: "_SC_SHELL", header: "<unistd.h>".}: cint
  SC_SIGQUEUE_MAX*{.importc: "_SC_SIGQUEUE_MAX", header: "<unistd.h>".}: cint
  SC_SPAWN*{.importc: "_SC_SPAWN", header: "<unistd.h>".}: cint
  SC_SPIN_LOCKS*{.importc: "_SC_SPIN_LOCKS", header: "<unistd.h>".}: cint
  SC_SPORADIC_SERVER*{.importc: "_SC_SPORADIC_SERVER",
    header: "<unistd.h>".}: cint
  SC_SS_REPL_MAX*{.importc: "_SC_SS_REPL_MAX", header: "<unistd.h>".}: cint
  SC_STREAM_MAX*{.importc: "_SC_STREAM_MAX", header: "<unistd.h>".}: cint
  SC_SYMLOOP_MAX*{.importc: "_SC_SYMLOOP_MAX", header: "<unistd.h>".}: cint
  SC_SYNCHRONIZED_IO*{.importc: "_SC_SYNCHRONIZED_IO",
    header: "<unistd.h>".}: cint
  SC_THREAD_ATTR_STACKADDR*{.importc: "_SC_THREAD_ATTR_STACKADDR",
    header: "<unistd.h>".}: cint
  SC_THREAD_ATTR_STACKSIZE*{.importc: "_SC_THREAD_ATTR_STACKSIZE",
    header: "<unistd.h>".}: cint
  SC_THREAD_CPUTIME*{.importc: "_SC_THREAD_CPUTIME", header: "<unistd.h>".}: cint
  SC_THREAD_DESTRUCTOR_ITERATIONS*{.importc: "_SC_THREAD_DESTRUCTOR_ITERATIONS",
    header: "<unistd.h>".}: cint
  SC_THREAD_KEYS_MAX*{.importc: "_SC_THREAD_KEYS_MAX",
    header: "<unistd.h>".}: cint
  SC_THREAD_PRIO_INHERIT*{.importc: "_SC_THREAD_PRIO_INHERIT",
    header: "<unistd.h>".}: cint
  SC_THREAD_PRIO_PROTECT*{.importc: "_SC_THREAD_PRIO_PROTECT",
    header: "<unistd.h>".}: cint
  SC_THREAD_PRIORITY_SCHEDULING*{.importc: "_SC_THREAD_PRIORITY_SCHEDULING",
    header: "<unistd.h>".}: cint
  SC_THREAD_PROCESS_SHARED*{.importc: "_SC_THREAD_PROCESS_SHARED",
    header: "<unistd.h>".}: cint
  SC_THREAD_SAFE_FUNCTIONS*{.importc: "_SC_THREAD_SAFE_FUNCTIONS",
    header: "<unistd.h>".}: cint
  SC_THREAD_SPORADIC_SERVER*{.importc: "_SC_THREAD_SPORADIC_SERVER",
    header: "<unistd.h>".}: cint
  SC_THREAD_STACK_MIN*{.importc: "_SC_THREAD_STACK_MIN",
    header: "<unistd.h>".}: cint
  SC_THREAD_THREADS_MAX*{.importc: "_SC_THREAD_THREADS_MAX",
    header: "<unistd.h>".}: cint
  SC_THREADS*{.importc: "_SC_THREADS", header: "<unistd.h>".}: cint
  SC_TIMEOUTS*{.importc: "_SC_TIMEOUTS", header: "<unistd.h>".}: cint
  SC_TIMER_MAX*{.importc: "_SC_TIMER_MAX", header: "<unistd.h>".}: cint
  SC_TIMERS*{.importc: "_SC_TIMERS", header: "<unistd.h>".}: cint
  SC_TRACE*{.importc: "_SC_TRACE", header: "<unistd.h>".}: cint
  SC_TRACE_EVENT_FILTER*{.importc: "_SC_TRACE_EVENT_FILTER", header: "<unistd.h>".}: cint
  SC_TRACE_EVENT_NAME_MAX*{.importc: "_SC_TRACE_EVENT_NAME_MAX", header: "<unistd.h>".}: cint
  SC_TRACE_INHERIT*{.importc: "_SC_TRACE_INHERIT", header: "<unistd.h>".}: cint
  SC_TRACE_LOG*{.importc: "_SC_TRACE_LOG", header: "<unistd.h>".}: cint
  SC_TRACE_NAME_MAX*{.importc: "_SC_TRACE_NAME_MAX", header: "<unistd.h>".}: cint
  SC_TRACE_SYS_MAX*{.importc: "_SC_TRACE_SYS_MAX", header: "<unistd.h>".}: cint
  SC_TRACE_USER_EVENT_MAX*{.importc: "_SC_TRACE_USER_EVENT_MAX", header: "<unistd.h>".}: cint
  SC_TTY_NAME_MAX*{.importc: "_SC_TTY_NAME_MAX", header: "<unistd.h>".}: cint
  SC_TYPED_MEMORY_OBJECTS*{.importc: "_SC_TYPED_MEMORY_OBJECTS", header: "<unistd.h>".}: cint
  SC_TZNAME_MAX*{.importc: "_SC_TZNAME_MAX", header: "<unistd.h>".}: cint
  SC_V6_ILP32_OFF32*{.importc: "_SC_V6_ILP32_OFF32", header: "<unistd.h>".}: cint
  SC_V6_ILP32_OFFBIG*{.importc: "_SC_V6_ILP32_OFFBIG", header: "<unistd.h>".}: cint
  SC_V6_LP64_OFF64*{.importc: "_SC_V6_LP64_OFF64", header: "<unistd.h>".}: cint
  SC_V6_LPBIG_OFFBIG*{.importc: "_SC_V6_LPBIG_OFFBIG", header: "<unistd.h>".}: cint
  SC_VERSION*{.importc: "_SC_VERSION", header: "<unistd.h>".}: cint
  SC_XBS5_ILP32_OFF32*{.importc: "_SC_XBS5_ILP32_OFF32", header: "<unistd.h>".}: cint
  SC_XBS5_ILP32_OFFBIG*{.importc: "_SC_XBS5_ILP32_OFFBIG", header: "<unistd.h>".}: cint
  SC_XBS5_LP64_OFF64*{.importc: "_SC_XBS5_LP64_OFF64", header: "<unistd.h>".}: cint
  SC_XBS5_LPBIG_OFFBIG*{.importc: "_SC_XBS5_LPBIG_OFFBIG",
                         header: "<unistd.h>".}: cint
  SC_XOPEN_CRYPT*{.importc: "_SC_XOPEN_CRYPT", header: "<unistd.h>".}: cint
  SC_XOPEN_ENH_I18N*{.importc: "_SC_XOPEN_ENH_I18N", header: "<unistd.h>".}: cint
  SC_XOPEN_LEGACY*{.importc: "_SC_XOPEN_LEGACY", header: "<unistd.h>".}: cint
  SC_XOPEN_REALTIME*{.importc: "_SC_XOPEN_REALTIME", header: "<unistd.h>".}: cint
  SC_XOPEN_REALTIME_THREADS*{.importc: "_SC_XOPEN_REALTIME_THREADS",
                              header: "<unistd.h>".}: cint
  SC_XOPEN_SHM*{.importc: "_SC_XOPEN_SHM", header: "<unistd.h>".}: cint
  SC_XOPEN_STREAMS*{.importc: "_SC_XOPEN_STREAMS", header: "<unistd.h>".}: cint
  SC_XOPEN_UNIX*{.importc: "_SC_XOPEN_UNIX", header: "<unistd.h>".}: cint
  SC_XOPEN_VERSION*{.importc: "_SC_XOPEN_VERSION", header: "<unistd.h>".}: cint
  SC_NPROCESSORS_ONLN*{.importc: "_SC_NPROCESSORS_ONLN",
                        header: "<unistd.h>".}: cint

  SEM_FAILED* {.importc, header: "<semaphore.h>".}: pointer
  IPC_CREAT* {.importc, header: "<sys/ipc.h>".}: cint
    ## Create entry if key does not exist.
  IPC_EXCL* {.importc, header: "<sys/ipc.h>".}: cint
    ## Fail if key exists.
  IPC_NOWAIT* {.importc, header: "<sys/ipc.h>".}: cint
    ## Error if request must wait.

  IPC_PRIVATE* {.importc, header: "<sys/ipc.h>".}: cint
    ## Private key.

  IPC_RMID* {.importc, header: "<sys/ipc.h>".}: cint
    ## Remove identifier.
  IPC_SET* {.importc, header: "<sys/ipc.h>".}: cint
    ## Set options.
  IPC_STAT* {.importc, header: "<sys/ipc.h>".}: cint
    ## Get options.

  S_IFMT* {.importc, header: "<sys/stat.h>".}: cint
    ## Type of file.
  S_IFBLK* {.importc, header: "<sys/stat.h>".}: cint
    ## Block special.
  S_IFCHR* {.importc, header: "<sys/stat.h>".}: cint
    ## Character special.
  S_IFIFO* {.importc, header: "<sys/stat.h>".}: cint
    ## FIFO special.
  S_IFREG* {.importc, header: "<sys/stat.h>".}: cint
    ## Regular.
  S_IFDIR* {.importc, header: "<sys/stat.h>".}: cint
    ## Directory.
  S_IFLNK* {.importc, header: "<sys/stat.h>".}: cint
    ## Symbolic link.
  S_IFSOCK* {.importc, header: "<sys/stat.h>".}: cint
    ## Socket.
  S_IRWXU* {.importc, header: "<sys/stat.h>".}: cint
    ## Read, write, execute/search by owner.
  S_IRUSR* {.importc, header: "<sys/stat.h>".}: cint
    ## Read permission, owner.
  S_IWUSR* {.importc, header: "<sys/stat.h>".}: cint
    ## Write permission, owner.
  S_IXUSR* {.importc, header: "<sys/stat.h>".}: cint
    ## Execute/search permission, owner.
  S_IRWXG* {.importc, header: "<sys/stat.h>".}: cint
    ## Read, write, execute/search by group.
  S_IRGRP* {.importc, header: "<sys/stat.h>".}: cint
    ## Read permission, group.
  S_IWGRP* {.importc, header: "<sys/stat.h>".}: cint
    ## Write permission, group.
  S_IXGRP* {.importc, header: "<sys/stat.h>".}: cint
    ## Execute/search permission, group.
  S_IRWXO* {.importc, header: "<sys/stat.h>".}: cint
    ## Read, write, execute/search by others.
  S_IROTH* {.importc, header: "<sys/stat.h>".}: cint
    ## Read permission, others.
  S_IWOTH* {.importc, header: "<sys/stat.h>".}: cint
    ## Write permission, others.
  S_IXOTH* {.importc, header: "<sys/stat.h>".}: cint
    ## Execute/search permission, others.
  S_ISUID* {.importc, header: "<sys/stat.h>".}: cint
    ## Set-user-ID on execution.
  S_ISGID* {.importc, header: "<sys/stat.h>".}: cint
    ## Set-group-ID on execution.
  S_ISVTX* {.importc, header: "<sys/stat.h>".}: cint
    ## On directories, restricted deletion flag.

  ST_RDONLY* {.importc, header: "<sys/statvfs.h>".}: cint
    ## Read-only file system.
  ST_NOSUID* {.importc, header: "<sys/statvfs.h>".}: cint
    ## Does not support the semantics of the ST_ISUID and ST_ISGID file mode bits.

  PROT_READ* {.importc, header: "<sys/mman.h>".}: cint
    ## Page can be read.
  PROT_WRITE* {.importc, header: "<sys/mman.h>".}: cint
    ## Page can be written.
  PROT_EXEC* {.importc, header: "<sys/mman.h>".}: cint
    ## Page can be executed.
  PROT_NONE* {.importc, header: "<sys/mman.h>".}: cint
    ## Page cannot be accessed.
  MAP_SHARED* {.importc, header: "<sys/mman.h>".}: cint
    ## Share changes.
  MAP_PRIVATE* {.importc, header: "<sys/mman.h>".}: cint
    ## Changes are private.
  MAP_FIXED* {.importc, header: "<sys/mman.h>".}: cint
    ## Interpret addr exactly.
  MS_ASYNC* {.importc, header: "<sys/mman.h>".}: cint
    ## Perform asynchronous writes.
  MS_SYNC* {.importc, header: "<sys/mman.h>".}: cint
    ## Perform synchronous writes.
  MS_INVALIDATE* {.importc, header: "<sys/mman.h>".}: cint
    ## Invalidate mappings.
  MCL_CURRENT* {.importc, header: "<sys/mman.h>".}: cint
    ## Lock currently mapped pages.
  MCL_FUTURE* {.importc, header: "<sys/mman.h>".}: cint
    ## Lock pages that become mapped.
  MAP_FAILED* {.importc, header: "<sys/mman.h>".}: cint
  POSIX_MADV_NORMAL* {.importc, header: "<sys/mman.h>".}: cint
    ## The application has no advice to give on its behavior with
    ## respect to the specified range. It is the default characteristic
    ## if no advice is given for a range of memory.
  POSIX_MADV_SEQUENTIAL* {.importc, header: "<sys/mman.h>".}: cint
    ## The application expects to access the specified range sequentially
    ## from lower addresses to higher addresses.
  POSIX_MADV_RANDOM* {.importc, header: "<sys/mman.h>".}: cint
    ## The application expects to access the specified range in a random order.
  POSIX_MADV_WILLNEED* {.importc, header: "<sys/mman.h>".}: cint
    ## The application expects to access the specified range in the near future.
  POSIX_MADV_DONTNEED* {.importc, header: "<sys/mman.h>".}: cint
  POSIX_TYPED_MEM_ALLOCATE* {.importc, header: "<sys/mman.h>".}: cint
  POSIX_TYPED_MEM_ALLOCATE_CONTIG* {.importc, header: "<sys/mman.h>".}: cint
  POSIX_TYPED_MEM_MAP_ALLOCATABLE* {.importc, header: "<sys/mman.h>".}: cint


  CLOCKS_PER_SEC* {.importc, header: "<time.h>".}: int
    ## A number used to convert the value returned by the clock() function
    ## into seconds.
  CLOCK_PROCESS_CPUTIME_ID* {.importc, header: "<time.h>".}: cint
    ## The identifier of the CPU-time clock associated with the process
    ## making a clock() or timer*() function call.
  CLOCK_THREAD_CPUTIME_ID* {.importc, header: "<time.h>".}: cint
  CLOCK_REALTIME* {.importc, header: "<time.h>".}: cint
    ## The identifier of the system-wide realtime clock.
  TIMER_ABSTIME* {.importc, header: "<time.h>".}: cint
    ## Flag indicating time is absolute. For functions taking timer
    ## objects, this refers to the clock associated with the timer.
  CLOCK_MONOTONIC* {.importc, header: "<time.h>".}: cint

  WNOHANG* {.importc, header: "<sys/wait.h>".}: cint
    ## Do not hang if no status is available; return immediately.
  WUNTRACED* {.importc, header: "<sys/wait.h>".}: cint
    ## Report status of stopped child process.
  WEXITSTATUS* {.importc, header: "<sys/wait.h>".}: cint
    ## Return exit status.
  WSTOPSIG* {.importc, header: "<sys/wait.h>".}: cint
    ## Return signal number that caused process to stop.
  WTERMSIG* {.importc, header: "<sys/wait.h>".}: cint
    ## Return signal number that caused process to terminate.
  WEXITED* {.importc, header: "<sys/wait.h>".}: cint
    ## Wait for processes that have exited.
  WSTOPPED* {.importc, header: "<sys/wait.h>".}: cint
    ## Status is returned for any child that has stopped upon receipt
    ## of a signal.
  WCONTINUED* {.importc, header: "<sys/wait.h>".}: cint
    ## Status is returned for any child that was stopped and has been continued.
  WNOWAIT* {.importc, header: "<sys/wait.h>".}: cint
    ## Keep the process whose status is returned in infop in a waitable state.
  P_ALL* {.importc, header: "<sys/wait.h>".}: cint
  P_PID* {.importc, header: "<sys/wait.h>".}: cint
  P_PGID* {.importc, header: "<sys/wait.h>".}: cint

  SIG_DFL* {.importc, header: "<signal.h>".}: proc (x: cint) {.noconv.}
    ## Request for default signal handling.
  SIG_ERR* {.importc, header: "<signal.h>".}: proc (x: cint) {.noconv.}
    ## Return value from signal() in case of error.
  cSIG_HOLD* {.importc: "SIG_HOLD",
    header: "<signal.h>".}: proc (x: cint) {.noconv.}
    ## Request that signal be held.
  SIG_IGN* {.importc, header: "<signal.h>".}: proc (x: cint) {.noconv.}
    ## Request that signal be ignored.

  SIGEV_NONE* {.importc, header: "<signal.h>".}: cint
  SIGEV_SIGNAL* {.importc, header: "<signal.h>".}: cint
  SIGEV_THREAD* {.importc, header: "<signal.h>".}: cint
  SIGABRT* {.importc, header: "<signal.h>".}: cint
  SIGALRM* {.importc, header: "<signal.h>".}: cint
  SIGBUS* {.importc, header: "<signal.h>".}: cint
  SIGCHLD* {.importc, header: "<signal.h>".}: cint
  SIGCONT* {.importc, header: "<signal.h>".}: cint
  SIGFPE* {.importc, header: "<signal.h>".}: cint
  SIGHUP* {.importc, header: "<signal.h>".}: cint
  SIGILL* {.importc, header: "<signal.h>".}: cint
  SIGINT* {.importc, header: "<signal.h>".}: cint
  SIGKILL* {.importc, header: "<signal.h>".}: cint
  SIGPIPE* {.importc, header: "<signal.h>".}: cint
  SIGQUIT* {.importc, header: "<signal.h>".}: cint
  SIGSEGV* {.importc, header: "<signal.h>".}: cint
  SIGSTOP* {.importc, header: "<signal.h>".}: cint
  SIGTERM* {.importc, header: "<signal.h>".}: cint
  SIGTSTP* {.importc, header: "<signal.h>".}: cint
  SIGTTIN* {.importc, header: "<signal.h>".}: cint
  SIGTTOU* {.importc, header: "<signal.h>".}: cint
  SIGUSR1* {.importc, header: "<signal.h>".}: cint
  SIGUSR2* {.importc, header: "<signal.h>".}: cint
  SIGPOLL* {.importc, header: "<signal.h>".}: cint
  SIGPROF* {.importc, header: "<signal.h>".}: cint
  SIGSYS* {.importc, header: "<signal.h>".}: cint
  SIGTRAP* {.importc, header: "<signal.h>".}: cint
  SIGURG* {.importc, header: "<signal.h>".}: cint
  SIGVTALRM* {.importc, header: "<signal.h>".}: cint
  SIGXCPU* {.importc, header: "<signal.h>".}: cint
  SIGXFSZ* {.importc, header: "<signal.h>".}: cint
  SA_NOCLDSTOP* {.importc, header: "<signal.h>".}: cint
  SIG_BLOCK* {.importc, header: "<signal.h>".}: cint
  SIG_UNBLOCK* {.importc, header: "<signal.h>".}: cint
  SIG_SETMASK* {.importc, header: "<signal.h>".}: cint
  SA_ONSTACK* {.importc, header: "<signal.h>".}: cint
  SA_RESETHAND* {.importc, header: "<signal.h>".}: cint
  SA_RESTART* {.importc, header: "<signal.h>".}: cint
  SA_SIGINFO* {.importc, header: "<signal.h>".}: cint
  SA_NOCLDWAIT* {.importc, header: "<signal.h>".}: cint
  SA_NODEFER* {.importc, header: "<signal.h>".}: cint
  SS_ONSTACK* {.importc, header: "<signal.h>".}: cint
  SS_DISABLE* {.importc, header: "<signal.h>".}: cint
  MINSIGSTKSZ* {.importc, header: "<signal.h>".}: cint
  SIGSTKSZ* {.importc, header: "<signal.h>".}: cint

  NL_SETD* {.importc, header: "<nl_types.h>".}: cint
  NL_CAT_LOCALE* {.importc, header: "<nl_types.h>".}: cint

  SCHED_FIFO* {.importc, header: "<sched.h>".}: cint
  SCHED_RR* {.importc, header: "<sched.h>".}: cint
  SCHED_SPORADIC* {.importc, header: "<sched.h>".}: cint
  SCHED_OTHER* {.importc, header: "<sched.h>".}: cint
  FD_SETSIZE* {.importc, header: "<sys/select.h>".}: cint

  SEEK_SET* {.importc, header: "<unistd.h>".}: cint
  SEEK_CUR* {.importc, header: "<unistd.h>".}: cint
  SEEK_END* {.importc, header: "<unistd.h>".}: cint

  SCM_RIGHTS* {.importc, header: "<sys/socket.h>".}: cint
    ## Indicates that the data array contains the access rights
    ## to be sent or received.

  SOCK_DGRAM* {.importc, header: "<sys/socket.h>".}: cint ## Datagram socket.
  SOCK_RAW* {.importc, header: "<sys/socket.h>".}: cint
    ## Raw Protocol Interface.
  SOCK_SEQPACKET* {.importc, header: "<sys/socket.h>".}: cint
    ## Sequenced-packet socket.
  SOCK_STREAM* {.importc, header: "<sys/socket.h>".}: cint
    ## Byte-stream socket.

  SOL_SOCKET* {.importc, header: "<sys/socket.h>".}: cint
    ## Options to be accessed at socket level, not protocol level.

  SO_ACCEPTCONN* {.importc, header: "<sys/socket.h>".}: cint
    ## Socket is accepting connections.
  SO_BROADCAST* {.importc, header: "<sys/socket.h>".}: cint
    ## Transmission of broadcast messages is supported.
  SO_DEBUG* {.importc, header: "<sys/socket.h>".}: cint
    ## Debugging information is being recorded.
  SO_DONTROUTE* {.importc, header: "<sys/socket.h>".}: cint
    ## Bypass normal routing.
  SO_ERROR* {.importc, header: "<sys/socket.h>".}: cint
    ## Socket error status.
  SO_KEEPALIVE* {.importc, header: "<sys/socket.h>".}: cint
    ## Connections are kept alive with periodic messages.
  SO_LINGER* {.importc, header: "<sys/socket.h>".}: cint
    ## Socket lingers on close.
  SO_OOBINLINE* {.importc, header: "<sys/socket.h>".}: cint
    ## Out-of-band data is transmitted in line.
  SO_RCVBUF* {.importc, header: "<sys/socket.h>".}: cint
    ## Receive buffer size.
  SO_RCVLOWAT* {.importc, header: "<sys/socket.h>".}: cint
    ## Receive *low water mark*.
  SO_RCVTIMEO* {.importc, header: "<sys/socket.h>".}: cint
    ## Receive timeout.
  SO_REUSEADDR* {.importc, header: "<sys/socket.h>".}: cint
    ## Reuse of local addresses is supported.
  SO_SNDBUF* {.importc, header: "<sys/socket.h>".}: cint
    ## Send buffer size.
  SO_SNDLOWAT* {.importc, header: "<sys/socket.h>".}: cint
    ## Send *low water mark*.
  SO_SNDTIMEO* {.importc, header: "<sys/socket.h>".}: cint
    ## Send timeout.
  SO_TYPE* {.importc, header: "<sys/socket.h>".}: cint
    ## Socket type.

  SOMAXCONN* {.importc, header: "<sys/socket.h>".}: cint
    ## The maximum backlog queue length.

  MSG_CTRUNC* {.importc, header: "<sys/socket.h>".}: cint
    ## Control data truncated.
  MSG_DONTROUTE* {.importc, header: "<sys/socket.h>".}: cint
    ## Send without using routing tables.
  MSG_EOR* {.importc, header: "<sys/socket.h>".}: cint
    ## Terminates a record (if supported by the protocol).
  MSG_OOB* {.importc, header: "<sys/socket.h>".}: cint
    ## Out-of-band data.

proc WIFCONTINUED*(s:cint) : bool {.importc, header: "<sys/wait.h>".}
  ## True if child has been continued.
proc WIFEXITED*(s:cint) : bool {.importc, header: "<sys/wait.h>".}
  ## True if child exited normally.
proc WIFSIGNALED*(s:cint) : bool {.importc, header: "<sys/wait.h>".}
  ## True if child exited due to uncaught signal.
proc WIFSTOPPED*(s:cint) : bool {.importc, header: "<sys/wait.h>".}
  ## True if child is currently stopped.

when defined(linux):
  var
    MAP_POPULATE* {.importc, header: "<sys/mman.h>".}: cint
      ## Populate (prefault) page tables for a mapping.
else:
  var
    MAP_POPULATE*: cint = 0


when defined(macosx):
  # We can't use the NOSIGNAL flag in the ``send`` function, it has no effect
  var
    MSG_NOSIGNAL* = 0'i32
else:
  var
    MSG_NOSIGNAL* {.importc, header: "<sys/socket.h>".}: cint
      ## No SIGPIPE generated when an attempt to send is made on a stream-oriented socket that is no longer connected.

var
  MSG_PEEK* {.importc, header: "<sys/socket.h>".}: cint
    ## Leave received data in queue.
  MSG_TRUNC* {.importc, header: "<sys/socket.h>".}: cint
    ## Normal data truncated.
  MSG_WAITALL* {.importc, header: "<sys/socket.h>".}: cint
    ## Attempt to fill the read buffer.

  AF_INET* {.importc, header: "<sys/socket.h>".}: cint
    ## Internet domain sockets for use with IPv4 addresses.
  AF_INET6* {.importc, header: "<sys/socket.h>".}: cint
    ## Internet domain sockets for use with IPv6 addresses.
  AF_UNIX* {.importc, header: "<sys/socket.h>".}: cint
    ## UNIX domain sockets.
  AF_UNSPEC* {.importc, header: "<sys/socket.h>".}: cint
    ## Unspecified.

  SHUT_RD* {.importc, header: "<sys/socket.h>".}: cint
    ## Disables further receive operations.
  SHUT_RDWR* {.importc, header: "<sys/socket.h>".}: cint
    ## Disables further send and receive operations.
  SHUT_WR* {.importc, header: "<sys/socket.h>".}: cint
    ## Disables further send operations.

  IF_NAMESIZE* {.importc, header: "<net/if.h>".}: cint

  IPPROTO_IP* {.importc, header: "<netinet/in.h>".}: cint
    ## Internet protocol.
  IPPROTO_IPV6* {.importc, header: "<netinet/in.h>".}: cint
    ## Internet Protocol Version 6.
  IPPROTO_ICMP* {.importc, header: "<netinet/in.h>".}: cint
    ## Control message protocol.
  IPPROTO_RAW* {.importc, header: "<netinet/in.h>".}: cint
    ## Raw IP Packets Protocol.
  IPPROTO_TCP* {.importc, header: "<netinet/in.h>".}: cint
    ## Transmission control protocol.
  IPPROTO_UDP* {.importc, header: "<netinet/in.h>".}: cint
    ## User datagram protocol.

  INADDR_ANY* {.importc, header: "<netinet/in.h>".}: TInAddrScalar
    ## IPv4 local host address.
  INADDR_BROADCAST* {.importc, header: "<netinet/in.h>".}: TInAddrScalar
    ## IPv4 broadcast address.

  INET_ADDRSTRLEN* {.importc, header: "<netinet/in.h>".}: cint
    ## 16. Length of the string form for IP.

  IPV6_JOIN_GROUP* {.importc, header: "<netinet/in.h>".}: cint
    ## Join a multicast group.
  IPV6_LEAVE_GROUP* {.importc, header: "<netinet/in.h>".}: cint
    ## Quit a multicast group.
  IPV6_MULTICAST_HOPS* {.importc, header: "<netinet/in.h>".}: cint
    ## Multicast hop limit.
  IPV6_MULTICAST_IF* {.importc, header: "<netinet/in.h>".}: cint
    ## Interface to use for outgoing multicast packets.
  IPV6_MULTICAST_LOOP* {.importc, header: "<netinet/in.h>".}: cint
    ## Multicast packets are delivered back to the local application.
  IPV6_UNICAST_HOPS* {.importc, header: "<netinet/in.h>".}: cint
    ## Unicast hop limit.
  IPV6_V6ONLY* {.importc, header: "<netinet/in.h>".}: cint
    ## Restrict AF_INET6 socket to IPv6 communications only.

  TCP_NODELAY* {.importc, header: "<netinet/tcp.h>".}: cint
    ## Avoid coalescing of small segments.

  IPPORT_RESERVED* {.importc, header: "<netdb.h>".}: cint

  HOST_NOT_FOUND* {.importc, header: "<netdb.h>".}: cint
  NO_DATA* {.importc, header: "<netdb.h>".}: cint
  NO_RECOVERY* {.importc, header: "<netdb.h>".}: cint
  TRY_AGAIN* {.importc, header: "<netdb.h>".}: cint

  AI_PASSIVE* {.importc, header: "<netdb.h>".}: cint
    ## Socket address is intended for bind().
  AI_CANONNAME* {.importc, header: "<netdb.h>".}: cint
    ## Request for canonical name.
  AI_NUMERICHOST* {.importc, header: "<netdb.h>".}: cint
    ## Return numeric host address as name.
  AI_NUMERICSERV* {.importc, header: "<netdb.h>".}: cint
    ## Inhibit service name resolution.
  AI_V4MAPPED* {.importc, header: "<netdb.h>".}: cint
     ## If no IPv6 addresses are found, query for IPv4 addresses and
     ## return them to the caller as IPv4-mapped IPv6 addresses.
  AI_ALL* {.importc, header: "<netdb.h>".}: cint
    ## Query for both IPv4 and IPv6 addresses.
  AI_ADDRCONFIG* {.importc, header: "<netdb.h>".}: cint
    ## Query for IPv4 addresses only when an IPv4 address is configured;
    ## query for IPv6 addresses only when an IPv6 address is configured.

  NI_NOFQDN* {.importc, header: "<netdb.h>".}: cint
    ## Only the nodename portion of the FQDN is returned for local hosts.
  NI_NUMERICHOST* {.importc, header: "<netdb.h>".}: cint
    ## The numeric form of the node's address is returned instead of its name.
  NI_NAMEREQD* {.importc, header: "<netdb.h>".}: cint
    ## Return an error if the node's name cannot be located in the database.
  NI_NUMERICSERV* {.importc, header: "<netdb.h>".}: cint
    ## The numeric form of the service address is returned instead of its name.
  NI_NUMERICSCOPE* {.importc, header: "<netdb.h>".}: cint
    ## For IPv6 addresses, the numeric form of the scope identifier is
    ## returned instead of its name.
  NI_DGRAM* {.importc, header: "<netdb.h>".}: cint
    ## Indicates that the service is a datagram service (SOCK_DGRAM).

  EAI_AGAIN* {.importc, header: "<netdb.h>".}: cint
    ## The name could not be resolved at this time. Future attempts may succeed.
  EAI_BADFLAGS* {.importc, header: "<netdb.h>".}: cint
    ## The flags had an invalid value.
  EAI_FAIL* {.importc, header: "<netdb.h>".}: cint
    ## A non-recoverable error occurred.
  EAI_FAMILY* {.importc, header: "<netdb.h>".}: cint
    ## The address family was not recognized or the address length
    ## was invalid for the specified family.
  EAI_MEMORY* {.importc, header: "<netdb.h>".}: cint
    ## There was a memory allocation failure.
  EAI_NONAME* {.importc, header: "<netdb.h>".}: cint
    ## The name does not resolve for the supplied parameters.
    ## NI_NAMEREQD is set and the host's name cannot be located,
    ## or both nodename and servname were null.
  EAI_SERVICE* {.importc, header: "<netdb.h>".}: cint
    ## The service passed was not recognized for the specified socket type.
  EAI_SOCKTYPE* {.importc, header: "<netdb.h>".}: cint
    ## The intended socket type was not recognized.
  EAI_SYSTEM* {.importc, header: "<netdb.h>".}: cint
    ## A system error occurred. The error code can be found in errno.
  EAI_OVERFLOW* {.importc, header: "<netdb.h>".}: cint
    ## An argument buffer overflowed.

  POLLIN* {.importc, header: "<poll.h>".}: cshort
    ## Data other than high-priority data may be read without blocking.
  POLLRDNORM* {.importc, header: "<poll.h>".}: cshort
    ## Normal data may be read without blocking.
  POLLRDBAND* {.importc, header: "<poll.h>".}: cshort
    ## Priority data may be read without blocking.
  POLLPRI* {.importc, header: "<poll.h>".}: cshort
    ## High priority data may be read without blocking.
  POLLOUT* {.importc, header: "<poll.h>".}: cshort
    ## Normal data may be written without blocking.
  POLLWRNORM* {.importc, header: "<poll.h>".}: cshort
    ## Equivalent to POLLOUT.
  POLLWRBAND* {.importc, header: "<poll.h>".}: cshort
    ## Priority data may be written.
  POLLERR* {.importc, header: "<poll.h>".}: cshort
    ## An error has occurred (revents only).
  POLLHUP* {.importc, header: "<poll.h>".}: cshort
    ## Device has been disconnected (revents only).
  POLLNVAL* {.importc, header: "<poll.h>".}: cshort
    ## Invalid fd member (revents only).


when hasSpawnH:
  var
    POSIX_SPAWN_RESETIDS* {.importc, header: "<spawn.h>".}: cint
    POSIX_SPAWN_SETPGROUP* {.importc, header: "<spawn.h>".}: cint
    POSIX_SPAWN_SETSCHEDPARAM* {.importc, header: "<spawn.h>".}: cint
    POSIX_SPAWN_SETSCHEDULER* {.importc, header: "<spawn.h>".}: cint
    POSIX_SPAWN_SETSIGDEF* {.importc, header: "<spawn.h>".}: cint
    POSIX_SPAWN_SETSIGMASK* {.importc, header: "<spawn.h>".}: cint

  when defined(linux):
    # better be safe than sorry; Linux has this flag, macosx doesn't, don't
    # know about the other OSes

    # Non-GNU systems like TCC and musl-libc  don't define __USE_GNU, so we
    # can't get the magic number from spawn.h
    const POSIX_SPAWN_USEVFORK* = cint(0x40)
  else:
    # macosx lacks this, so we define the constant to be 0 to not affect
    # OR'ing of flags:
    const POSIX_SPAWN_USEVFORK* = cint(0)

when hasAioH:
  proc aio_cancel*(a1: cint, a2: ptr Taiocb): cint {.importc, header: "<aio.h>".}
  proc aio_error*(a1: ptr Taiocb): cint {.importc, header: "<aio.h>".}
  proc aio_fsync*(a1: cint, a2: ptr Taiocb): cint {.importc, header: "<aio.h>".}
  proc aio_read*(a1: ptr Taiocb): cint {.importc, header: "<aio.h>".}
  proc aio_return*(a1: ptr Taiocb): int {.importc, header: "<aio.h>".}
  proc aio_suspend*(a1: ptr ptr Taiocb, a2: cint, a3: ptr Ttimespec): cint {.
                   importc, header: "<aio.h>".}
  proc aio_write*(a1: ptr Taiocb): cint {.importc, header: "<aio.h>".}
  proc lio_listio*(a1: cint, a2: ptr ptr Taiocb, a3: cint,
               a4: ptr TsigEvent): cint {.importc, header: "<aio.h>".}

# arpa/inet.h
proc htonl*(a1: int32): int32 {.importc, header: "<arpa/inet.h>".}
proc htons*(a1: int16): int16 {.importc, header: "<arpa/inet.h>".}
proc ntohl*(a1: int32): int32 {.importc, header: "<arpa/inet.h>".}
proc ntohs*(a1: int16): int16 {.importc, header: "<arpa/inet.h>".}

proc inet_addr*(a1: cstring): TInAddrT {.importc, header: "<arpa/inet.h>".}
proc inet_ntoa*(a1: InAddr): cstring {.importc, header: "<arpa/inet.h>".}
proc inet_ntop*(a1: cint, a2: pointer, a3: cstring, a4: int32): cstring {.
  importc, header: "<arpa/inet.h>".}
proc inet_pton*(a1: cint, a2: cstring, a3: pointer): cint {.
  importc, header: "<arpa/inet.h>".}

var
  in6addr_any* {.importc, header: "<netinet/in.h>".}: TIn6Addr
  in6addr_loopback* {.importc, header: "<netinet/in.h>".}: TIn6Addr

proc IN6ADDR_ANY_INIT* (): TIn6Addr {.importc, header: "<netinet/in.h>".}
proc IN6ADDR_LOOPBACK_INIT* (): TIn6Addr {.importc, header: "<netinet/in.h>".}

# dirent.h
proc closedir*(a1: ptr TDIR): cint  {.importc, header: "<dirent.h>".}
proc opendir*(a1: cstring): ptr TDIR {.importc, header: "<dirent.h>".}
proc readdir*(a1: ptr TDIR): ptr Tdirent  {.importc, header: "<dirent.h>".}
proc readdir_r*(a1: ptr TDIR, a2: ptr Tdirent, a3: ptr ptr Tdirent): cint  {.
                importc, header: "<dirent.h>".}
proc rewinddir*(a1: ptr TDIR)  {.importc, header: "<dirent.h>".}
proc seekdir*(a1: ptr TDIR, a2: int)  {.importc, header: "<dirent.h>".}
proc telldir*(a1: ptr TDIR): int {.importc, header: "<dirent.h>".}

# dlfcn.h
proc dlclose*(a1: pointer): cint {.importc, header: "<dlfcn.h>".}
proc dlerror*(): cstring {.importc, header: "<dlfcn.h>".}
proc dlopen*(a1: cstring, a2: cint): pointer {.importc, header: "<dlfcn.h>".}
proc dlsym*(a1: pointer, a2: cstring): pointer {.importc, header: "<dlfcn.h>".}

proc creat*(a1: cstring, a2: TMode): cint {.importc, header: "<fcntl.h>".}
proc fcntl*(a1: cint | SocketHandle, a2: cint): cint {.varargs, importc, header: "<fcntl.h>".}
proc open*(a1: cstring, a2: cint): cint {.varargs, importc, header: "<fcntl.h>".}
proc posix_fadvise*(a1: cint, a2, a3: TOff, a4: cint): cint {.
  importc, header: "<fcntl.h>".}
proc posix_fallocate*(a1: cint, a2, a3: TOff): cint {.
  importc, header: "<fcntl.h>".}

when not defined(haiku) and not defined(OpenBSD):
  proc fmtmsg*(a1: int, a2: cstring, a3: cint,
              a4, a5, a6: cstring): cint {.importc, header: "<fmtmsg.h>".}

proc fnmatch*(a1, a2: cstring, a3: cint): cint {.importc, header: "<fnmatch.h>".}
proc ftw*(a1: cstring,
         a2: proc (x1: cstring, x2: ptr TStat, x3: cint): cint {.noconv.},
         a3: cint): cint {.importc, header: "<ftw.h>".}
proc nftw*(a1: cstring,
          a2: proc (x1: cstring, x2: ptr TStat,
                    x3: cint, x4: ptr TFTW): cint {.noconv.},
          a3: cint,
          a4: cint): cint {.importc, header: "<ftw.h>".}

proc glob*(a1: cstring, a2: cint,
          a3: proc (x1: cstring, x2: cint): cint {.noconv.},
          a4: ptr TGlob): cint {.importc, header: "<glob.h>".}
proc globfree*(a1: ptr TGlob) {.importc, header: "<glob.h>".}

proc getgrgid*(a1: TGid): ptr TGroup {.importc, header: "<grp.h>".}
proc getgrnam*(a1: cstring): ptr TGroup {.importc, header: "<grp.h>".}
proc getgrgid_r*(a1: TGid, a2: ptr TGroup, a3: cstring, a4: int,
                 a5: ptr ptr TGroup): cint {.importc, header: "<grp.h>".}
proc getgrnam_r*(a1: cstring, a2: ptr TGroup, a3: cstring,
                  a4: int, a5: ptr ptr TGroup): cint {.
                 importc, header: "<grp.h>".}
proc getgrent*(): ptr TGroup {.importc, header: "<grp.h>".}
proc endgrent*() {.importc, header: "<grp.h>".}
proc setgrent*() {.importc, header: "<grp.h>".}


proc iconv_open*(a1, a2: cstring): Ticonv {.importc, header: "<iconv.h>".}
proc iconv*(a1: Ticonv, a2: var cstring, a3: var int, a4: var cstring,
            a5: var int): int {.importc, header: "<iconv.h>".}
proc iconv_close*(a1: Ticonv): cint {.importc, header: "<iconv.h>".}

proc nl_langinfo*(a1: Tnl_item): cstring {.importc, header: "<langinfo.h>".}

proc basename*(a1: cstring): cstring {.importc, header: "<libgen.h>".}
proc dirname*(a1: cstring): cstring {.importc, header: "<libgen.h>".}

proc localeconv*(): ptr Tlconv {.importc, header: "<locale.h>".}
proc setlocale*(a1: cint, a2: cstring): cstring {.
                importc, header: "<locale.h>".}

proc strfmon*(a1: cstring, a2: int, a3: cstring): int {.varargs,
   importc, header: "<monetary.h>".}

proc mq_close*(a1: TMqd): cint {.importc, header: "<mqueue.h>".}
proc mq_getattr*(a1: TMqd, a2: ptr TMqAttr): cint {.
  importc, header: "<mqueue.h>".}
proc mq_notify*(a1: TMqd, a2: ptr TsigEvent): cint {.
  importc, header: "<mqueue.h>".}
proc mq_open*(a1: cstring, a2: cint): TMqd {.
  varargs, importc, header: "<mqueue.h>".}
proc mq_receive*(a1: TMqd, a2: cstring, a3: int, a4: var int): int {.
  importc, header: "<mqueue.h>".}
proc mq_send*(a1: TMqd, a2: cstring, a3: int, a4: int): cint {.
  importc, header: "<mqueue.h>".}
proc mq_setattr*(a1: TMqd, a2, a3: ptr TMqAttr): cint {.
  importc, header: "<mqueue.h>".}

proc mq_timedreceive*(a1: TMqd, a2: cstring, a3: int, a4: int,
                      a5: ptr Ttimespec): int {.importc, header: "<mqueue.h>".}
proc mq_timedsend*(a1: TMqd, a2: cstring, a3: int, a4: int,
                   a5: ptr Ttimespec): cint {.importc, header: "<mqueue.h>".}
proc mq_unlink*(a1: cstring): cint {.importc, header: "<mqueue.h>".}


proc getpwnam*(a1: cstring): ptr TPasswd {.importc, header: "<pwd.h>".}
proc getpwuid*(a1: Tuid): ptr TPasswd {.importc, header: "<pwd.h>".}
proc getpwnam_r*(a1: cstring, a2: ptr TPasswd, a3: cstring, a4: int,
                 a5: ptr ptr TPasswd): cint {.importc, header: "<pwd.h>".}
proc getpwuid_r*(a1: Tuid, a2: ptr TPasswd, a3: cstring,
      a4: int, a5: ptr ptr TPasswd): cint {.importc, header: "<pwd.h>".}
proc endpwent*() {.importc, header: "<pwd.h>".}
proc getpwent*(): ptr TPasswd {.importc, header: "<pwd.h>".}
proc setpwent*() {.importc, header: "<pwd.h>".}

proc uname*(a1: var Tutsname): cint {.importc, header: "<sys/utsname.h>".}

proc pthread_atfork*(a1, a2, a3: proc () {.noconv.}): cint {.
  importc, header: "<pthread.h>".}
proc pthread_attr_destroy*(a1: ptr Tpthread_attr): cint {.
  importc, header: "<pthread.h>".}
proc pthread_attr_getdetachstate*(a1: ptr Tpthread_attr, a2: cint): cint {.
  importc, header: "<pthread.h>".}
proc pthread_attr_getguardsize*(a1: ptr Tpthread_attr, a2: var cint): cint {.
  importc, header: "<pthread.h>".}
proc pthread_attr_getinheritsched*(a1: ptr Tpthread_attr,
          a2: var cint): cint {.importc, header: "<pthread.h>".}
proc pthread_attr_getschedparam*(a1: ptr Tpthread_attr,
          a2: ptr Tsched_param): cint {.importc, header: "<pthread.h>".}
proc pthread_attr_getschedpolicy*(a1: ptr Tpthread_attr,
          a2: var cint): cint {.importc, header: "<pthread.h>".}
proc pthread_attr_getscope*(a1: ptr Tpthread_attr,
          a2: var cint): cint {.importc, header: "<pthread.h>".}
proc pthread_attr_getstack*(a1: ptr Tpthread_attr,
         a2: var pointer, a3: var int): cint {.importc, header: "<pthread.h>".}
proc pthread_attr_getstackaddr*(a1: ptr Tpthread_attr,
          a2: var pointer): cint {.importc, header: "<pthread.h>".}
proc pthread_attr_getstacksize*(a1: ptr Tpthread_attr,
          a2: var int): cint {.importc, header: "<pthread.h>".}
proc pthread_attr_init*(a1: ptr Tpthread_attr): cint {.
  importc, header: "<pthread.h>".}
proc pthread_attr_setdetachstate*(a1: ptr Tpthread_attr, a2: cint): cint {.
  importc, header: "<pthread.h>".}
proc pthread_attr_setguardsize*(a1: ptr Tpthread_attr, a2: int): cint {.
  importc, header: "<pthread.h>".}
proc pthread_attr_setinheritsched*(a1: ptr Tpthread_attr, a2: cint): cint {.
  importc, header: "<pthread.h>".}
proc pthread_attr_setschedparam*(a1: ptr Tpthread_attr,
          a2: ptr Tsched_param): cint {.importc, header: "<pthread.h>".}
proc pthread_attr_setschedpolicy*(a1: ptr Tpthread_attr, a2: cint): cint {.
  importc, header: "<pthread.h>".}
proc pthread_attr_setscope*(a1: ptr Tpthread_attr, a2: cint): cint {.importc,
  header: "<pthread.h>".}
proc pthread_attr_setstack*(a1: ptr Tpthread_attr, a2: pointer, a3: int): cint {.
  importc, header: "<pthread.h>".}
proc pthread_attr_setstackaddr*(a1: ptr Tpthread_attr, a2: pointer): cint {.
  importc, header: "<pthread.h>".}
proc pthread_attr_setstacksize*(a1: ptr Tpthread_attr, a2: int): cint {.
  importc, header: "<pthread.h>".}
proc pthread_barrier_destroy*(a1: ptr Tpthread_barrier): cint {.
  importc, header: "<pthread.h>".}
proc pthread_barrier_init*(a1: ptr Tpthread_barrier,
         a2: ptr Tpthread_barrierattr, a3: cint): cint {.
         importc, header: "<pthread.h>".}
proc pthread_barrier_wait*(a1: ptr Tpthread_barrier): cint {.
  importc, header: "<pthread.h>".}
proc pthread_barrierattr_destroy*(a1: ptr Tpthread_barrierattr): cint {.
  importc, header: "<pthread.h>".}
proc pthread_barrierattr_getpshared*(
          a1: ptr Tpthread_barrierattr, a2: var cint): cint {.
          importc, header: "<pthread.h>".}
proc pthread_barrierattr_init*(a1: ptr Tpthread_barrierattr): cint {.
  importc, header: "<pthread.h>".}
proc pthread_barrierattr_setpshared*(a1: ptr Tpthread_barrierattr,
  a2: cint): cint {.importc, header: "<pthread.h>".}
proc pthread_cancel*(a1: Tpthread): cint {.importc, header: "<pthread.h>".}
proc pthread_cleanup_push*(a1: proc (x: pointer) {.noconv.}, a2: pointer) {.
  importc, header: "<pthread.h>".}
proc pthread_cleanup_pop*(a1: cint) {.importc, header: "<pthread.h>".}
proc pthread_cond_broadcast*(a1: ptr Tpthread_cond): cint {.
  importc, header: "<pthread.h>".}
proc pthread_cond_destroy*(a1: ptr Tpthread_cond): cint {.importc, header: "<pthread.h>".}
proc pthread_cond_init*(a1: ptr Tpthread_cond,
          a2: ptr Tpthread_condattr): cint {.importc, header: "<pthread.h>".}
proc pthread_cond_signal*(a1: ptr Tpthread_cond): cint {.importc, header: "<pthread.h>".}
proc pthread_cond_timedwait*(a1: ptr Tpthread_cond,
          a2: ptr Tpthread_mutex, a3: ptr Ttimespec): cint {.importc, header: "<pthread.h>".}

proc pthread_cond_wait*(a1: ptr Tpthread_cond,
          a2: ptr Tpthread_mutex): cint {.importc, header: "<pthread.h>".}
proc pthread_condattr_destroy*(a1: ptr Tpthread_condattr): cint {.importc, header: "<pthread.h>".}
proc pthread_condattr_getclock*(a1: ptr Tpthread_condattr,
          a2: var TClockId): cint {.importc, header: "<pthread.h>".}
proc pthread_condattr_getpshared*(a1: ptr Tpthread_condattr,
          a2: var cint): cint {.importc, header: "<pthread.h>".}

proc pthread_condattr_init*(a1: ptr Tpthread_condattr): cint {.importc, header: "<pthread.h>".}
proc pthread_condattr_setclock*(a1: ptr Tpthread_condattr,a2: TClockId): cint {.importc, header: "<pthread.h>".}
proc pthread_condattr_setpshared*(a1: ptr Tpthread_condattr, a2: cint): cint {.importc, header: "<pthread.h>".}

proc pthread_create*(a1: ptr Tpthread, a2: ptr Tpthread_attr,
          a3: proc (x: pointer): pointer {.noconv.}, a4: pointer): cint {.importc, header: "<pthread.h>".}
proc pthread_detach*(a1: Tpthread): cint {.importc, header: "<pthread.h>".}
proc pthread_equal*(a1, a2: Tpthread): cint {.importc, header: "<pthread.h>".}
proc pthread_exit*(a1: pointer) {.importc, header: "<pthread.h>".}
proc pthread_getconcurrency*(): cint {.importc, header: "<pthread.h>".}
proc pthread_getcpuclockid*(a1: Tpthread, a2: var TClockId): cint {.importc, header: "<pthread.h>".}
proc pthread_getschedparam*(a1: Tpthread,  a2: var cint,
          a3: ptr Tsched_param): cint {.importc, header: "<pthread.h>".}
proc pthread_getspecific*(a1: Tpthread_key): pointer {.importc, header: "<pthread.h>".}
proc pthread_join*(a1: Tpthread, a2: ptr pointer): cint {.importc, header: "<pthread.h>".}
proc pthread_key_create*(a1: ptr Tpthread_key, a2: proc (x: pointer) {.noconv.}): cint {.importc, header: "<pthread.h>".}
proc pthread_key_delete*(a1: Tpthread_key): cint {.importc, header: "<pthread.h>".}

proc pthread_mutex_destroy*(a1: ptr Tpthread_mutex): cint {.importc, header: "<pthread.h>".}
proc pthread_mutex_getprioceiling*(a1: ptr Tpthread_mutex,
         a2: var cint): cint {.importc, header: "<pthread.h>".}
proc pthread_mutex_init*(a1: ptr Tpthread_mutex,
          a2: ptr Tpthread_mutexattr): cint {.importc, header: "<pthread.h>".}
proc pthread_mutex_lock*(a1: ptr Tpthread_mutex): cint {.importc, header: "<pthread.h>".}
proc pthread_mutex_setprioceiling*(a1: ptr Tpthread_mutex,a2: cint,
          a3: var cint): cint {.importc, header: "<pthread.h>".}
proc pthread_mutex_timedlock*(a1: ptr Tpthread_mutex,
          a2: ptr Ttimespec): cint {.importc, header: "<pthread.h>".}
proc pthread_mutex_trylock*(a1: ptr Tpthread_mutex): cint {.importc, header: "<pthread.h>".}
proc pthread_mutex_unlock*(a1: ptr Tpthread_mutex): cint {.importc, header: "<pthread.h>".}
proc pthread_mutexattr_destroy*(a1: ptr Tpthread_mutexattr): cint {.importc, header: "<pthread.h>".}

proc pthread_mutexattr_getprioceiling*(
          a1: ptr Tpthread_mutexattr, a2: var cint): cint {.importc, header: "<pthread.h>".}
proc pthread_mutexattr_getprotocol*(a1: ptr Tpthread_mutexattr,
          a2: var cint): cint {.importc, header: "<pthread.h>".}
proc pthread_mutexattr_getpshared*(a1: ptr Tpthread_mutexattr,
          a2: var cint): cint {.importc, header: "<pthread.h>".}
proc pthread_mutexattr_gettype*(a1: ptr Tpthread_mutexattr,
          a2: var cint): cint {.importc, header: "<pthread.h>".}

proc pthread_mutexattr_init*(a1: ptr Tpthread_mutexattr): cint {.importc, header: "<pthread.h>".}
proc pthread_mutexattr_setprioceiling*(a1: ptr Tpthread_mutexattr, a2: cint): cint {.importc, header: "<pthread.h>".}
proc pthread_mutexattr_setprotocol*(a1: ptr Tpthread_mutexattr, a2: cint): cint {.importc, header: "<pthread.h>".}
proc pthread_mutexattr_setpshared*(a1: ptr Tpthread_mutexattr, a2: cint): cint {.importc, header: "<pthread.h>".}
proc pthread_mutexattr_settype*(a1: ptr Tpthread_mutexattr, a2: cint): cint {.importc, header: "<pthread.h>".}

proc pthread_once*(a1: ptr Tpthread_once, a2: proc () {.noconv.}): cint {.importc, header: "<pthread.h>".}

proc pthread_rwlock_destroy*(a1: ptr Tpthread_rwlock): cint {.importc, header: "<pthread.h>".}
proc pthread_rwlock_init*(a1: ptr Tpthread_rwlock,
          a2: ptr Tpthread_rwlockattr): cint {.importc, header: "<pthread.h>".}
proc pthread_rwlock_rdlock*(a1: ptr Tpthread_rwlock): cint {.importc, header: "<pthread.h>".}
proc pthread_rwlock_timedrdlock*(a1: ptr Tpthread_rwlock,
          a2: ptr Ttimespec): cint {.importc, header: "<pthread.h>".}
proc pthread_rwlock_timedwrlock*(a1: ptr Tpthread_rwlock,
          a2: ptr Ttimespec): cint {.importc, header: "<pthread.h>".}

proc pthread_rwlock_tryrdlock*(a1: ptr Tpthread_rwlock): cint {.importc, header: "<pthread.h>".}
proc pthread_rwlock_trywrlock*(a1: ptr Tpthread_rwlock): cint {.importc, header: "<pthread.h>".}
proc pthread_rwlock_unlock*(a1: ptr Tpthread_rwlock): cint {.importc, header: "<pthread.h>".}
proc pthread_rwlock_wrlock*(a1: ptr Tpthread_rwlock): cint {.importc, header: "<pthread.h>".}
proc pthread_rwlockattr_destroy*(a1: ptr Tpthread_rwlockattr): cint {.importc, header: "<pthread.h>".}
proc pthread_rwlockattr_getpshared*(
          a1: ptr Tpthread_rwlockattr, a2: var cint): cint {.importc, header: "<pthread.h>".}
proc pthread_rwlockattr_init*(a1: ptr Tpthread_rwlockattr): cint {.importc, header: "<pthread.h>".}
proc pthread_rwlockattr_setpshared*(a1: ptr Tpthread_rwlockattr, a2: cint): cint {.importc, header: "<pthread.h>".}

proc pthread_self*(): Tpthread {.importc, header: "<pthread.h>".}
proc pthread_setcancelstate*(a1: cint, a2: var cint): cint {.importc, header: "<pthread.h>".}
proc pthread_setcanceltype*(a1: cint, a2: var cint): cint {.importc, header: "<pthread.h>".}
proc pthread_setconcurrency*(a1: cint): cint {.importc, header: "<pthread.h>".}
proc pthread_setschedparam*(a1: Tpthread, a2: cint,
          a3: ptr Tsched_param): cint {.importc, header: "<pthread.h>".}

proc pthread_setschedprio*(a1: Tpthread, a2: cint): cint {.
  importc, header: "<pthread.h>".}
proc pthread_setspecific*(a1: Tpthread_key, a2: pointer): cint {.
  importc, header: "<pthread.h>".}
proc pthread_spin_destroy*(a1: ptr Tpthread_spinlock): cint {.
  importc, header: "<pthread.h>".}
proc pthread_spin_init*(a1: ptr Tpthread_spinlock, a2: cint): cint {.
  importc, header: "<pthread.h>".}
proc pthread_spin_lock*(a1: ptr Tpthread_spinlock): cint {.
  importc, header: "<pthread.h>".}
proc pthread_spin_trylock*(a1: ptr Tpthread_spinlock): cint{.
  importc, header: "<pthread.h>".}
proc pthread_spin_unlock*(a1: ptr Tpthread_spinlock): cint {.
  importc, header: "<pthread.h>".}
proc pthread_testcancel*() {.importc, header: "<pthread.h>".}


proc exitnow*(code: int): void {.importc: "_exit", header: "<unistd.h>".}
proc access*(a1: cstring, a2: cint): cint {.importc, header: "<unistd.h>".}
proc alarm*(a1: cint): cint {.importc, header: "<unistd.h>".}
proc chdir*(a1: cstring): cint {.importc, header: "<unistd.h>".}
proc chown*(a1: cstring, a2: Tuid, a3: TGid): cint {.importc, header: "<unistd.h>".}
proc close*(a1: cint | SocketHandle): cint {.importc, header: "<unistd.h>".}
proc confstr*(a1: cint, a2: cstring, a3: int): int {.importc, header: "<unistd.h>".}
proc crypt*(a1, a2: cstring): cstring {.importc, header: "<unistd.h>".}
proc ctermid*(a1: cstring): cstring {.importc, header: "<unistd.h>".}
proc dup*(a1: cint): cint {.importc, header: "<unistd.h>".}
proc dup2*(a1, a2: cint): cint {.importc, header: "<unistd.h>".}
proc encrypt*(a1: array[0..63, char], a2: cint) {.importc, header: "<unistd.h>".}

proc execl*(a1, a2: cstring): cint {.varargs, importc, header: "<unistd.h>".}
proc execle*(a1, a2: cstring): cint {.varargs, importc, header: "<unistd.h>".}
proc execlp*(a1, a2: cstring): cint {.varargs, importc, header: "<unistd.h>".}
proc execv*(a1: cstring, a2: cstringArray): cint {.importc, header: "<unistd.h>".}
proc execve*(a1: cstring, a2, a3: cstringArray): cint {.
  importc, header: "<unistd.h>".}
proc execvp*(a1: cstring, a2: cstringArray): cint {.importc, header: "<unistd.h>".}
proc execvpe*(a1: cstring, a2: cstringArray, a3: cstringArray): cint {.importc, header: "<unistd.h>".}
proc fchown*(a1: cint, a2: Tuid, a3: TGid): cint {.importc, header: "<unistd.h>".}
proc fchdir*(a1: cint): cint {.importc, header: "<unistd.h>".}
proc fdatasync*(a1: cint): cint {.importc, header: "<unistd.h>".}
proc fork*(): TPid {.importc, header: "<unistd.h>".}
proc fpathconf*(a1, a2: cint): int {.importc, header: "<unistd.h>".}
proc fsync*(a1: cint): cint {.importc, header: "<unistd.h>".}
proc ftruncate*(a1: cint, a2: TOff): cint {.importc, header: "<unistd.h>".}
proc getcwd*(a1: cstring, a2: int): cstring {.importc, header: "<unistd.h>".}
proc getegid*(): TGid {.importc, header: "<unistd.h>".}
proc geteuid*(): Tuid {.importc, header: "<unistd.h>".}
proc getgid*(): TGid {.importc, header: "<unistd.h>".}

proc getgroups*(a1: cint, a2: ptr array[0..255, TGid]): cint {.
  importc, header: "<unistd.h>".}
proc gethostid*(): int {.importc, header: "<unistd.h>".}
proc gethostname*(a1: cstring, a2: int): cint {.importc, header: "<unistd.h>".}
proc getlogin*(): cstring {.importc, header: "<unistd.h>".}
proc getlogin_r*(a1: cstring, a2: int): cint {.importc, header: "<unistd.h>".}

proc getopt*(a1: cint, a2: cstringArray, a3: cstring): cint {.
  importc, header: "<unistd.h>".}
proc getpgid*(a1: TPid): TPid {.importc, header: "<unistd.h>".}
proc getpgrp*(): TPid {.importc, header: "<unistd.h>".}
proc getpid*(): TPid {.importc, header: "<unistd.h>".}
proc getppid*(): TPid {.importc, header: "<unistd.h>".}
proc getsid*(a1: TPid): TPid {.importc, header: "<unistd.h>".}
proc getuid*(): Tuid {.importc, header: "<unistd.h>".}
proc getwd*(a1: cstring): cstring {.importc, header: "<unistd.h>".}
proc isatty*(a1: cint): cint {.importc, header: "<unistd.h>".}
proc lchown*(a1: cstring, a2: Tuid, a3: TGid): cint {.importc, header: "<unistd.h>".}
proc link*(a1, a2: cstring): cint {.importc, header: "<unistd.h>".}

proc lockf*(a1, a2: cint, a3: TOff): cint {.importc, header: "<unistd.h>".}
proc lseek*(a1: cint, a2: TOff, a3: cint): TOff {.importc, header: "<unistd.h>".}
proc nice*(a1: cint): cint {.importc, header: "<unistd.h>".}
proc pathconf*(a1: cstring, a2: cint): int {.importc, header: "<unistd.h>".}

proc pause*(): cint {.importc, header: "<unistd.h>".}
proc pipe*(a: array[0..1, cint]): cint {.importc, header: "<unistd.h>".}
proc pread*(a1: cint, a2: pointer, a3: int, a4: TOff): int {.
  importc, header: "<unistd.h>".}
proc pwrite*(a1: cint, a2: pointer, a3: int, a4: TOff): int {.
  importc, header: "<unistd.h>".}
proc read*(a1: cint, a2: pointer, a3: int): int {.importc, header: "<unistd.h>".}
proc readlink*(a1, a2: cstring, a3: int): int {.importc, header: "<unistd.h>".}

proc rmdir*(a1: cstring): cint {.importc, header: "<unistd.h>".}
proc setegid*(a1: TGid): cint {.importc, header: "<unistd.h>".}
proc seteuid*(a1: Tuid): cint {.importc, header: "<unistd.h>".}
proc setgid*(a1: TGid): cint {.importc, header: "<unistd.h>".}

proc setpgid*(a1, a2: TPid): cint {.importc, header: "<unistd.h>".}
proc setpgrp*(): TPid {.importc, header: "<unistd.h>".}
proc setregid*(a1, a2: TGid): cint {.importc, header: "<unistd.h>".}
proc setreuid*(a1, a2: Tuid): cint {.importc, header: "<unistd.h>".}
proc setsid*(): TPid {.importc, header: "<unistd.h>".}
proc setuid*(a1: Tuid): cint {.importc, header: "<unistd.h>".}
proc sleep*(a1: cint): cint {.importc, header: "<unistd.h>".}
proc swab*(a1, a2: pointer, a3: int) {.importc, header: "<unistd.h>".}
proc symlink*(a1, a2: cstring): cint {.importc, header: "<unistd.h>".}
proc sync*() {.importc, header: "<unistd.h>".}
proc sysconf*(a1: cint): int {.importc, header: "<unistd.h>".}
proc tcgetpgrp*(a1: cint): TPid {.importc, header: "<unistd.h>".}
proc tcsetpgrp*(a1: cint, a2: TPid): cint {.importc, header: "<unistd.h>".}
proc truncate*(a1: cstring, a2: TOff): cint {.importc, header: "<unistd.h>".}
proc ttyname*(a1: cint): cstring {.importc, header: "<unistd.h>".}
proc ttyname_r*(a1: cint, a2: cstring, a3: int): cint {.
  importc, header: "<unistd.h>".}
proc ualarm*(a1, a2: Tuseconds): Tuseconds {.importc, header: "<unistd.h>".}
proc unlink*(a1: cstring): cint {.importc, header: "<unistd.h>".}
proc usleep*(a1: Tuseconds): cint {.importc, header: "<unistd.h>".}
proc vfork*(): TPid {.importc, header: "<unistd.h>".}
proc write*(a1: cint, a2: pointer, a3: int): int {.importc, header: "<unistd.h>".}

proc sem_close*(a1: ptr TSem): cint {.importc, header: "<semaphore.h>".}
proc sem_destroy*(a1: ptr TSem): cint {.importc, header: "<semaphore.h>".}
proc sem_getvalue*(a1: ptr TSem, a2: var cint): cint {.
  importc, header: "<semaphore.h>".}
proc sem_init*(a1: ptr TSem, a2: cint, a3: cint): cint {.
  importc, header: "<semaphore.h>".}
proc sem_open*(a1: cstring, a2: cint): ptr TSem {.
  varargs, importc, header: "<semaphore.h>".}
proc sem_post*(a1: ptr TSem): cint {.importc, header: "<semaphore.h>".}
proc sem_timedwait*(a1: ptr TSem, a2: ptr Ttimespec): cint {.
  importc, header: "<semaphore.h>".}
proc sem_trywait*(a1: ptr TSem): cint {.importc, header: "<semaphore.h>".}
proc sem_unlink*(a1: cstring): cint {.importc, header: "<semaphore.h>".}
proc sem_wait*(a1: ptr TSem): cint {.importc, header: "<semaphore.h>".}

proc ftok*(a1: cstring, a2: cint): TKey {.importc, header: "<sys/ipc.h>".}

proc statvfs*(a1: cstring, a2: var TStatvfs): cint {.
  importc, header: "<sys/statvfs.h>".}
proc fstatvfs*(a1: cint, a2: var TStatvfs): cint {.
  importc, header: "<sys/statvfs.h>".}

proc chmod*(a1: cstring, a2: TMode): cint {.importc, header: "<sys/stat.h>".}
proc fchmod*(a1: cint, a2: TMode): cint {.importc, header: "<sys/stat.h>".}
proc fstat*(a1: cint, a2: var TStat): cint {.importc, header: "<sys/stat.h>".}
proc lstat*(a1: cstring, a2: var TStat): cint {.importc, header: "<sys/stat.h>".}
proc mkdir*(a1: cstring, a2: TMode): cint {.importc, header: "<sys/stat.h>".}
proc mkfifo*(a1: cstring, a2: TMode): cint {.importc, header: "<sys/stat.h>".}
proc mknod*(a1: cstring, a2: TMode, a3: TDev): cint {.
  importc, header: "<sys/stat.h>".}
proc stat*(a1: cstring, a2: var TStat): cint {.importc, header: "<sys/stat.h>".}
proc umask*(a1: TMode): TMode {.importc, header: "<sys/stat.h>".}

proc S_ISBLK*(m: TMode): bool {.importc, header: "<sys/stat.h>".}
  ## Test for a block special file.
proc S_ISCHR*(m: TMode): bool {.importc, header: "<sys/stat.h>".}
  ## Test for a character special file.
proc S_ISDIR*(m: TMode): bool {.importc, header: "<sys/stat.h>".}
  ## Test for a directory.
proc S_ISFIFO*(m: TMode): bool {.importc, header: "<sys/stat.h>".}
  ## Test for a pipe or FIFO special file.
proc S_ISREG*(m: TMode): bool {.importc, header: "<sys/stat.h>".}
  ## Test for a regular file.
proc S_ISLNK*(m: TMode): bool {.importc, header: "<sys/stat.h>".}
  ## Test for a symbolic link.
proc S_ISSOCK*(m: TMode): bool {.importc, header: "<sys/stat.h>".}
  ## Test for a socket.

proc S_TYPEISMQ*(buf: var TStat): bool {.importc, header: "<sys/stat.h>".}
  ## Test for a message queue.
proc S_TYPEISSEM*(buf: var TStat): bool {.importc, header: "<sys/stat.h>".}
  ## Test for a semaphore.
proc S_TYPEISSHM*(buf: var TStat): bool {.importc, header: "<sys/stat.h>".}
  ## Test for a shared memory object.

proc S_TYPEISTMO*(buf: var TStat): bool {.importc, header: "<sys/stat.h>".}
  ## Test macro for a typed memory object.

proc mlock*(a1: pointer, a2: int): cint {.importc, header: "<sys/mman.h>".}
proc mlockall*(a1: cint): cint {.importc, header: "<sys/mman.h>".}
proc mmap*(a1: pointer, a2: int, a3, a4, a5: cint, a6: TOff): pointer {.
  importc, header: "<sys/mman.h>".}
proc mprotect*(a1: pointer, a2: int, a3: cint): cint {.
  importc, header: "<sys/mman.h>".}
proc msync*(a1: pointer, a2: int, a3: cint): cint {.importc, header: "<sys/mman.h>".}
proc munlock*(a1: pointer, a2: int): cint {.importc, header: "<sys/mman.h>".}
proc munlockall*(): cint {.importc, header: "<sys/mman.h>".}
proc munmap*(a1: pointer, a2: int): cint {.importc, header: "<sys/mman.h>".}
proc posix_madvise*(a1: pointer, a2: int, a3: cint): cint {.
  importc, header: "<sys/mman.h>".}
proc posix_mem_offset*(a1: pointer, a2: int, a3: var TOff,
           a4: var int, a5: var cint): cint {.importc, header: "<sys/mman.h>".}
proc posix_typed_mem_get_info*(a1: cint,
  a2: var Tposix_typed_mem_info): cint {.importc, header: "<sys/mman.h>".}
proc posix_typed_mem_open*(a1: cstring, a2, a3: cint): cint {.
  importc, header: "<sys/mman.h>".}
proc shm_open*(a1: cstring, a2: cint, a3: TMode): cint {.
  importc, header: "<sys/mman.h>".}
proc shm_unlink*(a1: cstring): cint {.importc, header: "<sys/mman.h>".}

proc asctime*(a1: var Ttm): cstring{.importc, header: "<time.h>".}

proc asctime_r*(a1: var Ttm, a2: cstring): cstring {.importc, header: "<time.h>".}
proc clock*(): TClock {.importc, header: "<time.h>".}
proc clock_getcpuclockid*(a1: TPid, a2: var TClockId): cint {.
  importc, header: "<time.h>".}
proc clock_getres*(a1: TClockId, a2: var Ttimespec): cint {.
  importc, header: "<time.h>".}
proc clock_gettime*(a1: TClockId, a2: var Ttimespec): cint {.
  importc, header: "<time.h>".}
proc clock_nanosleep*(a1: TClockId, a2: cint, a3: var Ttimespec,
               a4: var Ttimespec): cint {.importc, header: "<time.h>".}
proc clock_settime*(a1: TClockId, a2: var Ttimespec): cint {.
  importc, header: "<time.h>".}

proc ctime*(a1: var Time): cstring {.importc, header: "<time.h>".}
proc ctime_r*(a1: var Time, a2: cstring): cstring {.importc, header: "<time.h>".}
proc difftime*(a1, a2: Time): cdouble {.importc, header: "<time.h>".}
proc getdate*(a1: cstring): ptr Ttm {.importc, header: "<time.h>".}

proc gmtime*(a1: var Time): ptr Ttm {.importc, header: "<time.h>".}
proc gmtime_r*(a1: var Time, a2: var Ttm): ptr Ttm {.importc, header: "<time.h>".}
proc localtime*(a1: var Time): ptr Ttm {.importc, header: "<time.h>".}
proc localtime_r*(a1: var Time, a2: var Ttm): ptr Ttm {.importc, header: "<time.h>".}
proc mktime*(a1: var Ttm): Time  {.importc, header: "<time.h>".}
proc timegm*(a1: var Ttm): Time  {.importc, header: "<time.h>".}
proc nanosleep*(a1, a2: var Ttimespec): cint {.importc, header: "<time.h>".}
proc strftime*(a1: cstring, a2: int, a3: cstring,
           a4: var Ttm): int {.importc, header: "<time.h>".}
proc strptime*(a1, a2: cstring, a3: var Ttm): cstring {.importc, header: "<time.h>".}
proc time*(a1: var Time): Time {.importc, header: "<time.h>".}
proc timer_create*(a1: var TClockId, a2: var TsigEvent,
               a3: var Ttimer): cint {.importc, header: "<time.h>".}
proc timer_delete*(a1: var Ttimer): cint {.importc, header: "<time.h>".}
proc timer_gettime*(a1: Ttimer, a2: var titimerspec): cint {.
  importc, header: "<time.h>".}
proc timer_getoverrun*(a1: Ttimer): cint {.importc, header: "<time.h>".}
proc timer_settime*(a1: Ttimer, a2: cint, a3: var titimerspec,
               a4: var titimerspec): cint {.importc, header: "<time.h>".}
proc tzset*() {.importc, header: "<time.h>".}


proc wait*(a1: var cint): TPid {.importc, header: "<sys/wait.h>".}
proc waitid*(a1: cint, a2: Tid, a3: var TsigInfo, a4: cint): cint {.
  importc, header: "<sys/wait.h>".}
proc waitpid*(a1: TPid, a2: var cint, a3: cint): TPid {.
  importc, header: "<sys/wait.h>".}

proc bsd_signal*(a1: cint, a2: proc (x: pointer) {.noconv.}) {.
  importc, header: "<signal.h>".}
proc kill*(a1: TPid, a2: cint): cint {.importc, header: "<signal.h>".}
proc killpg*(a1: TPid, a2: cint): cint {.importc, header: "<signal.h>".}
proc pthread_kill*(a1: Tpthread, a2: cint): cint {.importc, header: "<signal.h>".}
proc pthread_sigmask*(a1: cint, a2, a3: var Tsigset): cint {.
  importc, header: "<signal.h>".}
proc `raise`*(a1: cint): cint {.importc, header: "<signal.h>".}
proc sigaction*(a1: cint, a2, a3: var TSigaction): cint {.
  importc, header: "<signal.h>".}
proc sigaddset*(a1: var Tsigset, a2: cint): cint {.importc, header: "<signal.h>".}
proc sigaltstack*(a1, a2: var TStack): cint {.importc, header: "<signal.h>".}
proc sigdelset*(a1: var Tsigset, a2: cint): cint {.importc, header: "<signal.h>".}
proc sigemptyset*(a1: var Tsigset): cint {.importc, header: "<signal.h>".}
proc sigfillset*(a1: var Tsigset): cint {.importc, header: "<signal.h>".}
proc sighold*(a1: cint): cint {.importc, header: "<signal.h>".}
proc sigignore*(a1: cint): cint {.importc, header: "<signal.h>".}
proc siginterrupt*(a1, a2: cint): cint {.importc, header: "<signal.h>".}
proc sigismember*(a1: var Tsigset, a2: cint): cint {.importc, header: "<signal.h>".}
proc signal*(a1: cint, a2: proc (x: cint) {.noconv.}) {.
  importc, header: "<signal.h>".}
proc sigpause*(a1: cint): cint {.importc, header: "<signal.h>".}
proc sigpending*(a1: var Tsigset): cint {.importc, header: "<signal.h>".}
proc sigprocmask*(a1: cint, a2, a3: var Tsigset): cint {.
  importc, header: "<signal.h>".}
proc sigqueue*(a1: TPid, a2: cint, a3: TsigVal): cint {.
  importc, header: "<signal.h>".}
proc sigrelse*(a1: cint): cint {.importc, header: "<signal.h>".}
proc sigset*(a1: int, a2: proc (x: cint) {.noconv.}) {.
  importc, header: "<signal.h>".}
proc sigsuspend*(a1: var Tsigset): cint {.importc, header: "<signal.h>".}
proc sigtimedwait*(a1: var Tsigset, a2: var TsigInfo,
                   a3: var Ttimespec): cint {.importc, header: "<signal.h>".}
proc sigwait*(a1: var Tsigset, a2: var cint): cint {.
  importc, header: "<signal.h>".}
proc sigwaitinfo*(a1: var Tsigset, a2: var TsigInfo): cint {.
  importc, header: "<signal.h>".}


proc catclose*(a1: Tnl_catd): cint {.importc, header: "<nl_types.h>".}
proc catgets*(a1: Tnl_catd, a2, a3: cint, a4: cstring): cstring {.
  importc, header: "<nl_types.h>".}
proc catopen*(a1: cstring, a2: cint): Tnl_catd {.
  importc, header: "<nl_types.h>".}

proc sched_get_priority_max*(a1: cint): cint {.importc, header: "<sched.h>".}
proc sched_get_priority_min*(a1: cint): cint {.importc, header: "<sched.h>".}
proc sched_getparam*(a1: TPid, a2: var Tsched_param): cint {.
  importc, header: "<sched.h>".}
proc sched_getscheduler*(a1: TPid): cint {.importc, header: "<sched.h>".}
proc sched_rr_get_interval*(a1: TPid, a2: var Ttimespec): cint {.
  importc, header: "<sched.h>".}
proc sched_setparam*(a1: TPid, a2: var Tsched_param): cint {.
  importc, header: "<sched.h>".}
proc sched_setscheduler*(a1: TPid, a2: cint, a3: var Tsched_param): cint {.
  importc, header: "<sched.h>".}
proc sched_yield*(): cint {.importc, header: "<sched.h>".}

proc strerror*(errnum: cint): cstring {.importc, header: "<string.h>".}
proc hstrerror*(herrnum: cint): cstring {.importc, header: "<netdb.h>".}

proc FD_CLR*(a1: cint, a2: var TFdSet) {.importc, header: "<sys/select.h>".}
proc FD_ISSET*(a1: cint | SocketHandle, a2: var TFdSet): cint {.
  importc, header: "<sys/select.h>".}
proc FD_SET*(a1: cint | SocketHandle, a2: var TFdSet) {.
  importc: "FD_SET", header: "<sys/select.h>".}
proc FD_ZERO*(a1: var TFdSet) {.importc, header: "<sys/select.h>".}

proc pselect*(a1: cint, a2, a3, a4: ptr TFdSet, a5: ptr Ttimespec,
         a6: var Tsigset): cint  {.importc, header: "<sys/select.h>".}
proc select*(a1: cint | SocketHandle, a2, a3, a4: ptr TFdSet, a5: ptr Timeval): cint {.
             importc, header: "<sys/select.h>".}

when hasSpawnH:
  proc posix_spawn*(a1: var TPid, a2: cstring,
            a3: var Tposix_spawn_file_actions,
            a4: var Tposix_spawnattr,
            a5, a6: cstringArray): cint {.importc, header: "<spawn.h>".}
  proc posix_spawn_file_actions_addclose*(a1: var Tposix_spawn_file_actions,
            a2: cint): cint {.importc, header: "<spawn.h>".}
  proc posix_spawn_file_actions_adddup2*(a1: var Tposix_spawn_file_actions,
            a2, a3: cint): cint {.importc, header: "<spawn.h>".}
  proc posix_spawn_file_actions_addopen*(a1: var Tposix_spawn_file_actions,
            a2: cint, a3: cstring, a4: cint, a5: TMode): cint {.
            importc, header: "<spawn.h>".}
  proc posix_spawn_file_actions_destroy*(
    a1: var Tposix_spawn_file_actions): cint {.importc, header: "<spawn.h>".}
  proc posix_spawn_file_actions_init*(
    a1: var Tposix_spawn_file_actions): cint {.importc, header: "<spawn.h>".}
  proc posix_spawnattr_destroy*(a1: var Tposix_spawnattr): cint {.
    importc, header: "<spawn.h>".}
  proc posix_spawnattr_getsigdefault*(a1: var Tposix_spawnattr,
            a2: var Tsigset): cint {.importc, header: "<spawn.h>".}
  proc posix_spawnattr_getflags*(a1: var Tposix_spawnattr,
            a2: var cshort): cint {.importc, header: "<spawn.h>".}
  proc posix_spawnattr_getpgroup*(a1: var Tposix_spawnattr,
            a2: var TPid): cint {.importc, header: "<spawn.h>".}
  proc posix_spawnattr_getschedparam*(a1: var Tposix_spawnattr,
            a2: var Tsched_param): cint {.importc, header: "<spawn.h>".}
  proc posix_spawnattr_getschedpolicy*(a1: var Tposix_spawnattr,
            a2: var cint): cint {.importc, header: "<spawn.h>".}
  proc posix_spawnattr_getsigmask*(a1: var Tposix_spawnattr,
            a2: var Tsigset): cint {.importc, header: "<spawn.h>".}

  proc posix_spawnattr_init*(a1: var Tposix_spawnattr): cint {.
    importc, header: "<spawn.h>".}
  proc posix_spawnattr_setsigdefault*(a1: var Tposix_spawnattr,
            a2: var Tsigset): cint {.importc, header: "<spawn.h>".}
  proc posix_spawnattr_setflags*(a1: var Tposix_spawnattr, a2: cint): cint {.
    importc, header: "<spawn.h>".}
  proc posix_spawnattr_setpgroup*(a1: var Tposix_spawnattr, a2: TPid): cint {.
    importc, header: "<spawn.h>".}

  proc posix_spawnattr_setschedparam*(a1: var Tposix_spawnattr,
            a2: var Tsched_param): cint {.importc, header: "<spawn.h>".}
  proc posix_spawnattr_setschedpolicy*(a1: var Tposix_spawnattr,
                                       a2: cint): cint {.
                                       importc, header: "<spawn.h>".}
  proc posix_spawnattr_setsigmask*(a1: var Tposix_spawnattr,
            a2: var Tsigset): cint {.importc, header: "<spawn.h>".}
  proc posix_spawnp*(a1: var TPid, a2: cstring,
            a3: var Tposix_spawn_file_actions,
            a4: var Tposix_spawnattr,
            a5, a6: cstringArray): cint {.importc, header: "<spawn.h>".}

proc getcontext*(a1: var Tucontext): cint {.importc, header: "<ucontext.h>".}
proc makecontext*(a1: var Tucontext, a4: proc (){.noconv.}, a3: cint) {.
  varargs, importc, header: "<ucontext.h>".}
proc setcontext*(a1: var Tucontext): cint {.importc, header: "<ucontext.h>".}
proc swapcontext*(a1, a2: var Tucontext): cint {.importc, header: "<ucontext.h>".}

proc readv*(a1: cint, a2: ptr TIOVec, a3: cint): int {.
  importc, header: "<sys/uio.h>".}
proc writev*(a1: cint, a2: ptr TIOVec, a3: cint): int {.
  importc, header: "<sys/uio.h>".}

proc CMSG_DATA*(cmsg: ptr Tcmsghdr): cstring {.
  importc, header: "<sys/socket.h>".}

proc CMSG_NXTHDR*(mhdr: ptr Tmsghdr, cmsg: ptr Tcmsghdr): ptr Tcmsghdr {.
  importc, header: "<sys/socket.h>".}

proc CMSG_FIRSTHDR*(mhdr: ptr Tmsghdr): ptr Tcmsghdr {.
  importc, header: "<sys/socket.h>".}

const
  INVALID_SOCKET* = SocketHandle(-1)

proc `==`*(x, y: SocketHandle): bool {.borrow.}

proc accept*(a1: SocketHandle, a2: ptr SockAddr, a3: ptr Socklen): SocketHandle {.
  importc, header: "<sys/socket.h>".}

proc bindSocket*(a1: SocketHandle, a2: ptr SockAddr, a3: Socklen): cint {.
  importc: "bind", header: "<sys/socket.h>".}
  ## is Posix's ``bind``, because ``bind`` is a reserved word

proc connect*(a1: SocketHandle, a2: ptr SockAddr, a3: Socklen): cint {.
  importc, header: "<sys/socket.h>".}
proc getpeername*(a1: SocketHandle, a2: ptr SockAddr, a3: ptr Socklen): cint {.
  importc, header: "<sys/socket.h>".}
proc getsockname*(a1: SocketHandle, a2: ptr SockAddr, a3: ptr Socklen): cint {.
  importc, header: "<sys/socket.h>".}

proc getsockopt*(a1: SocketHandle, a2, a3: cint, a4: pointer, a5: ptr Socklen): cint {.
  importc, header: "<sys/socket.h>".}

proc listen*(a1: SocketHandle, a2: cint): cint {.
  importc, header: "<sys/socket.h>".}
proc recv*(a1: SocketHandle, a2: pointer, a3: int, a4: cint): int {.
  importc, header: "<sys/socket.h>".}
proc recvfrom*(a1: SocketHandle, a2: pointer, a3: int, a4: cint,
        a5: ptr SockAddr, a6: ptr Socklen): int {.
  importc, header: "<sys/socket.h>".}
proc recvmsg*(a1: SocketHandle, a2: ptr Tmsghdr, a3: cint): int {.
  importc, header: "<sys/socket.h>".}
proc send*(a1: SocketHandle, a2: pointer, a3: int, a4: cint): int {.
  importc, header: "<sys/socket.h>".}
proc sendmsg*(a1: SocketHandle, a2: ptr Tmsghdr, a3: cint): int {.
  importc, header: "<sys/socket.h>".}
proc sendto*(a1: SocketHandle, a2: pointer, a3: int, a4: cint, a5: ptr SockAddr,
             a6: Socklen): int {.
  importc, header: "<sys/socket.h>".}
proc setsockopt*(a1: SocketHandle, a2, a3: cint, a4: pointer, a5: Socklen): cint {.
  importc, header: "<sys/socket.h>".}
proc shutdown*(a1: SocketHandle, a2: cint): cint {.
  importc, header: "<sys/socket.h>".}
proc socket*(a1, a2, a3: cint): SocketHandle {.
  importc, header: "<sys/socket.h>".}
proc sockatmark*(a1: cint): cint {.
  importc, header: "<sys/socket.h>".}
proc socketpair*(a1, a2, a3: cint, a4: var array[0..1, cint]): cint {.
  importc, header: "<sys/socket.h>".}

proc if_nametoindex*(a1: cstring): cint {.importc, header: "<net/if.h>".}
proc if_indextoname*(a1: cint, a2: cstring): cstring {.
  importc, header: "<net/if.h>".}
proc if_nameindex*(): ptr Tif_nameindex {.importc, header: "<net/if.h>".}
proc if_freenameindex*(a1: ptr Tif_nameindex) {.importc, header: "<net/if.h>".}

proc IN6_IS_ADDR_UNSPECIFIED* (a1: ptr TIn6Addr): cint {.
  importc, header: "<netinet/in.h>".}
  ## Unspecified address.
proc IN6_IS_ADDR_LOOPBACK* (a1: ptr TIn6Addr): cint {.
  importc, header: "<netinet/in.h>".}
  ## Loopback address.
proc IN6_IS_ADDR_MULTICAST* (a1: ptr TIn6Addr): cint {.
  importc, header: "<netinet/in.h>".}
  ## Multicast address.
proc IN6_IS_ADDR_LINKLOCAL* (a1: ptr TIn6Addr): cint {.
  importc, header: "<netinet/in.h>".}
  ## Unicast link-local address.
proc IN6_IS_ADDR_SITELOCAL* (a1: ptr TIn6Addr): cint {.
  importc, header: "<netinet/in.h>".}
  ## Unicast site-local address.
proc IN6_IS_ADDR_V4MAPPED* (a1: ptr TIn6Addr): cint {.
  importc, header: "<netinet/in.h>".}
  ## IPv4 mapped address.
proc IN6_IS_ADDR_V4COMPAT* (a1: ptr TIn6Addr): cint {.
  importc, header: "<netinet/in.h>".}
  ## IPv4-compatible address.
proc IN6_IS_ADDR_MC_NODELOCAL* (a1: ptr TIn6Addr): cint {.
  importc, header: "<netinet/in.h>".}
  ## Multicast node-local address.
proc IN6_IS_ADDR_MC_LINKLOCAL* (a1: ptr TIn6Addr): cint {.
  importc, header: "<netinet/in.h>".}
  ## Multicast link-local address.
proc IN6_IS_ADDR_MC_SITELOCAL* (a1: ptr TIn6Addr): cint {.
  importc, header: "<netinet/in.h>".}
  ## Multicast site-local address.
proc IN6_IS_ADDR_MC_ORGLOCAL* (a1: ptr TIn6Addr): cint {.
  importc, header: "<netinet/in.h>".}
  ## Multicast organization-local address.
proc IN6_IS_ADDR_MC_GLOBAL* (a1: ptr TIn6Addr): cint {.
  importc, header: "<netinet/in.h>".}
  ## Multicast global address.

proc endhostent*() {.importc, header: "<netdb.h>".}
proc endnetent*() {.importc, header: "<netdb.h>".}
proc endprotoent*() {.importc, header: "<netdb.h>".}
proc endservent*() {.importc, header: "<netdb.h>".}
proc freeaddrinfo*(a1: ptr AddrInfo) {.importc, header: "<netdb.h>".}

proc gai_strerror*(a1: cint): cstring {.importc, header: "<netdb.h>".}

proc getaddrinfo*(a1, a2: cstring, a3: ptr AddrInfo,
                  a4: var ptr AddrInfo): cint {.importc, header: "<netdb.h>".}

proc gethostbyaddr*(a1: pointer, a2: Socklen, a3: cint): ptr Hostent {.
                    importc, header: "<netdb.h>".}
proc gethostbyname*(a1: cstring): ptr Hostent {.importc, header: "<netdb.h>".}
proc gethostent*(): ptr Hostent {.importc, header: "<netdb.h>".}

proc getnameinfo*(a1: ptr SockAddr, a2: Socklen,
                  a3: cstring, a4: Socklen, a5: cstring,
                  a6: Socklen, a7: cint): cint {.importc, header: "<netdb.h>".}

proc getnetbyaddr*(a1: int32, a2: cint): ptr Tnetent {.importc, header: "<netdb.h>".}
proc getnetbyname*(a1: cstring): ptr Tnetent {.importc, header: "<netdb.h>".}
proc getnetent*(): ptr Tnetent {.importc, header: "<netdb.h>".}

proc getprotobyname*(a1: cstring): ptr TProtoent {.importc, header: "<netdb.h>".}
proc getprotobynumber*(a1: cint): ptr TProtoent {.importc, header: "<netdb.h>".}
proc getprotoent*(): ptr TProtoent {.importc, header: "<netdb.h>".}

proc getservbyname*(a1, a2: cstring): ptr Servent {.importc, header: "<netdb.h>".}
proc getservbyport*(a1: cint, a2: cstring): ptr Servent {.
  importc, header: "<netdb.h>".}
proc getservent*(): ptr Servent {.importc, header: "<netdb.h>".}

proc sethostent*(a1: cint) {.importc, header: "<netdb.h>".}
proc setnetent*(a1: cint) {.importc, header: "<netdb.h>".}
proc setprotoent*(a1: cint) {.importc, header: "<netdb.h>".}
proc setservent*(a1: cint) {.importc, header: "<netdb.h>".}

proc poll*(a1: ptr TPollfd, a2: Tnfds, a3: int): cint {.
  importc, header: "<poll.h>".}

proc realpath*(name, resolved: cstring): cstring {.
  importc: "realpath", header: "<stdlib.h>".}

proc utimes*(path: cstring, times: ptr array [2, Timeval]): int {.
  importc: "utimes", header: "<sys/time.h>".}
  ## Sets file access and modification times.
  ##
  ## Pass the filename and an array of times to set the access and modification
  ## times respectively. If you pass nil as the array both attributes will be
  ## set to the current time.
  ##
  ## Returns zero on success.
  ##
  ## For more information read http://www.unix.com/man-page/posix/3/utimes/.
