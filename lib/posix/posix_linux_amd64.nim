#
#
#            Nim's Runtime Library
#        (c) Copyright 2012 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

# Types here should conform to the glibc ABI on linux / x86_64
# When adding a type, the order and size of fields must match

# To be included from posix.nim!

from times import Time

const
  hasSpawnH = not defined(haiku) # should exist for every Posix system nowadays
  hasAioH = defined(linux)

# On Linux:
# timer_{create,delete,settime,gettime},
# clock_{getcpuclockid, getres, gettime, nanosleep, settime} lives in librt
{.passL: "-lrt".}

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
  DIR* {.importc: "DIR", header: "<dirent.h>",
          incompleteStruct.} = object
    ## A type representing a directory stream.
{.deprecated: [TDIR: DIR].}

type
  SocketHandle* = distinct cint # The type used to represent socket descriptors

{.deprecated: [TSocketHandle: SocketHandle].}

type
  Timespec* {.importc: "struct timespec",
               header: "<time.h>", final, pure.} = object ## struct timespec
    tv_sec*: Time  ## Seconds.
    tv_nsec*: clong  ## Nanoseconds.

  Dirent* {.importc: "struct dirent",
             header: "<dirent.h>", final, pure.} = object ## dirent_t struct
    d_ino*: Ino
    d_off*: Off
    d_reclen*: cushort
    d_type*: int8  # cuchar really!
    d_name*: array[256, cchar]

  Tflock* {.importc: "struct flock", final, pure,
            header: "<fcntl.h>".} = object ## flock type
    l_type*: cshort   ## Type of lock; F_RDLCK, F_WRLCK, F_UNLCK.
    l_whence*: cshort ## Flag for starting offset.
    l_start*: Off     ## Relative offset in bytes.
    l_len*: Off       ## Size; if 0 then until EOF.
    l_pid*: Pid      ## Process ID of the process holding the lock;
                      ## returned with F_GETLK.

  # no struct FTW on linux

  Glob* {.importc: "glob_t", header: "<glob.h>",
           final, pure.} = object ## glob_t
    gl_pathc*: csize          ## Count of paths matched by pattern.
    gl_pathv*: cstringArray ## Pointer to a list of matched pathnames.
    gl_offs*: csize           ## Slots to reserve at the beginning of gl_pathv.
    gl_flags*: cint
    gl_closedir*: pointer
    gl_readdir*: pointer
    gl_opendir*: pointer
    gl_lstat*: pointer
    gl_stat*: pointer

  Group* {.importc: "struct group", header: "<grp.h>",
            final, pure.} = object ## struct group
    gr_name*: cstring     ## The name of the group.
    gr_passwd*: cstring
    gr_gid*: Gid         ## Numerical group ID.
    gr_mem*: cstringArray ## Pointer to a null-terminated array of character
                          ## pointers to member names.

  Iconv* {.importc: "iconv_t", header: "<iconv.h>".} = pointer
     ## Identifies the conversion from one codeset to another.

  Lconv* {.importc: "struct lconv", header: "<locale.h>", final,
            pure.} = object
    decimal_point*: cstring
    thousands_sep*: cstring
    grouping*: cstring
    int_curr_symbol*: cstring
    currency_symbol*: cstring
    mon_decimal_point*: cstring
    mon_thousands_sep*: cstring
    mon_grouping*: cstring
    positive_sign*: cstring
    negative_sign*: cstring
    int_frac_digits*: char
    frac_digits*: char
    p_cs_precedes*: char
    p_sep_by_space*: char
    n_cs_precedes*: char
    n_sep_by_space*: char
    p_sign_posn*: char
    n_sign_posn*: char
    int_p_cs_precedes*: char
    int_p_sep_by_space*: char
    int_n_cs_precedes*: char
    int_n_sep_by_space*: char
    int_p_sign_posn*: char
    int_n_sign_posn*: char

  Mqd* {.importc: "mqd_t", header: "<mqueue.h>".} = cint
  MqAttr* {.importc: "struct mq_attr",
             header: "<mqueue.h>",
             final, pure.} = object ## message queue attribute
    mq_flags*: clong   ## Message queue flags.
    mq_maxmsg*: clong  ## Maximum number of messages.
    mq_msgsize*: clong ## Maximum message size.
    mq_curmsgs*: clong ## Number of messages currently queued.
    pad: array[4, clong]

  Passwd* {.importc: "struct passwd", header: "<pwd.h>",
             final, pure.} = object ## struct passwd
    pw_name*: cstring   ## User's login name.
    pw_passwd*: cstring
    pw_uid*: Uid        ## Numerical user ID.
    pw_gid*: Gid        ## Numerical group ID.
    pw_gecos*: cstring
    pw_dir*: cstring    ## Initial working directory.
    pw_shell*: cstring  ## Program to use as shell.

  Blkcnt* {.importc: "blkcnt_t", header: "<sys/types.h>".} = clong
    ## used for file block counts
  Blksize* {.importc: "blksize_t", header: "<sys/types.h>".} = clong
    ## used for block sizes
  Clock* {.importc: "clock_t", header: "<sys/types.h>".} = clong
  ClockId* {.importc: "clockid_t", header: "<sys/types.h>".} = cint
  Dev* {.importc: "dev_t", header: "<sys/types.h>".} = culong
  Fsblkcnt* {.importc: "fsblkcnt_t", header: "<sys/types.h>".} = culong
  Fsfilcnt* {.importc: "fsfilcnt_t", header: "<sys/types.h>".} = culong
  Gid* {.importc: "gid_t", header: "<sys/types.h>".} = cuint
  Id* {.importc: "id_t", header: "<sys/types.h>".} = cuint
  Ino* {.importc: "ino_t", header: "<sys/types.h>".} = culong
  Key* {.importc: "key_t", header: "<sys/types.h>".} = cint
  Mode* {.importc: "mode_t", header: "<sys/types.h>".} = cint # cuint really!
  Nlink* {.importc: "nlink_t", header: "<sys/types.h>".} = culong
  Off* {.importc: "off_t", header: "<sys/types.h>".} = clong
  Pid* {.importc: "pid_t", header: "<sys/types.h>".} = cint
  Pthread_attr* {.importc: "pthread_attr_t", header: "<sys/types.h>",
                  pure, final.} = object
    abi: array[56, uint8]

  Pthread_barrier* {.importc: "pthread_barrier_t",
                      header: "<sys/types.h>", pure, final.} = object
    abi: array[32, uint8]
  Pthread_barrierattr* {.importc: "pthread_barrierattr_t",
                          header: "<sys/types.h>", pure, final.} = object
    abi: array[4, uint8]

  Pthread_cond* {.importc: "pthread_cond_t", header: "<sys/types.h>",
                  pure, final.} = object
    abi: array[48, uint8]
  Pthread_condattr* {.importc: "pthread_condattr_t",
                       header: "<sys/types.h>", pure, final.} = object
    abi: array[4, uint8]
  Pthread_key* {.importc: "pthread_key_t", header: "<sys/types.h>".} = cuint
  Pthread_mutex* {.importc: "pthread_mutex_t", header: "<sys/types.h>",
                   pure, final.} = object
    abi: array[48, uint8]
  Pthread_mutexattr* {.importc: "pthread_mutexattr_t",
                        header: "<sys/types.h>", pure, final.} = object
    abi: array[4, uint8]
  Pthread_once* {.importc: "pthread_once_t", header: "<sys/types.h>".} = cint
  Pthread_rwlock* {.importc: "pthread_rwlock_t",
                     header: "<sys/types.h>", pure, final.} = object
    abi: array[56, uint8]
  Pthread_rwlockattr* {.importc: "pthread_rwlockattr_t",
                         header: "<sys/types.h>".} = object
    abi: array[8, uint8]
  Pthread_spinlock* {.importc: "pthread_spinlock_t",
                       header: "<sys/types.h>".} = cint
  Pthread* {.importc: "pthread_t", header: "<sys/types.h>".} = culong
  Suseconds* {.importc: "suseconds_t", header: "<sys/types.h>".} = clong
  #Ttime* {.importc: "time_t", header: "<sys/types.h>".} = int
  Timer* {.importc: "timer_t", header: "<sys/types.h>".} = pointer
  Uid* {.importc: "uid_t", header: "<sys/types.h>".} = cuint
  Useconds* {.importc: "useconds_t", header: "<sys/types.h>".} = cuint

  Utsname* {.importc: "struct utsname",
              header: "<sys/utsname.h>",
              final, pure.} = object ## struct utsname
    sysname*,      ## Name of this implementation of the operating system.
      nodename*,   ## Name of this node within the communications
                   ## network to which this node is attached, if any.
      release*,    ## Current release level of this implementation.
      version*,    ## Current version level of this release.
      machine*,    ## Name of the hardware type on which the
                   ## system is running.
      domainname*: array[65, char]

  Sem* {.importc: "sem_t", header: "<semaphore.h>", final, pure.} = object
    abi: array[32, uint8]

  Ipc_perm* {.importc: "struct ipc_perm",
               header: "<sys/ipc.h>", final, pure.} = object ## struct ipc_perm
    key: Key
    uid*: Uid    ## Owner's user ID.
    gid*: Gid    ## Owner's group ID.
    cuid*: Uid   ## Creator's user ID.
    cgid*: Gid   ## Creator's group ID.
    mode*: cshort  ## Read/write permission.
    pad1: cshort
    seq1: cshort
    pad2: cshort
    reserved1: culong
    reserved2: culong

  Stat* {.importc: "struct stat",
           header: "<sys/stat.h>", final, pure.} = object ## struct stat
    st_dev*: Dev          ## Device ID of device containing file.
    st_ino*: Ino          ## File serial number.
    st_nlink*: Nlink      ## Number of hard links to the file.
    st_mode*: Mode        ## Mode of file (see below).
    st_uid*: Uid          ## User ID of file.
    st_gid*: Gid          ## Group ID of file.
    pad0: cint
    st_rdev*: Dev         ## Device ID (if file is character or block special).
    st_size*: Off         ## For regular files, the file size in bytes.
                           ## For symbolic links, the length in bytes of the
                           ## pathname contained in the symbolic link.
                           ## For a shared memory object, the length in bytes.
                           ## For a typed memory object, the length in bytes.
                           ## For other file types, the use of this field is
                           ## unspecified.
    st_blksize*: Blksize   ## A file system-specific preferred I/O block size
                           ## for this object. In some file system types, this
                           ## may vary from file to file.
    st_blocks*: Blkcnt     ## Number of blocks allocated for this object.
    st_atim*: Timespec   ## Time of last access.
    st_mtim*: Timespec   ## Time of last data modification.
    st_ctim*: Timespec   ## Time of last status change.
    reserved: array[3, clong]


  Statvfs* {.importc: "struct statvfs", header: "<sys/statvfs.h>",
              final, pure.} = object ## struct statvfs
    f_bsize*: culong        ## File system block size.
    f_frsize*: culong       ## Fundamental file system block size.
    f_blocks*: Fsblkcnt  ## Total number of blocks on file system
                         ## in units of f_frsize.
    f_bfree*: Fsblkcnt   ## Total number of free blocks.
    f_bavail*: Fsblkcnt  ## Number of free blocks available to
                         ## non-privileged process.
    f_files*: Fsfilcnt   ## Total number of file serial numbers.
    f_ffree*: Fsfilcnt   ## Total number of free file serial numbers.
    f_favail*: Fsfilcnt  ## Number of file serial numbers available to
                         ## non-privileged process.
    f_fsid*: culong         ## File system ID.
    f_flag*: culong         ## Bit mask of f_flag values.
    f_namemax*: culong      ## Maximum filename length.
    f_spare: array[6, cint]

  # No Posix_typed_mem_info

  Tm* {.importc: "struct tm", header: "<time.h>",
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
    tm_gmtoff*: clong
    tm_zone*: cstring

  Itimerspec* {.importc: "struct itimerspec", header: "<time.h>",
                 final, pure.} = object ## struct itimerspec
    it_interval*: Timespec  ## Timer period.
    it_value*: Timespec     ## Timer expiration.

  Sig_atomic* {.importc: "sig_atomic_t", header: "<signal.h>".} = cint
    ## Possibly volatile-qualified integer type of an object that can be
    ## accessed as an atomic entity, even in the presence of asynchronous
    ## interrupts.
  Sigset* {.importc: "sigset_t", header: "<signal.h>", final, pure.} = object
    abi: array[1024 div (8 * sizeof(culong)), culong]

  SigEvent* {.importc: "struct sigevent",
               header: "<signal.h>", final, pure.} = object ## struct sigevent
    sigev_value*: SigVal          ## Signal value.
    sigev_signo*: cint            ## Signal number.
    sigev_notify*: cint           ## Notification type.
    sigev_notify_function*: proc (x: SigVal) {.noconv.} ## Notification func.
    sigev_notify_attributes*: ptr PthreadAttr ## Notification attributes.
    abi: array[12, int]

  SigVal* {.importc: "union sigval",
             header: "<signal.h>", final, pure.} = object ## struct sigval
    sival_ptr*: pointer ## pointer signal value;
                        ## integer signal value not defined!
  Sigaction* {.importc: "struct sigaction",
                header: "<signal.h>", final, pure.} = object ## struct sigaction
    sa_handler*: proc (x: cint) {.noconv.}  ## Pointer to a signal-catching
                                            ## function or one of the macros
                                            ## SIG_IGN or SIG_DFL.
    sa_mask*: Sigset ## Set of signals to be blocked during execution of
                      ## the signal handling function.
    sa_flags*: cint   ## Special flags.
    sa_sigaction*: proc (x: cint, y: ptr SigInfo, z: pointer) {.noconv.}

  Stack* {.importc: "stack_t",
            header: "<signal.h>", final, pure.} = object ## stack_t
    ss_sp*: pointer  ## Stack base or pointer.
    ss_size*: int    ## Stack size.
    ss_flags*: cint  ## Flags.

  SigStack* {.importc: "struct sigstack",
               header: "<signal.h>", final, pure.} = object ## struct sigstack
    ss_onstack*: cint ## Non-zero when signal stack is in use.
    ss_sp*: pointer   ## Signal stack pointer.

  SigInfo* {.importc: "siginfo_t",
              header: "<signal.h>", final, pure.} = object ## siginfo_t
    si_signo*: cint    ## Signal number.
    si_code*: cint     ## Signal code.
    si_errno*: cint    ## If non-zero, an errno value associated with
                       ## this signal, as defined in <errno.h>.
    si_pid*: Pid       ## Sending process ID.
    si_uid*: Uid       ## Real user ID of sending process.
    si_addr*: pointer  ## Address of faulting instruction.
    si_status*: cint   ## Exit value or signal.
    si_band*: int      ## Band event for SIGPOLL.
    si_value*: SigVal  ## Signal value.
    pad {.importc: "_pad"}: array[128 - 56, uint8]

  Nl_item* {.importc: "nl_item", header: "<nl_types.h>".} = cint
  Nl_catd* {.importc: "nl_catd", header: "<nl_types.h>".} = pointer

  Sched_param* {.importc: "struct sched_param",
                  header: "<sched.h>",
                  final, pure.} = object ## struct sched_param
    sched_priority*: cint

  Timeval* {.importc: "struct timeval", header: "<sys/select.h>",
             final, pure.} = object ## struct timeval
    tv_sec*: clong       ## Seconds.
    tv_usec*: clong ## Microseconds.
  TFdSet* {.importc: "fd_set", header: "<sys/select.h>",
           final, pure.} = object
    abi: array[1024 div (8 * sizeof(clong)), clong]

  Mcontext* {.importc: "mcontext_t", header: "<ucontext.h>",
               final, pure.} = object
    gregs: array[23, clonglong]
    fpregs: pointer
    reserved1: array[8, clonglong]

  Ucontext* {.importc: "ucontext_t", header: "<ucontext.h>",
               final, pure.} = object ## ucontext_t
    uc_flags: clong
    uc_link*: ptr Ucontext  ## Pointer to the context that is resumed
                            ## when this context returns.
    uc_stack*: Stack        ## The stack used by this context.
    uc_mcontext*: Mcontext  ## A machine-specific representation of the saved
                            ## context.
    uc_sigmask*: Sigset     ## The set of signals that are blocked when this
                            ## context is active.
    # todo fpregds_mem

{.deprecated: [TOff: Off, TPid: Pid, TGid: Gid, TMode: Mode, TDev: Dev,
              TNlink: Nlink, TStack: Stack, TGroup: Group, TMqd: Mqd,
              TPasswd: Passwd, TClock: Clock, TClockId: ClockId, TKey: Key,
              TSem: Sem, Tpthread_attr: PthreadAttr, Ttimespec: Timespec,
              Tdirent: Dirent, TGlob: Glob,
              # Tflock: Flock, # Naming conflict if we drop the `T`
              Ticonv: Iconv, Tlconv: Lconv, TMqAttr: MqAttr, Tblkcnt: Blkcnt,
              Tblksize: Blksize, Tfsblkcnt: Fsblkcnt, Tfsfilcnt: Fsfilcnt,
              Tid: Id, Tino: Ino, Tpthread_barrier: Pthread_barrier,
              Tpthread_barrierattr: Pthread_barrierattr, Tpthread_cond: Pthread_cond,
              TPthread_condattr: Pthread_condattr, Tpthread_key: Pthread_key,
              Tpthread_mutex: Pthread_mutex, Tpthread_mutexattr: Pthread_mutexattr,
              Tpthread_once: Pthread_once, Tpthread_rwlock: Pthread_rwlock,
              Tpthread_rwlockattr: Pthread_rwlockattr, Tpthread_spinlock: Pthread_spinlock,
              Tpthread: Pthread, Tsuseconds: Suseconds, Ttimer: Timer,
              Tuid: Uid, Tuseconds: Useconds, Tutsname: Utsname, Tipc_perm: Ipc_perm,
              TStat: Stat, TStatvfs: Statvfs,
              Ttm: Tm, titimerspec: Itimerspec, Tsig_atomic: Sig_atomic, Tsigset: Sigset,
              TsigEvent: SigEvent, TsigVal: SigVal, TSigaction: Sigaction,
              TSigStack: SigStack, TsigInfo: SigInfo, Tnl_item: Nl_item,
              Tnl_catd: Nl_catd, Tsched_param: Sched_param,
              # TFdSet: FdSet, # Naming conflict if we drop the `T`
              Tmcontext: Mcontext, Tucontext: Ucontext].}
type
  Taiocb* {.importc: "struct aiocb", header: "<aio.h>",
            final, pure.} = object ## struct aiocb
    aio_fildes*: cint         ## File descriptor.
    aio_lio_opcode*: cint     ## Operation to be performed.
    aio_reqprio*: cint        ## Request priority offset.
    aio_buf*: pointer         ## Location of buffer.
    aio_nbytes*: csize        ## Length of transfer.
    aio_sigevent*: SigEvent   ## Signal number and value.
    next_prio: pointer
    abs_prio: cint
    policy: cint
    error_Code: cint
    return_value: clong
    aio_offset*: Off          ## File offset.
    reserved: array[32, uint8]


when hasSpawnH:
  type
    Tposix_spawnattr* {.importc: "posix_spawnattr_t",
                        header: "<spawn.h>", final, pure.} = object
      flags: cshort
      pgrp: Pid
      sd: Sigset
      ss: Sigset
      sp: Sched_param
      policy: cint
      pad: array[16, cint]

    Tposix_spawn_file_actions* {.importc: "posix_spawn_file_actions_t",
                                 header: "<spawn.h>", final, pure.} = object
      allocated: cint
      used: cint
      actions: pointer
      pad: array[16, cint]

# from sys/un.h
const Sockaddr_un_path_length* = 108

type
  Socklen* {.importc: "socklen_t", header: "<sys/socket.h>".} = cuint
  TSa_Family* {.importc: "sa_family_t", header: "<sys/socket.h>".} = cshort

  SockAddr* {.importc: "struct sockaddr", header: "<sys/socket.h>",
              pure, final.} = object ## struct sockaddr
    sa_family*: TSa_Family         ## Address family.
    sa_data*: array[14, char] ## Socket address (variable-length data).

  Sockaddr_un* {.importc: "struct sockaddr_un", header: "<sys/un.h>",
              pure, final.} = object ## struct sockaddr_un
    sun_family*: TSa_Family         ## Address family.
    sun_path*: array[108, char] ## Socket path

  Sockaddr_storage* {.importc: "struct sockaddr_storage",
                       header: "<sys/socket.h>",
                       pure, final.} = object ## struct sockaddr_storage
    ss_family*: TSa_Family ## Address family.
    ss_padding: array[128 - sizeof(cshort) - sizeof(culong), char]
    ss_align: clong

  Tif_nameindex* {.importc: "struct if_nameindex", final,
                   pure, header: "<net/if.h>".} = object ## struct if_nameindex
    if_index*: cuint   ## Numeric index of the interface.
    if_name*: cstring ## Null-terminated name of the interface.


  IOVec* {.importc: "struct iovec", pure, final,
            header: "<sys/uio.h>".} = object ## struct iovec
    iov_base*: pointer ## Base address of a memory region for input or output.
    iov_len*: csize    ## The size of the memory pointed to by iov_base.

  Tmsghdr* {.importc: "struct msghdr", pure, final,
             header: "<sys/socket.h>".} = object  ## struct msghdr
    msg_name*: pointer  ## Optional address.
    msg_namelen*: Socklen  ## Size of address.
    msg_iov*: ptr IOVec    ## Scatter/gather array.
    msg_iovlen*: csize   ## Members in msg_iov.
    msg_control*: pointer  ## Ancillary data; see below.
    msg_controllen*: csize ## Ancillary data buffer len.
    msg_flags*: cint ## Flags on received message.


  Tcmsghdr* {.importc: "struct cmsghdr", pure, final,
              header: "<sys/socket.h>".} = object ## struct cmsghdr
    cmsg_len*: csize ## Data byte count, including the cmsghdr.
    cmsg_level*: cint   ## Originating protocol.
    cmsg_type*: cint    ## Protocol-specific type.

  TLinger* {.importc: "struct linger", pure, final,
             header: "<sys/socket.h>".} = object ## struct linger
    l_onoff*: cint  ## Indicates whether linger option is enabled.
    l_linger*: cint ## Linger time, in seconds.
    # data follows...

  InPort* = uint16
  InAddrScalar* = uint32

  InAddrT* {.importc: "in_addr_t", pure, final,
             header: "<netinet/in.h>".} = uint32

  InAddr* {.importc: "struct in_addr", pure, final,
             header: "<netinet/in.h>".} = object ## struct in_addr
    s_addr*: InAddrScalar

  Sockaddr_in* {.importc: "struct sockaddr_in", pure, final,
                  header: "<netinet/in.h>".} = object ## struct sockaddr_in
    sin_family*: TSa_Family ## AF_INET.
    sin_port*: InPort      ## Port number.
    sin_addr*: InAddr      ## IP address.
    sin_zero: array[16 - 2 - 2 - 4, uint8]

  In6Addr* {.importc: "struct in6_addr", pure, final,
              header: "<netinet/in.h>".} = object ## struct in6_addr
    s6_addr*: array[0..15, char]

  Sockaddr_in6* {.importc: "struct sockaddr_in6", pure, final,
                   header: "<netinet/in.h>".} = object ## struct sockaddr_in6
    sin6_family*: TSa_Family ## AF_INET6.
    sin6_port*: InPort      ## Port number.
    sin6_flowinfo*: uint32    ## IPv6 traffic class and flow information.
    sin6_addr*: In6Addr     ## IPv6 address.
    sin6_scope_id*: uint32    ## Set of interfaces for a scope.

  Tipv6_mreq* {.importc: "struct ipv6_mreq", pure, final,
                header: "<netinet/in.h>".} = object ## struct ipv6_mreq
    ipv6mr_multiaddr*: In6Addr ## IPv6 multicast address.
    ipv6mr_interface*: cuint     ## Interface index.

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
    n_net*: uint32            ## The network number, in host byte order.

  Protoent* {.importc: "struct protoent", pure, final,
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

  Tnfds* {.importc: "nfds_t", header: "<poll.h>".} = culong

{.deprecated: [TSockaddr_in: Sockaddr_in, TAddrinfo: AddrInfo,
    TSockAddr: SockAddr, TSockLen: SockLen, TTimeval: Timeval,
    Tsockaddr_storage: Sockaddr_storage, Tsockaddr_in6: Sockaddr_in6,
    Thostent: Hostent, TServent: Servent,
    TInAddr: InAddr, TIOVec: IOVec, TInPort: InPort, TInAddrT: InAddrT,
    TIn6Addr: In6Addr, TInAddrScalar: InAddrScalar, TProtoent: Protoent].}

var
  errno* {.importc, header: "<errno.h>".}: cint ## error variable
  h_errno* {.importc, header: "<netdb.h>".}: cint
  daylight* {.importc, header: "<time.h>".}: cint
  timezone* {.importc, header: "<time.h>".}: clong

# Generated by detect.nim
const
  AIO_ALLDONE* = cint(2)
  AIO_CANCELED* = cint(0)
  AIO_NOTCANCELED* = cint(1)
  LIO_NOP* = cint(2)
  LIO_NOWAIT* = cint(1)
  LIO_READ* = cint(0)
  LIO_WAIT* = cint(0)
  LIO_WRITE* = cint(1)
  RTLD_LAZY* = cint(1)
  RTLD_NOW* = cint(2)
  RTLD_GLOBAL* = cint(256)
  RTLD_LOCAL* = cint(0)
  E2BIG* = cint(7)
  EACCES* = cint(13)
  EADDRINUSE* = cint(98)
  EADDRNOTAVAIL* = cint(99)
  EAFNOSUPPORT* = cint(97)
  EAGAIN* = cint(11)
  EALREADY* = cint(114)
  EBADF* = cint(9)
  EBADMSG* = cint(74)
  EBUSY* = cint(16)
  ECANCELED* = cint(125)
  ECHILD* = cint(10)
  ECONNABORTED* = cint(103)
  ECONNREFUSED* = cint(111)
  ECONNRESET* = cint(104)
  EDEADLK* = cint(35)
  EDESTADDRREQ* = cint(89)
  EDOM* = cint(33)
  EDQUOT* = cint(122)
  EEXIST* = cint(17)
  EFAULT* = cint(14)
  EFBIG* = cint(27)
  EHOSTUNREACH* = cint(113)
  EIDRM* = cint(43)
  EILSEQ* = cint(84)
  EINPROGRESS* = cint(115)
  EINTR* = cint(4)
  EINVAL* = cint(22)
  EIO* = cint(5)
  EISCONN* = cint(106)
  EISDIR* = cint(21)
  ELOOP* = cint(40)
  EMFILE* = cint(24)
  EMLINK* = cint(31)
  EMSGSIZE* = cint(90)
  EMULTIHOP* = cint(72)
  ENAMETOOLONG* = cint(36)
  ENETDOWN* = cint(100)
  ENETRESET* = cint(102)
  ENETUNREACH* = cint(101)
  ENFILE* = cint(23)
  ENOBUFS* = cint(105)
  ENODATA* = cint(61)
  ENODEV* = cint(19)
  ENOENT* = cint(2)
  ENOEXEC* = cint(8)
  ENOLCK* = cint(37)
  ENOLINK* = cint(67)
  ENOMEM* = cint(12)
  ENOMSG* = cint(42)
  ENOPROTOOPT* = cint(92)
  ENOSPC* = cint(28)
  ENOSR* = cint(63)
  ENOSTR* = cint(60)
  ENOSYS* = cint(38)
  ENOTCONN* = cint(107)
  ENOTDIR* = cint(20)
  ENOTEMPTY* = cint(39)
  ENOTSOCK* = cint(88)
  ENOTSUP* = cint(95)
  ENOTTY* = cint(25)
  ENXIO* = cint(6)
  EOPNOTSUPP* = cint(95)
  EOVERFLOW* = cint(75)
  EPERM* = cint(1)
  EPIPE* = cint(32)
  EPROTO* = cint(71)
  EPROTONOSUPPORT* = cint(93)
  EPROTOTYPE* = cint(91)
  ERANGE* = cint(34)
  EROFS* = cint(30)
  ESPIPE* = cint(29)
  ESRCH* = cint(3)
  ESTALE* = cint(116)
  ETIME* = cint(62)
  ETIMEDOUT* = cint(110)
  ETXTBSY* = cint(26)
  EWOULDBLOCK* = cint(11)
  EXDEV* = cint(18)
  F_DUPFD* = cint(0)
  F_GETFD* = cint(1)
  F_SETFD* = cint(2)
  F_GETFL* = cint(3)
  F_SETFL* = cint(4)
  F_GETLK* = cint(5)
  F_SETLK* = cint(6)
  F_SETLKW* = cint(7)
  F_GETOWN* = cint(9)
  F_SETOWN* = cint(8)
  FD_CLOEXEC* = cint(1)
  F_RDLCK* = cint(0)
  F_UNLCK* = cint(2)
  F_WRLCK* = cint(1)
  O_CREAT* = cint(64)
  O_EXCL* = cint(128)
  O_NOCTTY* = cint(256)
  O_TRUNC* = cint(512)
  O_APPEND* = cint(1024)
  O_DSYNC* = cint(4096)
  O_NONBLOCK* = cint(2048)
  O_RSYNC* = cint(1052672)
  O_SYNC* = cint(1052672)
  O_ACCMODE* = cint(3)
  O_RDONLY* = cint(0)
  O_RDWR* = cint(2)
  O_WRONLY* = cint(1)
  POSIX_FADV_NORMAL* = cint(0)
  POSIX_FADV_SEQUENTIAL* = cint(2)
  POSIX_FADV_RANDOM* = cint(1)
  POSIX_FADV_WILLNEED* = cint(3)
  POSIX_FADV_DONTNEED* = cint(4)
  POSIX_FADV_NOREUSE* = cint(5)
  MM_HARD* = cint(1)
  MM_SOFT* = cint(2)
  MM_FIRM* = cint(4)
  MM_APPL* = cint(8)
  MM_UTIL* = cint(16)
  MM_OPSYS* = cint(32)
  MM_RECOVER* = cint(64)
  MM_NRECOV* = cint(128)
  MM_HALT* = cint(1)
  MM_ERROR* = cint(2)
  MM_WARNING* = cint(3)
  MM_INFO* = cint(4)
  MM_NOSEV* = cint(0)
  MM_PRINT* = cint(256)
  MM_CONSOLE* = cint(512)
  MM_OK* = cint(0)
  MM_NOTOK* = cint(-1)
  MM_NOMSG* = cint(1)
  MM_NOCON* = cint(4)
  FNM_NOMATCH* = cint(1)
  FNM_PATHNAME* = cint(1)
  FNM_PERIOD* = cint(4)
  FNM_NOESCAPE* = cint(2)
  FTW_F* = cint(0)
  FTW_D* = cint(1)
  FTW_DNR* = cint(2)
  FTW_NS* = cint(3)
  FTW_SL* = cint(4)
  GLOB_APPEND* = cint(32)
  GLOB_DOOFFS* = cint(8)
  GLOB_ERR* = cint(1)
  GLOB_MARK* = cint(2)
  GLOB_NOCHECK* = cint(16)
  GLOB_NOESCAPE* = cint(64)
  GLOB_NOSORT* = cint(4)
  GLOB_ABORTED* = cint(2)
  GLOB_NOMATCH* = cint(3)
  GLOB_NOSPACE* = cint(1)
  GLOB_NOSYS* = cint(4)
  CODESET* = cint(14)
  D_T_FMT* = cint(131112)
  D_FMT* = cint(131113)
  T_FMT* = cint(131114)
  T_FMT_AMPM* = cint(131115)
  AM_STR* = cint(131110)
  PM_STR* = cint(131111)
  DAY_1* = cint(131079)
  DAY_2* = cint(131080)
  DAY_3* = cint(131081)
  DAY_4* = cint(131082)
  DAY_5* = cint(131083)
  DAY_6* = cint(131084)
  DAY_7* = cint(131085)
  ABDAY_1* = cint(131072)
  ABDAY_2* = cint(131073)
  ABDAY_3* = cint(131074)
  ABDAY_4* = cint(131075)
  ABDAY_5* = cint(131076)
  ABDAY_6* = cint(131077)
  ABDAY_7* = cint(131078)
  MON_1* = cint(131098)
  MON_2* = cint(131099)
  MON_3* = cint(131100)
  MON_4* = cint(131101)
  MON_5* = cint(131102)
  MON_6* = cint(131103)
  MON_7* = cint(131104)
  MON_8* = cint(131105)
  MON_9* = cint(131106)
  MON_10* = cint(131107)
  MON_11* = cint(131108)
  MON_12* = cint(131109)
  ABMON_1* = cint(131086)
  ABMON_2* = cint(131087)
  ABMON_3* = cint(131088)
  ABMON_4* = cint(131089)
  ABMON_5* = cint(131090)
  ABMON_6* = cint(131091)
  ABMON_7* = cint(131092)
  ABMON_8* = cint(131093)
  ABMON_9* = cint(131094)
  ABMON_10* = cint(131095)
  ABMON_11* = cint(131096)
  ABMON_12* = cint(131097)
  ERA* = cint(131116)
  ERA_D_FMT* = cint(131118)
  ERA_D_T_FMT* = cint(131120)
  ERA_T_FMT* = cint(131121)
  ALT_DIGITS* = cint(131119)
  RADIXCHAR* = cint(65536)
  THOUSEP* = cint(65537)
  YESEXPR* = cint(327680)
  NOEXPR* = cint(327681)
  CRNCYSTR* = cint(262159)
  LC_ALL* = cint(6)
  LC_COLLATE* = cint(3)
  LC_CTYPE* = cint(0)
  LC_MESSAGES* = cint(5)
  LC_MONETARY* = cint(4)
  LC_NUMERIC* = cint(1)
  LC_TIME* = cint(2)
  PTHREAD_BARRIER_SERIAL_THREAD* = cint(-1)
  PTHREAD_CANCEL_ASYNCHRONOUS* = cint(1)
  PTHREAD_CANCEL_ENABLE* = cint(0)
  PTHREAD_CANCEL_DEFERRED* = cint(0)
  PTHREAD_CANCEL_DISABLE* = cint(1)
  PTHREAD_CREATE_DETACHED* = cint(1)
  PTHREAD_CREATE_JOINABLE* = cint(0)
  PTHREAD_EXPLICIT_SCHED* = cint(1)
  PTHREAD_INHERIT_SCHED* = cint(0)
  PTHREAD_PROCESS_SHARED* = cint(1)
  PTHREAD_PROCESS_PRIVATE* = cint(0)
  PTHREAD_SCOPE_PROCESS* = cint(1)
  PTHREAD_SCOPE_SYSTEM* = cint(0)
  POSIX_ASYNC_IO* = cint(1)
  F_OK* = cint(0)
  R_OK* = cint(4)
  W_OK* = cint(2)
  X_OK* = cint(1)
  CS_PATH* = cint(0)
  CS_POSIX_V6_ILP32_OFF32_CFLAGS* = cint(1116)
  CS_POSIX_V6_ILP32_OFF32_LDFLAGS* = cint(1117)
  CS_POSIX_V6_ILP32_OFF32_LIBS* = cint(1118)
  CS_POSIX_V6_ILP32_OFFBIG_CFLAGS* = cint(1120)
  CS_POSIX_V6_ILP32_OFFBIG_LDFLAGS* = cint(1121)
  CS_POSIX_V6_ILP32_OFFBIG_LIBS* = cint(1122)
  CS_POSIX_V6_LP64_OFF64_CFLAGS* = cint(1124)
  CS_POSIX_V6_LP64_OFF64_LDFLAGS* = cint(1125)
  CS_POSIX_V6_LP64_OFF64_LIBS* = cint(1126)
  CS_POSIX_V6_LPBIG_OFFBIG_CFLAGS* = cint(1128)
  CS_POSIX_V6_LPBIG_OFFBIG_LDFLAGS* = cint(1129)
  CS_POSIX_V6_LPBIG_OFFBIG_LIBS* = cint(1130)
  CS_POSIX_V6_WIDTH_RESTRICTED_ENVS* = cint(1)
  F_LOCK* = cint(1)
  F_TEST* = cint(3)
  F_TLOCK* = cint(2)
  F_ULOCK* = cint(0)
  PC_2_SYMLINKS* = cint(20)
  PC_ALLOC_SIZE_MIN* = cint(18)
  PC_ASYNC_IO* = cint(10)
  PC_CHOWN_RESTRICTED* = cint(6)
  PC_FILESIZEBITS* = cint(13)
  PC_LINK_MAX* = cint(0)
  PC_MAX_CANON* = cint(1)
  PC_MAX_INPUT* = cint(2)
  PC_NAME_MAX* = cint(3)
  PC_NO_TRUNC* = cint(7)
  PC_PATH_MAX* = cint(4)
  PC_PIPE_BUF* = cint(5)
  PC_PRIO_IO* = cint(11)
  PC_REC_INCR_XFER_SIZE* = cint(14)
  PC_REC_MIN_XFER_SIZE* = cint(16)
  PC_REC_XFER_ALIGN* = cint(17)
  PC_SYMLINK_MAX* = cint(19)
  PC_SYNC_IO* = cint(9)
  PC_VDISABLE* = cint(8)
  SC_2_C_BIND* = cint(47)
  SC_2_C_DEV* = cint(48)
  SC_2_CHAR_TERM* = cint(95)
  SC_2_FORT_DEV* = cint(49)
  SC_2_FORT_RUN* = cint(50)
  SC_2_LOCALEDEF* = cint(52)
  SC_2_PBS* = cint(168)
  SC_2_PBS_ACCOUNTING* = cint(169)
  SC_2_PBS_CHECKPOINT* = cint(175)
  SC_2_PBS_LOCATE* = cint(170)
  SC_2_PBS_MESSAGE* = cint(171)
  SC_2_PBS_TRACK* = cint(172)
  SC_2_SW_DEV* = cint(51)
  SC_2_UPE* = cint(97)
  SC_2_VERSION* = cint(46)
  SC_ADVISORY_INFO* = cint(132)
  SC_AIO_LISTIO_MAX* = cint(23)
  SC_AIO_MAX* = cint(24)
  SC_AIO_PRIO_DELTA_MAX* = cint(25)
  SC_ARG_MAX* = cint(0)
  SC_ASYNCHRONOUS_IO* = cint(12)
  SC_ATEXIT_MAX* = cint(87)
  SC_BARRIERS* = cint(133)
  SC_BC_BASE_MAX* = cint(36)
  SC_BC_DIM_MAX* = cint(37)
  SC_BC_SCALE_MAX* = cint(38)
  SC_BC_STRING_MAX* = cint(39)
  SC_CHILD_MAX* = cint(1)
  SC_CLK_TCK* = cint(2)
  SC_CLOCK_SELECTION* = cint(137)
  SC_COLL_WEIGHTS_MAX* = cint(40)
  SC_CPUTIME* = cint(138)
  SC_DELAYTIMER_MAX* = cint(26)
  SC_EXPR_NEST_MAX* = cint(42)
  SC_FSYNC* = cint(15)
  SC_GETGR_R_SIZE_MAX* = cint(69)
  SC_GETPW_R_SIZE_MAX* = cint(70)
  SC_HOST_NAME_MAX* = cint(180)
  SC_IOV_MAX* = cint(60)
  SC_IPV6* = cint(235)
  SC_JOB_CONTROL* = cint(7)
  SC_LINE_MAX* = cint(43)
  SC_LOGIN_NAME_MAX* = cint(71)
  SC_MAPPED_FILES* = cint(16)
  SC_MEMLOCK* = cint(17)
  SC_MEMLOCK_RANGE* = cint(18)
  SC_MEMORY_PROTECTION* = cint(19)
  SC_MESSAGE_PASSING* = cint(20)
  SC_MONOTONIC_CLOCK* = cint(149)
  SC_MQ_OPEN_MAX* = cint(27)
  SC_MQ_PRIO_MAX* = cint(28)
  SC_NGROUPS_MAX* = cint(3)
  SC_OPEN_MAX* = cint(4)
  SC_PAGE_SIZE* = cint(30)
  SC_PRIORITIZED_IO* = cint(13)
  SC_PRIORITY_SCHEDULING* = cint(10)
  SC_RAW_SOCKETS* = cint(236)
  SC_RE_DUP_MAX* = cint(44)
  SC_READER_WRITER_LOCKS* = cint(153)
  SC_REALTIME_SIGNALS* = cint(9)
  SC_REGEXP* = cint(155)
  SC_RTSIG_MAX* = cint(31)
  SC_SAVED_IDS* = cint(8)
  SC_SEM_NSEMS_MAX* = cint(32)
  SC_SEM_VALUE_MAX* = cint(33)
  SC_SEMAPHORES* = cint(21)
  SC_SHARED_MEMORY_OBJECTS* = cint(22)
  SC_SHELL* = cint(157)
  SC_SIGQUEUE_MAX* = cint(34)
  SC_SPAWN* = cint(159)
  SC_SPIN_LOCKS* = cint(154)
  SC_SPORADIC_SERVER* = cint(160)
  SC_SS_REPL_MAX* = cint(241)
  SC_STREAM_MAX* = cint(5)
  SC_SYMLOOP_MAX* = cint(173)
  SC_SYNCHRONIZED_IO* = cint(14)
  SC_THREAD_ATTR_STACKADDR* = cint(77)
  SC_THREAD_ATTR_STACKSIZE* = cint(78)
  SC_THREAD_CPUTIME* = cint(139)
  SC_THREAD_DESTRUCTOR_ITERATIONS* = cint(73)
  SC_THREAD_KEYS_MAX* = cint(74)
  SC_THREAD_PRIO_INHERIT* = cint(80)
  SC_THREAD_PRIO_PROTECT* = cint(81)
  SC_THREAD_PRIORITY_SCHEDULING* = cint(79)
  SC_THREAD_PROCESS_SHARED* = cint(82)
  SC_THREAD_SAFE_FUNCTIONS* = cint(68)
  SC_THREAD_SPORADIC_SERVER* = cint(161)
  SC_THREAD_STACK_MIN* = cint(75)
  SC_THREAD_THREADS_MAX* = cint(76)
  SC_THREADS* = cint(67)
  SC_TIMEOUTS* = cint(164)
  SC_TIMER_MAX* = cint(35)
  SC_TIMERS* = cint(11)
  SC_TRACE* = cint(181)
  SC_TRACE_EVENT_FILTER* = cint(182)
  SC_TRACE_EVENT_NAME_MAX* = cint(242)
  SC_TRACE_INHERIT* = cint(183)
  SC_TRACE_LOG* = cint(184)
  SC_TRACE_NAME_MAX* = cint(243)
  SC_TRACE_SYS_MAX* = cint(244)
  SC_TRACE_USER_EVENT_MAX* = cint(245)
  SC_TTY_NAME_MAX* = cint(72)
  SC_TYPED_MEMORY_OBJECTS* = cint(165)
  SC_TZNAME_MAX* = cint(6)
  SC_V6_ILP32_OFF32* = cint(176)
  SC_V6_ILP32_OFFBIG* = cint(177)
  SC_V6_LP64_OFF64* = cint(178)
  SC_V6_LPBIG_OFFBIG* = cint(179)
  SC_VERSION* = cint(29)
  SC_XBS5_ILP32_OFF32* = cint(125)
  SC_XBS5_ILP32_OFFBIG* = cint(126)
  SC_XBS5_LP64_OFF64* = cint(127)
  SC_XBS5_LPBIG_OFFBIG* = cint(128)
  SC_XOPEN_CRYPT* = cint(92)
  SC_XOPEN_ENH_I18N* = cint(93)
  SC_XOPEN_LEGACY* = cint(129)
  SC_XOPEN_REALTIME* = cint(130)
  SC_XOPEN_REALTIME_THREADS* = cint(131)
  SC_XOPEN_SHM* = cint(94)
  SC_XOPEN_STREAMS* = cint(246)
  SC_XOPEN_UNIX* = cint(91)
  SC_XOPEN_VERSION* = cint(89)
  SC_NPROCESSORS_ONLN* = cint(84)
  SEM_FAILED* = cast[pointer]((nil))
  IPC_CREAT* = cint(512)
  IPC_EXCL* = cint(1024)
  IPC_NOWAIT* = cint(2048)
  IPC_PRIVATE* = cint(0)
  IPC_RMID* = cint(0)
  IPC_SET* = cint(1)
  IPC_STAT* = cint(2)
  S_IFBLK* = cint(24576)
  S_IFCHR* = cint(8192)
  S_IFDIR* = cint(16384)
  S_IFIFO* = cint(4096)
  S_IFLNK* = cint(40960)
  S_IFMT* = cint(61440)
  S_IFREG* = cint(32768)
  S_IFSOCK* = cint(49152)
  S_IRGRP* = cint(32)
  S_IROTH* = cint(4)
  S_IRUSR* = cint(256)
  S_IRWXG* = cint(56)
  S_IRWXO* = cint(7)
  S_IRWXU* = cint(448)
  S_ISGID* = cint(1024)
  S_ISUID* = cint(2048)
  S_ISVTX* = cint(512)
  S_IWGRP* = cint(16)
  S_IWOTH* = cint(2)
  S_IWUSR* = cint(128)
  S_IXGRP* = cint(8)
  S_IXOTH* = cint(1)
  S_IXUSR* = cint(64)
  ST_RDONLY* = cint(1)
  ST_NOSUID* = cint(2)
  PROT_READ* = cint(1)
  PROT_WRITE* = cint(2)
  PROT_EXEC* = cint(4)
  PROT_NONE* = cint(0)
  MAP_SHARED* = cint(1)
  MAP_PRIVATE* = cint(2)
  MAP_FIXED* = cint(16)
  MS_ASYNC* = cint(1)
  MS_SYNC* = cint(4)
  MS_INVALIDATE* = cint(2)
  MCL_CURRENT* = cint(1)
  MCL_FUTURE* = cint(2)
  MAP_FAILED* = cast[pointer](0xffffffffffffffff)
  POSIX_MADV_NORMAL* = cint(0)
  POSIX_MADV_SEQUENTIAL* = cint(2)
  POSIX_MADV_RANDOM* = cint(1)
  POSIX_MADV_WILLNEED* = cint(3)
  POSIX_MADV_DONTNEED* = cint(4)
  CLOCKS_PER_SEC* = clong(1000000)
  CLOCK_PROCESS_CPUTIME_ID* = cint(2)
  CLOCK_THREAD_CPUTIME_ID* = cint(3)
  CLOCK_REALTIME* = cint(0)
  TIMER_ABSTIME* = cint(1)
  CLOCK_MONOTONIC* = cint(1)
  WNOHANG* = cint(1)
  WUNTRACED* = cint(2)
  WEXITED* = cint(4)
  WSTOPPED* = cint(2)
  WCONTINUED* = cint(8)
  WNOWAIT* = cint(16777216)
  SIGEV_NONE* = cint(1)
  SIGEV_SIGNAL* = cint(0)
  SIGEV_THREAD* = cint(2)
  SIGABRT* = cint(6)
  SIGALRM* = cint(14)
  SIGBUS* = cint(7)
  SIGCHLD* = cint(17)
  SIGCONT* = cint(18)
  SIGFPE* = cint(8)
  SIGHUP* = cint(1)
  SIGILL* = cint(4)
  SIGINT* = cint(2)
  SIGKILL* = cint(9)
  SIGPIPE* = cint(13)
  SIGQUIT* = cint(3)
  SIGSEGV* = cint(11)
  SIGSTOP* = cint(19)
  SIGTERM* = cint(15)
  SIGTSTP* = cint(20)
  SIGTTIN* = cint(21)
  SIGTTOU* = cint(22)
  SIGUSR1* = cint(10)
  SIGUSR2* = cint(12)
  SIGPOLL* = cint(29)
  SIGPROF* = cint(27)
  SIGSYS* = cint(31)
  SIGTRAP* = cint(5)
  SIGURG* = cint(23)
  SIGVTALRM* = cint(26)
  SIGXCPU* = cint(24)
  SIGXFSZ* = cint(25)
  SA_NOCLDSTOP* = cint(1)
  SIG_BLOCK* = cint(0)
  SIG_UNBLOCK* = cint(1)
  SIG_SETMASK* = cint(2)
  SA_ONSTACK* = cint(134217728)
  SA_RESETHAND* = cint(-2147483648)
  SA_RESTART* = cint(268435456)
  SA_SIGINFO* = cint(4)
  SA_NOCLDWAIT* = cint(2)
  SA_NODEFER* = cint(1073741824)
  SS_ONSTACK* = cint(1)
  SS_DISABLE* = cint(2)
  MINSIGSTKSZ* = cint(2048)
  SIGSTKSZ* = cint(8192)
  NL_SETD* = cint(1)
  NL_CAT_LOCALE* = cint(1)
  SCHED_FIFO* = cint(1)
  SCHED_RR* = cint(2)
  SCHED_OTHER* = cint(0)
  FD_SETSIZE* = cint(1024)
  SEEK_SET* = cint(0)
  SEEK_CUR* = cint(1)
  SEEK_END* = cint(2)
  MSG_CTRUNC* = cint(8)
  MSG_DONTROUTE* = cint(4)
  MSG_EOR* = cint(128)
  MSG_OOB* = cint(1)
  SCM_RIGHTS* = cint(1)
  SO_ACCEPTCONN* = cint(30)
  SO_BROADCAST* = cint(6)
  SO_DEBUG* = cint(1)
  SO_DONTROUTE* = cint(5)
  SO_ERROR* = cint(4)
  SO_KEEPALIVE* = cint(9)
  SO_LINGER* = cint(13)
  SO_OOBINLINE* = cint(10)
  SO_RCVBUF* = cint(8)
  SO_RCVLOWAT* = cint(18)
  SO_RCVTIMEO* = cint(20)
  SO_REUSEADDR* = cint(2)
  SO_SNDBUF* = cint(7)
  SO_SNDLOWAT* = cint(19)
  SO_SNDTIMEO* = cint(21)
  SO_TYPE* = cint(3)
  SOCK_DGRAM* = cint(2)
  SOCK_RAW* = cint(3)
  SOCK_SEQPACKET* = cint(5)
  SOCK_STREAM* = cint(1)
  SOL_SOCKET* = cint(1)
  SOMAXCONN* = cint(128)
  MAP_POPULATE* = cint(32768)
  SO_REUSEPORT* = cint(15)
  MSG_NOSIGNAL* = cint(16384)
  MSG_PEEK* = cint(2)
  MSG_TRUNC* = cint(32)
  MSG_WAITALL* = cint(256)
  AF_INET* = TSa_Family(2)
  AF_INET6* = TSa_Family(10)
  AF_UNIX* = TSa_Family(1)
  AF_UNSPEC* = TSa_Family(0)
  SHUT_RD* = cint(0)
  SHUT_RDWR* = cint(2)
  SHUT_WR* = cint(1)
  IF_NAMESIZE* = cint(16)
  IPPROTO_IP* = cint(0)
  IPPROTO_IPV6* = cint(41)
  IPPROTO_ICMP* = cint(1)
  IPPROTO_RAW* = cint(255)
  IPPROTO_TCP* = cint(6)
  IPPROTO_UDP* = cint(17)
  INADDR_ANY* = InAddrScalar(0)
  INADDR_LOOPBACK* = InAddrScalar(2130706433)
  INADDR_BROADCAST* = InAddrScalar(-1)
  INET_ADDRSTRLEN* = cint(16)
  INET6_ADDRSTRLEN* = cint(46)
  IPV6_JOIN_GROUP* = cint(20)
  IPV6_LEAVE_GROUP* = cint(21)
  IPV6_MULTICAST_HOPS* = cint(18)
  IPV6_MULTICAST_IF* = cint(17)
  IPV6_MULTICAST_LOOP* = cint(19)
  IPV6_UNICAST_HOPS* = cint(16)
  IPV6_V6ONLY* = cint(26)
  TCP_NODELAY* = cint(1)
  IPPORT_RESERVED* = cint(1024)
  HOST_NOT_FOUND* = cint(1)
  NO_DATA* = cint(4)
  NO_RECOVERY* = cint(3)
  TRY_AGAIN* = cint(2)
  AI_PASSIVE* = cint(1)
  AI_CANONNAME* = cint(2)
  AI_NUMERICHOST* = cint(4)
  AI_NUMERICSERV* = cint(1024)
  AI_V4MAPPED* = cint(8)
  AI_ALL* = cint(16)
  AI_ADDRCONFIG* = cint(32)
  NI_NOFQDN* = cint(4)
  NI_NUMERICHOST* = cint(1)
  NI_NAMEREQD* = cint(8)
  NI_NUMERICSERV* = cint(2)
  NI_DGRAM* = cint(16)
  EAI_AGAIN* = cint(-3)
  EAI_BADFLAGS* = cint(-1)
  EAI_FAIL* = cint(-4)
  EAI_FAMILY* = cint(-6)
  EAI_MEMORY* = cint(-10)
  EAI_NONAME* = cint(-2)
  EAI_SERVICE* = cint(-8)
  EAI_SOCKTYPE* = cint(-7)
  EAI_SYSTEM* = cint(-11)
  EAI_OVERFLOW* = cint(-12)
  POLLIN* = cshort(1)
  POLLRDNORM* = cshort(64)
  POLLRDBAND* = cshort(128)
  POLLPRI* = cshort(2)
  POLLOUT* = cshort(4)
  POLLWRNORM* = cshort(256)
  POLLWRBAND* = cshort(512)
  POLLERR* = cshort(8)
  POLLHUP* = cshort(16)
  POLLNVAL* = cshort(32)
  POSIX_SPAWN_RESETIDS* = cint(1)
  POSIX_SPAWN_SETPGROUP* = cint(2)
  POSIX_SPAWN_SETSCHEDPARAM* = cint(16)
  POSIX_SPAWN_SETSCHEDULER* = cint(32)
  POSIX_SPAWN_SETSIGDEF* = cint(4)
  POSIX_SPAWN_SETSIGMASK* = cint(8)
  IOFBF* = cint(0)
  IONBF* = cint(2)

when not defined(macosx):
  proc st_atime*(s: Stat): Time {.inline.} =
    ## Second-granularity time of last access
    result = s.st_atim.tv_sec
  proc st_mtime*(s: Stat): Time {.inline.} =
    ## Second-granularity time of last data modification.
    result = s.st_mtim.tv_sec
  proc st_ctime*(s: Stat): Time {.inline.} =
    ## Second-granularity time of last status change.
    result = s.st_ctim.tv_sec

proc WIFCONTINUED*(s:cint) : bool {.importc, header: "<sys/wait.h>".}
  ## True if child has been continued.
proc WIFEXITED*(s:cint) : bool {.importc, header: "<sys/wait.h>".}
  ## True if child exited normally.
proc WIFSIGNALED*(s:cint) : bool {.importc, header: "<sys/wait.h>".}
  ## True if child exited due to uncaught signal.
proc WIFSTOPPED*(s:cint) : bool {.importc, header: "<sys/wait.h>".}
  ## True if child is currently stopped.

const POSIX_SPAWN_USEVFORK* = cint(0x40)

proc aio_cancel*(a1: cint, a2: ptr Taiocb): cint {.importc, header: "<aio.h>".}
proc aio_error*(a1: ptr Taiocb): cint {.importc, header: "<aio.h>".}
proc aio_fsync*(a1: cint, a2: ptr Taiocb): cint {.importc, header: "<aio.h>".}
proc aio_read*(a1: ptr Taiocb): cint {.importc, header: "<aio.h>".}
proc aio_return*(a1: ptr Taiocb): int {.importc, header: "<aio.h>".}
proc aio_suspend*(a1: ptr ptr Taiocb, a2: cint, a3: ptr Timespec): cint {.
                 importc, header: "<aio.h>".}
proc aio_write*(a1: ptr Taiocb): cint {.importc, header: "<aio.h>".}
proc lio_listio*(a1: cint, a2: ptr ptr Taiocb, a3: cint,
             a4: ptr SigEvent): cint {.importc, header: "<aio.h>".}

# arpa/inet.h
proc htonl*(a1: uint32): uint32 {.importc, header: "<arpa/inet.h>".}
proc htons*(a1: uint16): uint16 {.importc, header: "<arpa/inet.h>".}
proc ntohl*(a1: uint32): uint32 {.importc, header: "<arpa/inet.h>".}
proc ntohs*(a1: uint16): uint16 {.importc, header: "<arpa/inet.h>".}

proc inet_addr*(a1: cstring): InAddrT {.importc, header: "<arpa/inet.h>".}
proc inet_ntoa*(a1: InAddr): cstring {.importc, header: "<arpa/inet.h>".}
proc inet_ntop*(a1: cint, a2: pointer, a3: cstring, a4: int32): cstring {.
  importc:"(char *)$1", header: "<arpa/inet.h>".}
proc inet_pton*(a1: cint, a2: cstring, a3: pointer): cint {.
  importc, header: "<arpa/inet.h>".}

var
  in6addr_any* {.importc, header: "<netinet/in.h>".}: In6Addr
  in6addr_loopback* {.importc, header: "<netinet/in.h>".}: In6Addr

proc IN6ADDR_ANY_INIT* (): In6Addr {.importc, header: "<netinet/in.h>".}
proc IN6ADDR_LOOPBACK_INIT* (): In6Addr {.importc, header: "<netinet/in.h>".}

# dirent.h
proc closedir*(a1: ptr DIR): cint  {.importc, header: "<dirent.h>".}
proc opendir*(a1: cstring): ptr DIR {.importc, header: "<dirent.h>".}
proc readdir*(a1: ptr DIR): ptr Dirent  {.importc, header: "<dirent.h>".}
proc readdir_r*(a1: ptr DIR, a2: ptr Dirent, a3: ptr ptr Dirent): cint  {.
                importc, header: "<dirent.h>".}
proc rewinddir*(a1: ptr DIR)  {.importc, header: "<dirent.h>".}
proc seekdir*(a1: ptr DIR, a2: int)  {.importc, header: "<dirent.h>".}
proc telldir*(a1: ptr DIR): int {.importc, header: "<dirent.h>".}

# dlfcn.h
proc dlclose*(a1: pointer): cint {.importc, header: "<dlfcn.h>".}
proc dlerror*(): cstring {.importc, header: "<dlfcn.h>".}
proc dlopen*(a1: cstring, a2: cint): pointer {.importc, header: "<dlfcn.h>".}
proc dlsym*(a1: pointer, a2: cstring): pointer {.importc, header: "<dlfcn.h>".}

proc creat*(a1: cstring, a2: Mode): cint {.importc, header: "<fcntl.h>".}
proc fcntl*(a1: cint | SocketHandle, a2: cint): cint {.varargs, importc, header: "<fcntl.h>".}
proc open*(a1: cstring, a2: cint): cint {.varargs, importc, header: "<fcntl.h>".}
proc posix_fadvise*(a1: cint, a2, a3: Off, a4: cint): cint {.
  importc, header: "<fcntl.h>".}
proc posix_fallocate*(a1: cint, a2, a3: Off): cint {.
  importc, header: "<fcntl.h>".}

when not defined(haiku) and not defined(OpenBSD):
  proc fmtmsg*(a1: int, a2: cstring, a3: cint,
              a4, a5, a6: cstring): cint {.importc, header: "<fmtmsg.h>".}

proc fnmatch*(a1, a2: cstring, a3: cint): cint {.importc, header: "<fnmatch.h>".}
proc ftw*(a1: cstring,
         a2: proc (x1: cstring, x2: ptr Stat, x3: cint): cint {.noconv.},
         a3: cint): cint {.importc, header: "<ftw.h>".}
when not (defined(linux) and defined(amd64)):
  proc nftw*(a1: cstring,
            a2: proc (x1: cstring, x2: ptr Stat,
                      x3: cint, x4: ptr FTW): cint {.noconv.},
            a3: cint,
            a4: cint): cint {.importc, header: "<ftw.h>".}

proc glob*(a1: cstring, a2: cint,
          a3: proc (x1: cstring, x2: cint): cint {.noconv.},
          a4: ptr Glob): cint {.importc, header: "<glob.h>".}
proc globfree*(a1: ptr Glob) {.importc, header: "<glob.h>".}

proc getgrgid*(a1: Gid): ptr Group {.importc, header: "<grp.h>".}
proc getgrnam*(a1: cstring): ptr Group {.importc, header: "<grp.h>".}
proc getgrgid_r*(a1: Gid, a2: ptr Group, a3: cstring, a4: int,
                 a5: ptr ptr Group): cint {.importc, header: "<grp.h>".}
proc getgrnam_r*(a1: cstring, a2: ptr Group, a3: cstring,
                  a4: int, a5: ptr ptr Group): cint {.
                 importc, header: "<grp.h>".}
proc getgrent*(): ptr Group {.importc, header: "<grp.h>".}
proc endgrent*() {.importc, header: "<grp.h>".}
proc setgrent*() {.importc, header: "<grp.h>".}


proc iconv_open*(a1, a2: cstring): Iconv {.importc, header: "<iconv.h>".}
proc iconv*(a1: Iconv, a2: var cstring, a3: var int, a4: var cstring,
            a5: var int): int {.importc, header: "<iconv.h>".}
proc iconv_close*(a1: Iconv): cint {.importc, header: "<iconv.h>".}

proc nl_langinfo*(a1: Nl_item): cstring {.importc, header: "<langinfo.h>".}

proc basename*(a1: cstring): cstring {.importc, header: "<libgen.h>".}
proc dirname*(a1: cstring): cstring {.importc, header: "<libgen.h>".}

proc localeconv*(): ptr Lconv {.importc, header: "<locale.h>".}
proc setlocale*(a1: cint, a2: cstring): cstring {.
                importc, header: "<locale.h>".}

proc strfmon*(a1: cstring, a2: int, a3: cstring): int {.varargs,
   importc, header: "<monetary.h>".}

proc mq_close*(a1: Mqd): cint {.importc, header: "<mqueue.h>".}
proc mq_getattr*(a1: Mqd, a2: ptr MqAttr): cint {.
  importc, header: "<mqueue.h>".}
proc mq_notify*(a1: Mqd, a2: ptr SigEvent): cint {.
  importc, header: "<mqueue.h>".}
proc mq_open*(a1: cstring, a2: cint): Mqd {.
  varargs, importc, header: "<mqueue.h>".}
proc mq_receive*(a1: Mqd, a2: cstring, a3: int, a4: var int): int {.
  importc, header: "<mqueue.h>".}
proc mq_send*(a1: Mqd, a2: cstring, a3: int, a4: int): cint {.
  importc, header: "<mqueue.h>".}
proc mq_setattr*(a1: Mqd, a2, a3: ptr MqAttr): cint {.
  importc, header: "<mqueue.h>".}

proc mq_timedreceive*(a1: Mqd, a2: cstring, a3: int, a4: int,
                      a5: ptr Timespec): int {.importc, header: "<mqueue.h>".}
proc mq_timedsend*(a1: Mqd, a2: cstring, a3: int, a4: int,
                   a5: ptr Timespec): cint {.importc, header: "<mqueue.h>".}
proc mq_unlink*(a1: cstring): cint {.importc, header: "<mqueue.h>".}


proc getpwnam*(a1: cstring): ptr Passwd {.importc, header: "<pwd.h>".}
proc getpwuid*(a1: Uid): ptr Passwd {.importc, header: "<pwd.h>".}
proc getpwnam_r*(a1: cstring, a2: ptr Passwd, a3: cstring, a4: int,
                 a5: ptr ptr Passwd): cint {.importc, header: "<pwd.h>".}
proc getpwuid_r*(a1: Uid, a2: ptr Passwd, a3: cstring,
      a4: int, a5: ptr ptr Passwd): cint {.importc, header: "<pwd.h>".}
proc endpwent*() {.importc, header: "<pwd.h>".}
proc getpwent*(): ptr Passwd {.importc, header: "<pwd.h>".}
proc setpwent*() {.importc, header: "<pwd.h>".}

proc uname*(a1: var Utsname): cint {.importc, header: "<sys/utsname.h>".}

proc pthread_atfork*(a1, a2, a3: proc () {.noconv.}): cint {.
  importc, header: "<pthread.h>".}
proc pthread_attr_destroy*(a1: ptr PthreadAttr): cint {.
  importc, header: "<pthread.h>".}
proc pthread_attr_getdetachstate*(a1: ptr PthreadAttr, a2: cint): cint {.
  importc, header: "<pthread.h>".}
proc pthread_attr_getguardsize*(a1: ptr PthreadAttr, a2: var cint): cint {.
  importc, header: "<pthread.h>".}
proc pthread_attr_getinheritsched*(a1: ptr PthreadAttr,
          a2: var cint): cint {.importc, header: "<pthread.h>".}
proc pthread_attr_getschedparam*(a1: ptr PthreadAttr,
          a2: ptr Sched_param): cint {.importc, header: "<pthread.h>".}
proc pthread_attr_getschedpolicy*(a1: ptr PthreadAttr,
          a2: var cint): cint {.importc, header: "<pthread.h>".}
proc pthread_attr_getscope*(a1: ptr PthreadAttr,
          a2: var cint): cint {.importc, header: "<pthread.h>".}
proc pthread_attr_getstack*(a1: ptr PthreadAttr,
         a2: var pointer, a3: var int): cint {.importc, header: "<pthread.h>".}
proc pthread_attr_getstackaddr*(a1: ptr PthreadAttr,
          a2: var pointer): cint {.importc, header: "<pthread.h>".}
proc pthread_attr_getstacksize*(a1: ptr PthreadAttr,
          a2: var int): cint {.importc, header: "<pthread.h>".}
proc pthread_attr_init*(a1: ptr PthreadAttr): cint {.
  importc, header: "<pthread.h>".}
proc pthread_attr_setdetachstate*(a1: ptr PthreadAttr, a2: cint): cint {.
  importc, header: "<pthread.h>".}
proc pthread_attr_setguardsize*(a1: ptr PthreadAttr, a2: int): cint {.
  importc, header: "<pthread.h>".}
proc pthread_attr_setinheritsched*(a1: ptr PthreadAttr, a2: cint): cint {.
  importc, header: "<pthread.h>".}
proc pthread_attr_setschedparam*(a1: ptr PthreadAttr,
          a2: ptr Sched_param): cint {.importc, header: "<pthread.h>".}
proc pthread_attr_setschedpolicy*(a1: ptr PthreadAttr, a2: cint): cint {.
  importc, header: "<pthread.h>".}
proc pthread_attr_setscope*(a1: ptr PthreadAttr, a2: cint): cint {.importc,
  header: "<pthread.h>".}
proc pthread_attr_setstack*(a1: ptr PthreadAttr, a2: pointer, a3: int): cint {.
  importc, header: "<pthread.h>".}
proc pthread_attr_setstackaddr*(a1: ptr PthreadAttr, a2: pointer): cint {.
  importc, header: "<pthread.h>".}
proc pthread_attr_setstacksize*(a1: ptr PthreadAttr, a2: int): cint {.
  importc, header: "<pthread.h>".}
proc pthread_barrier_destroy*(a1: ptr Pthread_barrier): cint {.
  importc, header: "<pthread.h>".}
proc pthread_barrier_init*(a1: ptr Pthread_barrier,
         a2: ptr Pthread_barrierattr, a3: cint): cint {.
         importc, header: "<pthread.h>".}
proc pthread_barrier_wait*(a1: ptr Pthread_barrier): cint {.
  importc, header: "<pthread.h>".}
proc pthread_barrierattr_destroy*(a1: ptr Pthread_barrierattr): cint {.
  importc, header: "<pthread.h>".}
proc pthread_barrierattr_getpshared*(
          a1: ptr Pthread_barrierattr, a2: var cint): cint {.
          importc, header: "<pthread.h>".}
proc pthread_barrierattr_init*(a1: ptr Pthread_barrierattr): cint {.
  importc, header: "<pthread.h>".}
proc pthread_barrierattr_setpshared*(a1: ptr Pthread_barrierattr,
  a2: cint): cint {.importc, header: "<pthread.h>".}
proc pthread_cancel*(a1: Pthread): cint {.importc, header: "<pthread.h>".}
proc pthread_cleanup_push*(a1: proc (x: pointer) {.noconv.}, a2: pointer) {.
  importc, header: "<pthread.h>".}
proc pthread_cleanup_pop*(a1: cint) {.importc, header: "<pthread.h>".}
proc pthread_cond_broadcast*(a1: ptr Pthread_cond): cint {.
  importc, header: "<pthread.h>".}
proc pthread_cond_destroy*(a1: ptr Pthread_cond): cint {.importc, header: "<pthread.h>".}
proc pthread_cond_init*(a1: ptr Pthread_cond,
          a2: ptr Pthread_condattr): cint {.importc, header: "<pthread.h>".}
proc pthread_cond_signal*(a1: ptr Pthread_cond): cint {.importc, header: "<pthread.h>".}
proc pthread_cond_timedwait*(a1: ptr Pthread_cond,
          a2: ptr Pthread_mutex, a3: ptr Timespec): cint {.importc, header: "<pthread.h>".}

proc pthread_cond_wait*(a1: ptr Pthread_cond,
          a2: ptr Pthread_mutex): cint {.importc, header: "<pthread.h>".}
proc pthread_condattr_destroy*(a1: ptr Pthread_condattr): cint {.importc, header: "<pthread.h>".}
proc pthread_condattr_getclock*(a1: ptr Pthread_condattr,
          a2: var ClockId): cint {.importc, header: "<pthread.h>".}
proc pthread_condattr_getpshared*(a1: ptr Pthread_condattr,
          a2: var cint): cint {.importc, header: "<pthread.h>".}

proc pthread_condattr_init*(a1: ptr Pthread_condattr): cint {.importc, header: "<pthread.h>".}
proc pthread_condattr_setclock*(a1: ptr Pthread_condattr,a2: ClockId): cint {.importc, header: "<pthread.h>".}
proc pthread_condattr_setpshared*(a1: ptr Pthread_condattr, a2: cint): cint {.importc, header: "<pthread.h>".}

proc pthread_create*(a1: ptr Pthread, a2: ptr PthreadAttr,
          a3: proc (x: pointer): pointer {.noconv.}, a4: pointer): cint {.importc, header: "<pthread.h>".}
proc pthread_detach*(a1: Pthread): cint {.importc, header: "<pthread.h>".}
proc pthread_equal*(a1, a2: Pthread): cint {.importc, header: "<pthread.h>".}
proc pthread_exit*(a1: pointer) {.importc, header: "<pthread.h>".}
proc pthread_getconcurrency*(): cint {.importc, header: "<pthread.h>".}
proc pthread_getcpuclockid*(a1: Pthread, a2: var ClockId): cint {.importc, header: "<pthread.h>".}
proc pthread_getschedparam*(a1: Pthread,  a2: var cint,
          a3: ptr Sched_param): cint {.importc, header: "<pthread.h>".}
proc pthread_getspecific*(a1: Pthread_key): pointer {.importc, header: "<pthread.h>".}
proc pthread_join*(a1: Pthread, a2: ptr pointer): cint {.importc, header: "<pthread.h>".}
proc pthread_key_create*(a1: ptr Pthread_key, a2: proc (x: pointer) {.noconv.}): cint {.importc, header: "<pthread.h>".}
proc pthread_key_delete*(a1: Pthread_key): cint {.importc, header: "<pthread.h>".}

proc pthread_mutex_destroy*(a1: ptr Pthread_mutex): cint {.importc, header: "<pthread.h>".}
proc pthread_mutex_getprioceiling*(a1: ptr Pthread_mutex,
         a2: var cint): cint {.importc, header: "<pthread.h>".}
proc pthread_mutex_init*(a1: ptr Pthread_mutex,
          a2: ptr Pthread_mutexattr): cint {.importc, header: "<pthread.h>".}
proc pthread_mutex_lock*(a1: ptr Pthread_mutex): cint {.importc, header: "<pthread.h>".}
proc pthread_mutex_setprioceiling*(a1: ptr Pthread_mutex,a2: cint,
          a3: var cint): cint {.importc, header: "<pthread.h>".}
proc pthread_mutex_timedlock*(a1: ptr Pthread_mutex,
          a2: ptr Timespec): cint {.importc, header: "<pthread.h>".}
proc pthread_mutex_trylock*(a1: ptr Pthread_mutex): cint {.importc, header: "<pthread.h>".}
proc pthread_mutex_unlock*(a1: ptr Pthread_mutex): cint {.importc, header: "<pthread.h>".}
proc pthread_mutexattr_destroy*(a1: ptr Pthread_mutexattr): cint {.importc, header: "<pthread.h>".}

proc pthread_mutexattr_getprioceiling*(
          a1: ptr Pthread_mutexattr, a2: var cint): cint {.importc, header: "<pthread.h>".}
proc pthread_mutexattr_getprotocol*(a1: ptr Pthread_mutexattr,
          a2: var cint): cint {.importc, header: "<pthread.h>".}
proc pthread_mutexattr_getpshared*(a1: ptr Pthread_mutexattr,
          a2: var cint): cint {.importc, header: "<pthread.h>".}
proc pthread_mutexattr_gettype*(a1: ptr Pthread_mutexattr,
          a2: var cint): cint {.importc, header: "<pthread.h>".}

proc pthread_mutexattr_init*(a1: ptr Pthread_mutexattr): cint {.importc, header: "<pthread.h>".}
proc pthread_mutexattr_setprioceiling*(a1: ptr Pthread_mutexattr, a2: cint): cint {.importc, header: "<pthread.h>".}
proc pthread_mutexattr_setprotocol*(a1: ptr Pthread_mutexattr, a2: cint): cint {.importc, header: "<pthread.h>".}
proc pthread_mutexattr_setpshared*(a1: ptr Pthread_mutexattr, a2: cint): cint {.importc, header: "<pthread.h>".}
proc pthread_mutexattr_settype*(a1: ptr Pthread_mutexattr, a2: cint): cint {.importc, header: "<pthread.h>".}

proc pthread_once*(a1: ptr Pthread_once, a2: proc () {.noconv.}): cint {.importc, header: "<pthread.h>".}

proc pthread_rwlock_destroy*(a1: ptr Pthread_rwlock): cint {.importc, header: "<pthread.h>".}
proc pthread_rwlock_init*(a1: ptr Pthread_rwlock,
          a2: ptr Pthread_rwlockattr): cint {.importc, header: "<pthread.h>".}
proc pthread_rwlock_rdlock*(a1: ptr Pthread_rwlock): cint {.importc, header: "<pthread.h>".}
proc pthread_rwlock_timedrdlock*(a1: ptr Pthread_rwlock,
          a2: ptr Timespec): cint {.importc, header: "<pthread.h>".}
proc pthread_rwlock_timedwrlock*(a1: ptr Pthread_rwlock,
          a2: ptr Timespec): cint {.importc, header: "<pthread.h>".}

proc pthread_rwlock_tryrdlock*(a1: ptr Pthread_rwlock): cint {.importc, header: "<pthread.h>".}
proc pthread_rwlock_trywrlock*(a1: ptr Pthread_rwlock): cint {.importc, header: "<pthread.h>".}
proc pthread_rwlock_unlock*(a1: ptr Pthread_rwlock): cint {.importc, header: "<pthread.h>".}
proc pthread_rwlock_wrlock*(a1: ptr Pthread_rwlock): cint {.importc, header: "<pthread.h>".}
proc pthread_rwlockattr_destroy*(a1: ptr Pthread_rwlockattr): cint {.importc, header: "<pthread.h>".}
proc pthread_rwlockattr_getpshared*(
          a1: ptr Pthread_rwlockattr, a2: var cint): cint {.importc, header: "<pthread.h>".}
proc pthread_rwlockattr_init*(a1: ptr Pthread_rwlockattr): cint {.importc, header: "<pthread.h>".}
proc pthread_rwlockattr_setpshared*(a1: ptr Pthread_rwlockattr, a2: cint): cint {.importc, header: "<pthread.h>".}

proc pthread_self*(): Pthread {.importc, header: "<pthread.h>".}
proc pthread_setcancelstate*(a1: cint, a2: var cint): cint {.importc, header: "<pthread.h>".}
proc pthread_setcanceltype*(a1: cint, a2: var cint): cint {.importc, header: "<pthread.h>".}
proc pthread_setconcurrency*(a1: cint): cint {.importc, header: "<pthread.h>".}
proc pthread_setschedparam*(a1: Pthread, a2: cint,
          a3: ptr Sched_param): cint {.importc, header: "<pthread.h>".}

proc pthread_setschedprio*(a1: Pthread, a2: cint): cint {.
  importc, header: "<pthread.h>".}
proc pthread_setspecific*(a1: Pthread_key, a2: pointer): cint {.
  importc, header: "<pthread.h>".}
proc pthread_spin_destroy*(a1: ptr Pthread_spinlock): cint {.
  importc, header: "<pthread.h>".}
proc pthread_spin_init*(a1: ptr Pthread_spinlock, a2: cint): cint {.
  importc, header: "<pthread.h>".}
proc pthread_spin_lock*(a1: ptr Pthread_spinlock): cint {.
  importc, header: "<pthread.h>".}
proc pthread_spin_trylock*(a1: ptr Pthread_spinlock): cint{.
  importc, header: "<pthread.h>".}
proc pthread_spin_unlock*(a1: ptr Pthread_spinlock): cint {.
  importc, header: "<pthread.h>".}
proc pthread_testcancel*() {.importc, header: "<pthread.h>".}


proc exitnow*(code: int): void {.importc: "_exit", header: "<unistd.h>".}
proc access*(a1: cstring, a2: cint): cint {.importc, header: "<unistd.h>".}
proc alarm*(a1: cint): cint {.importc, header: "<unistd.h>".}
proc chdir*(a1: cstring): cint {.importc, header: "<unistd.h>".}
proc chown*(a1: cstring, a2: Uid, a3: Gid): cint {.importc, header: "<unistd.h>".}
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
proc fchown*(a1: cint, a2: Uid, a3: Gid): cint {.importc, header: "<unistd.h>".}
proc fchdir*(a1: cint): cint {.importc, header: "<unistd.h>".}
proc fdatasync*(a1: cint): cint {.importc, header: "<unistd.h>".}
proc fork*(): Pid {.importc, header: "<unistd.h>".}
proc fpathconf*(a1, a2: cint): int {.importc, header: "<unistd.h>".}
proc fsync*(a1: cint): cint {.importc, header: "<unistd.h>".}
proc ftruncate*(a1: cint, a2: Off): cint {.importc, header: "<unistd.h>".}
proc getcwd*(a1: cstring, a2: int): cstring {.importc, header: "<unistd.h>".}
proc getegid*(): Gid {.importc, header: "<unistd.h>".}
proc geteuid*(): Uid {.importc, header: "<unistd.h>".}
proc getgid*(): Gid {.importc, header: "<unistd.h>".}

proc getgroups*(a1: cint, a2: ptr array[0..255, Gid]): cint {.
  importc, header: "<unistd.h>".}
proc gethostid*(): int {.importc, header: "<unistd.h>".}
proc gethostname*(a1: cstring, a2: int): cint {.importc, header: "<unistd.h>".}
proc getlogin*(): cstring {.importc, header: "<unistd.h>".}
proc getlogin_r*(a1: cstring, a2: int): cint {.importc, header: "<unistd.h>".}

proc getopt*(a1: cint, a2: cstringArray, a3: cstring): cint {.
  importc, header: "<unistd.h>".}
proc getpgid*(a1: Pid): Pid {.importc, header: "<unistd.h>".}
proc getpgrp*(): Pid {.importc, header: "<unistd.h>".}
proc getpid*(): Pid {.importc, header: "<unistd.h>".}
proc getppid*(): Pid {.importc, header: "<unistd.h>".}
proc getsid*(a1: Pid): Pid {.importc, header: "<unistd.h>".}
proc getuid*(): Uid {.importc, header: "<unistd.h>".}
proc getwd*(a1: cstring): cstring {.importc, header: "<unistd.h>".}
proc isatty*(a1: cint): cint {.importc, header: "<unistd.h>".}
proc lchown*(a1: cstring, a2: Uid, a3: Gid): cint {.importc, header: "<unistd.h>".}
proc link*(a1, a2: cstring): cint {.importc, header: "<unistd.h>".}

proc lockf*(a1, a2: cint, a3: Off): cint {.importc, header: "<unistd.h>".}
proc lseek*(a1: cint, a2: Off, a3: cint): Off {.importc, header: "<unistd.h>".}
proc nice*(a1: cint): cint {.importc, header: "<unistd.h>".}
proc pathconf*(a1: cstring, a2: cint): int {.importc, header: "<unistd.h>".}

proc pause*(): cint {.importc, header: "<unistd.h>".}
proc pclose*(a: File): cint {.importc, header: "<stdio.h>".}
proc pipe*(a: array[0..1, cint]): cint {.importc, header: "<unistd.h>".}
proc popen*(a1, a2: cstring): File {.importc, header: "<stdio.h>".}
proc pread*(a1: cint, a2: pointer, a3: int, a4: Off): int {.
  importc, header: "<unistd.h>".}
proc pwrite*(a1: cint, a2: pointer, a3: int, a4: Off): int {.
  importc, header: "<unistd.h>".}
proc read*(a1: cint, a2: pointer, a3: int): int {.importc, header: "<unistd.h>".}
proc readlink*(a1, a2: cstring, a3: int): int {.importc, header: "<unistd.h>".}
proc ioctl*(f: FileHandle, device: uint): int {.importc: "ioctl",
      header: "<sys/ioctl.h>", varargs, tags: [WriteIOEffect].}
  ## A system call for device-specific input/output operations and other
  ## operations which cannot be expressed by regular system calls

proc rmdir*(a1: cstring): cint {.importc, header: "<unistd.h>".}
proc setegid*(a1: Gid): cint {.importc, header: "<unistd.h>".}
proc seteuid*(a1: Uid): cint {.importc, header: "<unistd.h>".}
proc setgid*(a1: Gid): cint {.importc, header: "<unistd.h>".}

proc setpgid*(a1, a2: Pid): cint {.importc, header: "<unistd.h>".}
proc setpgrp*(): Pid {.importc, header: "<unistd.h>".}
proc setregid*(a1, a2: Gid): cint {.importc, header: "<unistd.h>".}
proc setreuid*(a1, a2: Uid): cint {.importc, header: "<unistd.h>".}
proc setsid*(): Pid {.importc, header: "<unistd.h>".}
proc setuid*(a1: Uid): cint {.importc, header: "<unistd.h>".}
proc sleep*(a1: cint): cint {.importc, header: "<unistd.h>".}
proc swab*(a1, a2: pointer, a3: int) {.importc, header: "<unistd.h>".}
proc symlink*(a1, a2: cstring): cint {.importc, header: "<unistd.h>".}
proc sync*() {.importc, header: "<unistd.h>".}
proc sysconf*(a1: cint): int {.importc, header: "<unistd.h>".}
proc tcgetpgrp*(a1: cint): Pid {.importc, header: "<unistd.h>".}
proc tcsetpgrp*(a1: cint, a2: Pid): cint {.importc, header: "<unistd.h>".}
proc truncate*(a1: cstring, a2: Off): cint {.importc, header: "<unistd.h>".}
proc ttyname*(a1: cint): cstring {.importc, header: "<unistd.h>".}
proc ttyname_r*(a1: cint, a2: cstring, a3: int): cint {.
  importc, header: "<unistd.h>".}
proc ualarm*(a1, a2: Useconds): Useconds {.importc, header: "<unistd.h>".}
proc unlink*(a1: cstring): cint {.importc, header: "<unistd.h>".}
proc usleep*(a1: Useconds): cint {.importc, header: "<unistd.h>".}
proc vfork*(): Pid {.importc, header: "<unistd.h>".}
proc write*(a1: cint, a2: pointer, a3: int): int {.importc, header: "<unistd.h>".}

proc sem_close*(a1: ptr Sem): cint {.importc, header: "<semaphore.h>".}
proc sem_destroy*(a1: ptr Sem): cint {.importc, header: "<semaphore.h>".}
proc sem_getvalue*(a1: ptr Sem, a2: var cint): cint {.
  importc, header: "<semaphore.h>".}
proc sem_init*(a1: ptr Sem, a2: cint, a3: cint): cint {.
  importc, header: "<semaphore.h>".}
proc sem_open*(a1: cstring, a2: cint): ptr Sem {.
  varargs, importc, header: "<semaphore.h>".}
proc sem_post*(a1: ptr Sem): cint {.importc, header: "<semaphore.h>".}
proc sem_timedwait*(a1: ptr Sem, a2: ptr Timespec): cint {.
  importc, header: "<semaphore.h>".}
proc sem_trywait*(a1: ptr Sem): cint {.importc, header: "<semaphore.h>".}
proc sem_unlink*(a1: cstring): cint {.importc, header: "<semaphore.h>".}
proc sem_wait*(a1: ptr Sem): cint {.importc, header: "<semaphore.h>".}

proc ftok*(a1: cstring, a2: cint): Key {.importc, header: "<sys/ipc.h>".}

proc statvfs*(a1: cstring, a2: var Statvfs): cint {.
  importc, header: "<sys/statvfs.h>".}
proc fstatvfs*(a1: cint, a2: var Statvfs): cint {.
  importc, header: "<sys/statvfs.h>".}

proc chmod*(a1: cstring, a2: Mode): cint {.importc, header: "<sys/stat.h>".}
proc fchmod*(a1: cint, a2: Mode): cint {.importc, header: "<sys/stat.h>".}
proc fstat*(a1: cint, a2: var Stat): cint {.importc, header: "<sys/stat.h>".}
proc lstat*(a1: cstring, a2: var Stat): cint {.importc, header: "<sys/stat.h>".}
proc mkdir*(a1: cstring, a2: Mode): cint {.importc, header: "<sys/stat.h>".}
proc mkfifo*(a1: cstring, a2: Mode): cint {.importc, header: "<sys/stat.h>".}
proc mknod*(a1: cstring, a2: Mode, a3: Dev): cint {.
  importc, header: "<sys/stat.h>".}
proc stat*(a1: cstring, a2: var Stat): cint {.importc, header: "<sys/stat.h>".}
proc umask*(a1: Mode): Mode {.importc, header: "<sys/stat.h>".}

proc S_ISBLK*(m: Mode): bool {.importc, header: "<sys/stat.h>".}
  ## Test for a block special file.
proc S_ISCHR*(m: Mode): bool {.importc, header: "<sys/stat.h>".}
  ## Test for a character special file.
proc S_ISDIR*(m: Mode): bool {.importc, header: "<sys/stat.h>".}
  ## Test for a directory.
proc S_ISFIFO*(m: Mode): bool {.importc, header: "<sys/stat.h>".}
  ## Test for a pipe or FIFO special file.
proc S_ISREG*(m: Mode): bool {.importc, header: "<sys/stat.h>".}
  ## Test for a regular file.
proc S_ISLNK*(m: Mode): bool {.importc, header: "<sys/stat.h>".}
  ## Test for a symbolic link.
proc S_ISSOCK*(m: Mode): bool {.importc, header: "<sys/stat.h>".}
  ## Test for a socket.

proc S_TYPEISMQ*(buf: var Stat): bool {.importc, header: "<sys/stat.h>".}
  ## Test for a message queue.
proc S_TYPEISSEM*(buf: var Stat): bool {.importc, header: "<sys/stat.h>".}
  ## Test for a semaphore.
proc S_TYPEISSHM*(buf: var Stat): bool {.importc, header: "<sys/stat.h>".}
  ## Test for a shared memory object.

proc S_TYPEISTMO*(buf: var Stat): bool {.importc, header: "<sys/stat.h>".}
  ## Test macro for a typed memory object.

proc mlock*(a1: pointer, a2: int): cint {.importc, header: "<sys/mman.h>".}
proc mlockall*(a1: cint): cint {.importc, header: "<sys/mman.h>".}
proc mmap*(a1: pointer, a2: int, a3, a4, a5: cint, a6: Off): pointer {.
  importc, header: "<sys/mman.h>".}
proc mprotect*(a1: pointer, a2: int, a3: cint): cint {.
  importc, header: "<sys/mman.h>".}
proc msync*(a1: pointer, a2: int, a3: cint): cint {.importc, header: "<sys/mman.h>".}
proc munlock*(a1: pointer, a2: int): cint {.importc, header: "<sys/mman.h>".}
proc munlockall*(): cint {.importc, header: "<sys/mman.h>".}
proc munmap*(a1: pointer, a2: int): cint {.importc, header: "<sys/mman.h>".}
proc posix_madvise*(a1: pointer, a2: int, a3: cint): cint {.
  importc, header: "<sys/mman.h>".}
proc posix_mem_offset*(a1: pointer, a2: int, a3: var Off,
           a4: var int, a5: var cint): cint {.importc, header: "<sys/mman.h>".}
when not (defined(linux) and defined(amd64)):
  proc posix_typed_mem_get_info*(a1: cint,
    a2: var Posix_typed_mem_info): cint {.importc, header: "<sys/mman.h>".}
proc posix_typed_mem_open*(a1: cstring, a2, a3: cint): cint {.
  importc, header: "<sys/mman.h>".}
proc shm_open*(a1: cstring, a2: cint, a3: Mode): cint {.
  importc, header: "<sys/mman.h>".}
proc shm_unlink*(a1: cstring): cint {.importc, header: "<sys/mman.h>".}

proc asctime*(a1: var Tm): cstring{.importc, header: "<time.h>".}

proc asctime_r*(a1: var Tm, a2: cstring): cstring {.importc, header: "<time.h>".}
proc clock*(): Clock {.importc, header: "<time.h>".}
proc clock_getcpuclockid*(a1: Pid, a2: var ClockId): cint {.
  importc, header: "<time.h>".}
proc clock_getres*(a1: ClockId, a2: var Timespec): cint {.
  importc, header: "<time.h>".}
proc clock_gettime*(a1: ClockId, a2: var Timespec): cint {.
  importc, header: "<time.h>".}
proc clock_nanosleep*(a1: ClockId, a2: cint, a3: var Timespec,
               a4: var Timespec): cint {.importc, header: "<time.h>".}
proc clock_settime*(a1: ClockId, a2: var Timespec): cint {.
  importc, header: "<time.h>".}

proc ctime*(a1: var Time): cstring {.importc, header: "<time.h>".}
proc ctime_r*(a1: var Time, a2: cstring): cstring {.importc, header: "<time.h>".}
proc difftime*(a1, a2: Time): cdouble {.importc, header: "<time.h>".}
proc getdate*(a1: cstring): ptr Tm {.importc, header: "<time.h>".}

proc gmtime*(a1: var Time): ptr Tm {.importc, header: "<time.h>".}
proc gmtime_r*(a1: var Time, a2: var Tm): ptr Tm {.importc, header: "<time.h>".}
proc localtime*(a1: var Time): ptr Tm {.importc, header: "<time.h>".}
proc localtime_r*(a1: var Time, a2: var Tm): ptr Tm {.importc, header: "<time.h>".}
proc mktime*(a1: var Tm): Time  {.importc, header: "<time.h>".}
proc timegm*(a1: var Tm): Time  {.importc, header: "<time.h>".}
proc nanosleep*(a1, a2: var Timespec): cint {.importc, header: "<time.h>".}
proc strftime*(a1: cstring, a2: int, a3: cstring,
           a4: var Tm): int {.importc, header: "<time.h>".}
proc strptime*(a1, a2: cstring, a3: var Tm): cstring {.importc, header: "<time.h>".}
proc time*(a1: var Time): Time {.importc, header: "<time.h>".}
proc timer_create*(a1: ClockId, a2: var SigEvent,
               a3: var Timer): cint {.importc, header: "<time.h>".}
proc timer_delete*(a1: Timer): cint {.importc, header: "<time.h>".}
proc timer_gettime*(a1: Timer, a2: var Itimerspec): cint {.
  importc, header: "<time.h>".}
proc timer_getoverrun*(a1: Timer): cint {.importc, header: "<time.h>".}
proc timer_settime*(a1: Timer, a2: cint, a3: var Itimerspec,
               a4: var Itimerspec): cint {.importc, header: "<time.h>".}
proc tzset*() {.importc, header: "<time.h>".}


proc wait*(a1: ptr cint): Pid {.importc, discardable, header: "<sys/wait.h>".}
proc waitid*(a1: cint, a2: Id, a3: var SigInfo, a4: cint): cint {.
  importc, header: "<sys/wait.h>".}
proc waitpid*(a1: Pid, a2: var cint, a3: cint): Pid {.
  importc, header: "<sys/wait.h>".}

proc bsd_signal*(a1: cint, a2: proc (x: pointer) {.noconv.}) {.
  importc, header: "<signal.h>".}
proc kill*(a1: Pid, a2: cint): cint {.importc, header: "<signal.h>".}
proc killpg*(a1: Pid, a2: cint): cint {.importc, header: "<signal.h>".}
proc pthread_kill*(a1: Pthread, a2: cint): cint {.importc, header: "<signal.h>".}
proc pthread_sigmask*(a1: cint, a2, a3: var Sigset): cint {.
  importc, header: "<signal.h>".}
proc `raise`*(a1: cint): cint {.importc, header: "<signal.h>".}
proc sigaction*(a1: cint, a2, a3: var Sigaction): cint {.
  importc, header: "<signal.h>".}

proc sigaction*(a1: cint, a2: var Sigaction; a3: ptr Sigaction = nil): cint {.
  importc, header: "<signal.h>".}

proc sigaddset*(a1: var Sigset, a2: cint): cint {.importc, header: "<signal.h>".}
proc sigaltstack*(a1, a2: var Stack): cint {.importc, header: "<signal.h>".}
proc sigdelset*(a1: var Sigset, a2: cint): cint {.importc, header: "<signal.h>".}
proc sigemptyset*(a1: var Sigset): cint {.importc, header: "<signal.h>".}
proc sigfillset*(a1: var Sigset): cint {.importc, header: "<signal.h>".}
proc sighold*(a1: cint): cint {.importc, header: "<signal.h>".}
proc sigignore*(a1: cint): cint {.importc, header: "<signal.h>".}
proc siginterrupt*(a1, a2: cint): cint {.importc, header: "<signal.h>".}
proc sigismember*(a1: var Sigset, a2: cint): cint {.importc, header: "<signal.h>".}
proc signal*(a1: cint, a2: proc (x: cint) {.noconv.}) {.
  importc, header: "<signal.h>".}
proc sigpause*(a1: cint): cint {.importc, header: "<signal.h>".}
proc sigpending*(a1: var Sigset): cint {.importc, header: "<signal.h>".}
proc sigprocmask*(a1: cint, a2, a3: var Sigset): cint {.
  importc, header: "<signal.h>".}
proc sigqueue*(a1: Pid, a2: cint, a3: SigVal): cint {.
  importc, header: "<signal.h>".}
proc sigrelse*(a1: cint): cint {.importc, header: "<signal.h>".}
proc sigset*(a1: int, a2: proc (x: cint) {.noconv.}) {.
  importc, header: "<signal.h>".}
proc sigsuspend*(a1: var Sigset): cint {.importc, header: "<signal.h>".}

when defined(android):
  proc syscall(arg: clong): clong {.varargs, importc: "syscall", header: "<unistd.h>".}
  var NR_rt_sigtimedwait {.importc: "__NR_rt_sigtimedwait", header: "<sys/syscall.h>".}: clong
  var NSIGMAX {.importc: "NSIG", header: "<signal.h>".}: clong

  proc sigtimedwait*(a1: var Sigset, a2: var SigInfo, a3: var Timespec): cint =
    result = cint(syscall(NR_rt_sigtimedwait, addr(a1), addr(a2), addr(a3), NSIGMAX div 8))
else:
  proc sigtimedwait*(a1: var Sigset, a2: var SigInfo,
                     a3: var Timespec): cint {.importc, header: "<signal.h>".}

proc sigwait*(a1: var Sigset, a2: var cint): cint {.
  importc, header: "<signal.h>".}
proc sigwaitinfo*(a1: var Sigset, a2: var SigInfo): cint {.
  importc, header: "<signal.h>".}


proc catclose*(a1: Nl_catd): cint {.importc, header: "<nl_types.h>".}
proc catgets*(a1: Nl_catd, a2, a3: cint, a4: cstring): cstring {.
  importc, header: "<nl_types.h>".}
proc catopen*(a1: cstring, a2: cint): Nl_catd {.
  importc, header: "<nl_types.h>".}

proc sched_get_priority_max*(a1: cint): cint {.importc, header: "<sched.h>".}
proc sched_get_priority_min*(a1: cint): cint {.importc, header: "<sched.h>".}
proc sched_getparam*(a1: Pid, a2: var Sched_param): cint {.
  importc, header: "<sched.h>".}
proc sched_getscheduler*(a1: Pid): cint {.importc, header: "<sched.h>".}
proc sched_rr_get_interval*(a1: Pid, a2: var Timespec): cint {.
  importc, header: "<sched.h>".}
proc sched_setparam*(a1: Pid, a2: var Sched_param): cint {.
  importc, header: "<sched.h>".}
proc sched_setscheduler*(a1: Pid, a2: cint, a3: var Sched_param): cint {.
  importc, header: "<sched.h>".}
proc sched_yield*(): cint {.importc, header: "<sched.h>".}

proc strerror*(errnum: cint): cstring {.importc, header: "<string.h>".}
proc hstrerror*(herrnum: cint): cstring {.importc:"(char *)$1", header: "<netdb.h>".}

proc FD_CLR*(a1: cint, a2: var TFdSet) {.importc, header: "<sys/select.h>".}
proc FD_ISSET*(a1: cint | SocketHandle, a2: var TFdSet): cint {.
  importc, header: "<sys/select.h>".}
proc FD_SET*(a1: cint | SocketHandle, a2: var TFdSet) {.
  importc: "FD_SET", header: "<sys/select.h>".}
proc FD_ZERO*(a1: var TFdSet) {.importc, header: "<sys/select.h>".}

proc pselect*(a1: cint, a2, a3, a4: ptr TFdSet, a5: ptr Timespec,
         a6: var Sigset): cint  {.importc, header: "<sys/select.h>".}
proc select*(a1: cint | SocketHandle, a2, a3, a4: ptr TFdSet, a5: ptr Timeval): cint {.
             importc, header: "<sys/select.h>".}

when hasSpawnH:
  proc posix_spawn*(a1: var Pid, a2: cstring,
            a3: var Tposix_spawn_file_actions,
            a4: var Tposix_spawnattr,
            a5, a6: cstringArray): cint {.importc, header: "<spawn.h>".}
  proc posix_spawn_file_actions_addclose*(a1: var Tposix_spawn_file_actions,
            a2: cint): cint {.importc, header: "<spawn.h>".}
  proc posix_spawn_file_actions_adddup2*(a1: var Tposix_spawn_file_actions,
            a2, a3: cint): cint {.importc, header: "<spawn.h>".}
  proc posix_spawn_file_actions_addopen*(a1: var Tposix_spawn_file_actions,
            a2: cint, a3: cstring, a4: cint, a5: Mode): cint {.
            importc, header: "<spawn.h>".}
  proc posix_spawn_file_actions_destroy*(
    a1: var Tposix_spawn_file_actions): cint {.importc, header: "<spawn.h>".}
  proc posix_spawn_file_actions_init*(
    a1: var Tposix_spawn_file_actions): cint {.importc, header: "<spawn.h>".}
  proc posix_spawnattr_destroy*(a1: var Tposix_spawnattr): cint {.
    importc, header: "<spawn.h>".}
  proc posix_spawnattr_getsigdefault*(a1: var Tposix_spawnattr,
            a2: var Sigset): cint {.importc, header: "<spawn.h>".}
  proc posix_spawnattr_getflags*(a1: var Tposix_spawnattr,
            a2: var cshort): cint {.importc, header: "<spawn.h>".}
  proc posix_spawnattr_getpgroup*(a1: var Tposix_spawnattr,
            a2: var Pid): cint {.importc, header: "<spawn.h>".}
  proc posix_spawnattr_getschedparam*(a1: var Tposix_spawnattr,
            a2: var Sched_param): cint {.importc, header: "<spawn.h>".}
  proc posix_spawnattr_getschedpolicy*(a1: var Tposix_spawnattr,
            a2: var cint): cint {.importc, header: "<spawn.h>".}
  proc posix_spawnattr_getsigmask*(a1: var Tposix_spawnattr,
            a2: var Sigset): cint {.importc, header: "<spawn.h>".}

  proc posix_spawnattr_init*(a1: var Tposix_spawnattr): cint {.
    importc, header: "<spawn.h>".}
  proc posix_spawnattr_setsigdefault*(a1: var Tposix_spawnattr,
            a2: var Sigset): cint {.importc, header: "<spawn.h>".}
  proc posix_spawnattr_setflags*(a1: var Tposix_spawnattr, a2: cint): cint {.
    importc, header: "<spawn.h>".}
  proc posix_spawnattr_setpgroup*(a1: var Tposix_spawnattr, a2: Pid): cint {.
    importc, header: "<spawn.h>".}

  proc posix_spawnattr_setschedparam*(a1: var Tposix_spawnattr,
            a2: var Sched_param): cint {.importc, header: "<spawn.h>".}
  proc posix_spawnattr_setschedpolicy*(a1: var Tposix_spawnattr,
                                       a2: cint): cint {.
                                       importc, header: "<spawn.h>".}
  proc posix_spawnattr_setsigmask*(a1: var Tposix_spawnattr,
            a2: var Sigset): cint {.importc, header: "<spawn.h>".}
  proc posix_spawnp*(a1: var Pid, a2: cstring,
            a3: var Tposix_spawn_file_actions,
            a4: var Tposix_spawnattr,
            a5, a6: cstringArray): cint {.importc, header: "<spawn.h>".}

proc getcontext*(a1: var Ucontext): cint {.importc, header: "<ucontext.h>".}
proc makecontext*(a1: var Ucontext, a4: proc (){.noconv.}, a3: cint) {.
  varargs, importc, header: "<ucontext.h>".}
proc setcontext*(a1: var Ucontext): cint {.importc, header: "<ucontext.h>".}
proc swapcontext*(a1, a2: var Ucontext): cint {.importc, header: "<ucontext.h>".}

proc readv*(a1: cint, a2: ptr IOVec, a3: cint): int {.
  importc, header: "<sys/uio.h>".}
proc writev*(a1: cint, a2: ptr IOVec, a3: cint): int {.
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

proc IN6_IS_ADDR_UNSPECIFIED* (a1: ptr In6Addr): cint {.
  importc, header: "<netinet/in.h>".}
  ## Unspecified address.
proc IN6_IS_ADDR_LOOPBACK* (a1: ptr In6Addr): cint {.
  importc, header: "<netinet/in.h>".}
  ## Loopback address.
proc IN6_IS_ADDR_MULTICAST* (a1: ptr In6Addr): cint {.
  importc, header: "<netinet/in.h>".}
  ## Multicast address.
proc IN6_IS_ADDR_LINKLOCAL* (a1: ptr In6Addr): cint {.
  importc, header: "<netinet/in.h>".}
  ## Unicast link-local address.
proc IN6_IS_ADDR_SITELOCAL* (a1: ptr In6Addr): cint {.
  importc, header: "<netinet/in.h>".}
  ## Unicast site-local address.
proc IN6_IS_ADDR_V4MAPPED* (a1: ptr In6Addr): cint {.
  importc, header: "<netinet/in.h>".}
  ## IPv4 mapped address.
proc IN6_IS_ADDR_V4COMPAT* (a1: ptr In6Addr): cint {.
  importc, header: "<netinet/in.h>".}
  ## IPv4-compatible address.
proc IN6_IS_ADDR_MC_NODELOCAL* (a1: ptr In6Addr): cint {.
  importc, header: "<netinet/in.h>".}
  ## Multicast node-local address.
proc IN6_IS_ADDR_MC_LINKLOCAL* (a1: ptr In6Addr): cint {.
  importc, header: "<netinet/in.h>".}
  ## Multicast link-local address.
proc IN6_IS_ADDR_MC_SITELOCAL* (a1: ptr In6Addr): cint {.
  importc, header: "<netinet/in.h>".}
  ## Multicast site-local address.
proc IN6_IS_ADDR_MC_ORGLOCAL* (a1: ptr In6Addr): cint {.
  importc, header: "<netinet/in.h>".}
  ## Multicast organization-local address.
proc IN6_IS_ADDR_MC_GLOBAL* (a1: ptr In6Addr): cint {.
  importc, header: "<netinet/in.h>".}
  ## Multicast global address.

proc endhostent*() {.importc, header: "<netdb.h>".}
proc endnetent*() {.importc, header: "<netdb.h>".}
proc endprotoent*() {.importc, header: "<netdb.h>".}
proc endservent*() {.importc, header: "<netdb.h>".}
proc freeaddrinfo*(a1: ptr AddrInfo) {.importc, header: "<netdb.h>".}

proc gai_strerror*(a1: cint): cstring {.importc:"(char *)$1", header: "<netdb.h>".}

proc getaddrinfo*(a1, a2: cstring, a3: ptr AddrInfo,
                  a4: var ptr AddrInfo): cint {.importc, header: "<netdb.h>".}

when not defined(android4):
  proc gethostbyaddr*(a1: pointer, a2: Socklen, a3: cint): ptr Hostent {.
                      importc, header: "<netdb.h>".}
else:
  proc gethostbyaddr*(a1: cstring, a2: cint, a3: cint): ptr Hostent {.
                      importc, header: "<netdb.h>".}
proc gethostbyname*(a1: cstring): ptr Hostent {.importc, header: "<netdb.h>".}
proc gethostent*(): ptr Hostent {.importc, header: "<netdb.h>".}

proc getnameinfo*(a1: ptr SockAddr, a2: Socklen,
                  a3: cstring, a4: Socklen, a5: cstring,
                  a6: Socklen, a7: cint): cint {.importc, header: "<netdb.h>".}

proc getnetbyaddr*(a1: int32, a2: cint): ptr Tnetent {.importc, header: "<netdb.h>".}
proc getnetbyname*(a1: cstring): ptr Tnetent {.importc, header: "<netdb.h>".}
proc getnetent*(): ptr Tnetent {.importc, header: "<netdb.h>".}

proc getprotobyname*(a1: cstring): ptr Protoent {.importc, header: "<netdb.h>".}
proc getprotobynumber*(a1: cint): ptr Protoent {.importc, header: "<netdb.h>".}
proc getprotoent*(): ptr Protoent {.importc, header: "<netdb.h>".}

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

proc mkstemp*(tmpl: cstring): cint {.importc, header: "<stdlib.h>".}
  ## Create a temporary file.
  ##
  ## **Warning**: The `tmpl` argument is written to by `mkstemp` and thus
  ## can't be a string literal. If in doubt copy the string before passing it.

proc utimes*(path: cstring, times: ptr array[2, Timeval]): int {.
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

proc handle_signal(sig: cint, handler: proc (a: cint) {.noconv.}) {.importc: "signal", header: "<signal.h>".}

template onSignal*(signals: varargs[cint], body: untyped) =
  ## Setup code to be executed when Unix signals are received. Example:
  ## from posix import SIGINT, SIGTERM
  ## onSignal(SIGINT, SIGTERM):
  ##   echo "bye"

  for s in signals:
    handle_signal(s,
      proc (sig: cint) {.noconv.} =
        body
    )
