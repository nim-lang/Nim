# Generated by detect.nim


# <aio.h>

# <dlfcn.h>

# <errno.h>
const E2BIG* = cint(7)
const EACCES* = cint(13)
const EADDRINUSE* = cint(112)
const EADDRNOTAVAIL* = cint(125)
const EAFNOSUPPORT* = cint(106)
const EAGAIN* = cint(11)
const EALREADY* = cint(120)
const EBADF* = cint(9)
const EBADMSG* = cint(77)
const EBUSY* = cint(16)
const ECANCELED* = cint(140)
const ECHILD* = cint(10)
const ECONNABORTED* = cint(113)
const ECONNREFUSED* = cint(111)
const ECONNRESET* = cint(104)
const EDEADLK* = cint(45)
const EDESTADDRREQ* = cint(121)
const EDOM* = cint(33)
const EDQUOT* = cint(132)
const EEXIST* = cint(17)
const EFAULT* = cint(14)
const EFBIG* = cint(27)
const EHOSTUNREACH* = cint(118)
const EIDRM* = cint(36)
const EILSEQ* = cint(138)
const EINPROGRESS* = cint(119)
const EINTR* = cint(4)
const EINVAL* = cint(22)
const EIO* = cint(5)
const EISCONN* = cint(127)
const EISDIR* = cint(21)
const ELOOP* = cint(92)
const EMFILE* = cint(24)
const EMLINK* = cint(31)
const EMSGSIZE* = cint(122)
const EMULTIHOP* = cint(74)
const ENAMETOOLONG* = cint(91)
const ENETDOWN* = cint(115)
const ENETRESET* = cint(126)
const ENETUNREACH* = cint(114)
const ENFILE* = cint(23)
const ENOBUFS* = cint(105)
const ENODATA* = cint(61)
const ENODEV* = cint(19)
const ENOENT* = cint(2)
const ENOEXEC* = cint(8)
const ENOLCK* = cint(46)
const ENOLINK* = cint(67)
const ENOMEM* = cint(12)
const ENOMSG* = cint(35)
const ENOPROTOOPT* = cint(109)
const ENOSPC* = cint(28)
const ENOSR* = cint(63)
const ENOSTR* = cint(60)
const ENOSYS* = cint(88)
const ENOTCONN* = cint(128)
const ENOTDIR* = cint(20)
const ENOTEMPTY* = cint(90)
const ENOTSOCK* = cint(108)
const ENOTSUP* = cint(134)
const ENOTTY* = cint(25)
const ENXIO* = cint(6)
const EOPNOTSUPP* = cint(95)
const EOVERFLOW* = cint(139)
const EPERM* = cint(1)
const EPIPE* = cint(32)
const EPROTO* = cint(71)
const EPROTONOSUPPORT* = cint(123)
const EPROTOTYPE* = cint(107)
const ERANGE* = cint(34)
const EROFS* = cint(30)
const ESPIPE* = cint(29)
const ESRCH* = cint(3)
const ESTALE* = cint(133)
const ETIME* = cint(62)
const ETIMEDOUT* = cint(116)
const ETXTBSY* = cint(26)
const EWOULDBLOCK* = cint(11)
const EXDEV* = cint(18)

# <fcntl.h>
const F_DUPFD* = cint(0)
const F_GETFD* = cint(1)
const F_SETFD* = cint(2)
const F_GETFL* = cint(3)
const F_SETFL* = cint(4)
const F_GETLK* = cint(7)
const F_SETLK* = cint(8)
const F_SETLKW* = cint(9)
const F_GETOWN* = cint(5)
const F_SETOWN* = cint(6)
const FD_CLOEXEC* = cint(1)
const F_RDLCK* = cint(1)
const F_UNLCK* = cint(3)
const F_WRLCK* = cint(2)
const O_CREAT* = cint(512)
const O_EXCL* = cint(2048)
const O_NOCTTY* = cint(32768)
const O_TRUNC* = cint(1024)
const O_APPEND* = cint(8)
const O_NONBLOCK* = cint(16384)
const O_SYNC* = cint(8192)
const O_ACCMODE* = cint(3)
const O_RDONLY* = cint(0)
const O_RDWR* = cint(2)
const O_WRONLY* = cint(1)

# <fenv.h>

# <fmtmsg.h>

# <fnmatch.h>
const FNM_NOMATCH* = cint(1)
const FNM_PATHNAME* = cint(2)
const FNM_PERIOD* = cint(4)
const FNM_NOESCAPE* = cint(1)

# <ftw.h>

# <glob.h>
const GLOB_APPEND* = cint(1)
const GLOB_DOOFFS* = cint(2)
const GLOB_ERR* = cint(4)
const GLOB_MARK* = cint(8)
const GLOB_NOCHECK* = cint(16)
const GLOB_NOSORT* = cint(32)
const GLOB_NOSPACE* = cint(-1)

# <langinfo.h>
const CODESET* = cint(0)
const D_T_FMT* = cint(1)
const D_FMT* = cint(2)
const T_FMT* = cint(3)
const T_FMT_AMPM* = cint(4)
const AM_STR* = cint(5)
const PM_STR* = cint(6)
const DAY_1* = cint(7)
const DAY_2* = cint(8)
const DAY_3* = cint(9)
const DAY_4* = cint(10)
const DAY_5* = cint(11)
const DAY_6* = cint(12)
const DAY_7* = cint(13)
const ABDAY_1* = cint(14)
const ABDAY_2* = cint(15)
const ABDAY_3* = cint(16)
const ABDAY_4* = cint(17)
const ABDAY_5* = cint(18)
const ABDAY_6* = cint(19)
const ABDAY_7* = cint(20)
const MON_1* = cint(21)
const MON_2* = cint(22)
const MON_3* = cint(23)
const MON_4* = cint(24)
const MON_5* = cint(25)
const MON_6* = cint(26)
const MON_7* = cint(27)
const MON_8* = cint(28)
const MON_9* = cint(29)
const MON_10* = cint(30)
const MON_11* = cint(31)
const MON_12* = cint(32)
const ABMON_1* = cint(33)
const ABMON_2* = cint(34)
const ABMON_3* = cint(35)
const ABMON_4* = cint(36)
const ABMON_5* = cint(37)
const ABMON_6* = cint(38)
const ABMON_7* = cint(39)
const ABMON_8* = cint(40)
const ABMON_9* = cint(41)
const ABMON_10* = cint(42)
const ABMON_11* = cint(43)
const ABMON_12* = cint(44)
const ERA* = cint(45)
const ERA_D_FMT* = cint(46)
const ERA_D_T_FMT* = cint(47)
const ERA_T_FMT* = cint(48)
const ALT_DIGITS* = cint(49)
const RADIXCHAR* = cint(50)
const THOUSEP* = cint(51)
const YESEXPR* = cint(52)
const NOEXPR* = cint(53)
const CRNCYSTR* = cint(56)

# <locale.h>
const LC_ALL* = cint(0)
const LC_COLLATE* = cint(1)
const LC_CTYPE* = cint(2)
const LC_MESSAGES* = cint(6)
const LC_MONETARY* = cint(3)
const LC_NUMERIC* = cint(4)
const LC_TIME* = cint(5)

# <netdb.h>
const IPPORT_RESERVED* = cint(1024)
const HOST_NOT_FOUND* = cint(1)
const NO_DATA* = cint(4)
const NO_RECOVERY* = cint(3)
const TRY_AGAIN* = cint(2)
const AI_PASSIVE* = cint(1)
const AI_CANONNAME* = cint(2)
const AI_NUMERICHOST* = cint(4)
const AI_NUMERICSERV* = cint(8)
const AI_V4MAPPED* = cint(2048)
const AI_ALL* = cint(256)
const AI_ADDRCONFIG* = cint(1024)
const NI_NOFQDN* = cint(1)
const NI_NUMERICHOST* = cint(2)
const NI_NAMEREQD* = cint(4)
const NI_NUMERICSERV* = cint(8)
const NI_NUMERICSCOPE* = cint(32)
const NI_DGRAM* = cint(16)
const EAI_AGAIN* = cint(2)
const EAI_BADFLAGS* = cint(3)
const EAI_FAIL* = cint(4)
const EAI_FAMILY* = cint(5)
const EAI_MEMORY* = cint(6)
const EAI_NONAME* = cint(8)
const EAI_SERVICE* = cint(9)
const EAI_SOCKTYPE* = cint(10)
const EAI_SYSTEM* = cint(11)
const EAI_OVERFLOW* = cint(14)

# <net/if.h>
const IF_NAMESIZE* = cint(16)

# <netinet/in.h>
const IPPROTO_IP* = cint(0)
const IPPROTO_IPV6* = cint(41)
const IPPROTO_ICMP* = cint(1)
const IPPROTO_RAW* = cint(255)
const IPPROTO_TCP* = cint(6)
const IPPROTO_UDP* = cint(17)
const INADDR_ANY* = InAddrScalar(0)
const INADDR_LOOPBACK* = InAddrScalar(2130706433)
const INADDR_BROADCAST* = InAddrScalar(-1)
const INET_ADDRSTRLEN* = cint(16)
const INET6_ADDRSTRLEN* = cint(46)
const IPV6_JOIN_GROUP* = cint(12)
const IPV6_LEAVE_GROUP* = cint(13)
const IPV6_MULTICAST_HOPS* = cint(10)
const IPV6_MULTICAST_IF* = cint(9)
const IPV6_MULTICAST_LOOP* = cint(11)
const IPV6_UNICAST_HOPS* = cint(4)
const IPV6_V6ONLY* = cint(27)

# <netinet/tcp.h>
const TCP_NODELAY* = cint(1)

# <nl_types.h>

# <poll.h>
const POLLIN* = cshort(1)
const POLLRDNORM* = cshort(64)
const POLLRDBAND* = cshort(128)
const POLLPRI* = cshort(2)
const POLLOUT* = cshort(4)
const POLLWRNORM* = cshort(4)
const POLLWRBAND* = cshort(256)
const POLLERR* = cshort(8)
const POLLHUP* = cshort(16)
const POLLNVAL* = cshort(32)

# <pthread.h>
const PTHREAD_CREATE_DETACHED* = cint(0)
const PTHREAD_CREATE_JOINABLE* = cint(1)
const PTHREAD_EXPLICIT_SCHED* = cint(2)
const PTHREAD_INHERIT_SCHED* = cint(1)
const PTHREAD_SCOPE_PROCESS* = cint(0)
const PTHREAD_SCOPE_SYSTEM* = cint(1)

# <sched.h>
const SCHED_FIFO* = cint(1)
const SCHED_RR* = cint(2)
const SCHED_OTHER* = cint(0)

# <semaphore.h>

# <signal.h>
const SIGEV_NONE* = cint(1)
const SIGEV_SIGNAL* = cint(2)
const SIGEV_THREAD* = cint(3)
const SIGABRT* = cint(6)
const SIGALRM* = cint(14)
const SIGBUS* = cint(10)
const SIGCHLD* = cint(20)
const SIGCONT* = cint(19)
const SIGFPE* = cint(8)
const SIGHUP* = cint(1)
const SIGILL* = cint(4)
const SIGINT* = cint(2)
const SIGKILL* = cint(9)
const SIGPIPE* = cint(13)
const SIGQUIT* = cint(3)
const SIGSEGV* = cint(11)
const SIGSTOP* = cint(17)
const SIGTERM* = cint(15)
const SIGTSTP* = cint(18)
const SIGTTIN* = cint(21)
const SIGTTOU* = cint(22)
const SIGUSR1* = cint(30)
const SIGUSR2* = cint(31)
const SIGPOLL* = cint(23)
const SIGPROF* = cint(27)
const SIGSYS* = cint(12)
const SIGTRAP* = cint(5)
const SIGURG* = cint(16)
const SIGVTALRM* = cint(26)
const SIGXCPU* = cint(24)
const SIGXFSZ* = cint(25)
const SA_NOCLDSTOP* = cint(1)
const SIG_BLOCK* = cint(1)
const SIG_UNBLOCK* = cint(2)
const SIG_SETMASK* = cint(0)
const SS_ONSTACK* = cint(1)
const SS_DISABLE* = cint(2)
const MINSIGSTKSZ* = cint(2048)
const SIGSTKSZ* = cint(8192)
const SIG_DFL* = cast[Sighandler](0)
const SIG_ERR* = cast[Sighandler](-1)
const SIG_IGN* = cast[Sighandler](1)

# <sys/ipc.h>

# <sys/mman.h>

# <sys/resource.h>

# <sys/select.h>
const FD_SETSIZE* = cint(64)

# <sys/socket.h>
const MSG_CTRUNC* = cint(32)
const MSG_DONTROUTE* = cint(4)
const MSG_EOR* = cint(8)
const MSG_OOB* = cint(1)
const SCM_RIGHTS* = cint(1)
const SO_ACCEPTCONN* = cint(2)
const SO_BROADCAST* = cint(32)
const SO_DEBUG* = cint(1)
const SO_DONTROUTE* = cint(16)
const SO_ERROR* = cint(4103)
const SO_KEEPALIVE* = cint(8)
const SO_LINGER* = cint(128)
const SO_OOBINLINE* = cint(256)
const SO_RCVBUF* = cint(4098)
const SO_RCVLOWAT* = cint(4100)
const SO_RCVTIMEO* = cint(4102)
const SO_REUSEADDR* = cint(4)
const SO_SNDBUF* = cint(4097)
const SO_SNDLOWAT* = cint(4099)
const SO_SNDTIMEO* = cint(4101)
const SO_TYPE* = cint(4104)
const SOCK_DGRAM* = cint(2)
const SOCK_RAW* = cint(3)
const SOCK_SEQPACKET* = cint(5)
const SOCK_STREAM* = cint(1)
const SOL_SOCKET* = cint(65535)
const SOMAXCONN* = cint(128)
const SO_REUSEPORT* = cint(512)
const MSG_NOSIGNAL* = cint(131072)
const MSG_PEEK* = cint(2)
const MSG_TRUNC* = cint(16)
const MSG_WAITALL* = cint(64)
const AF_INET* = cint(2)
const AF_INET6* = cint(28)
const AF_UNIX* = cint(1)
const AF_UNSPEC* = cint(0)
const SHUT_RD* = cint(0)
const SHUT_RDWR* = cint(2)
const SHUT_WR* = cint(1)

# <sys/stat.h>
const S_IFBLK* = cint(24576)
const S_IFCHR* = cint(8192)
const S_IFDIR* = cint(16384)
const S_IFIFO* = cint(4096)
const S_IFLNK* = cint(40960)
const S_IFMT* = cint(61440)
const S_IFREG* = cint(32768)
const S_IFSOCK* = cint(49152)
const S_IRGRP* = cint(32)
const S_IROTH* = cint(4)
const S_IRUSR* = cint(256)
const S_IRWXG* = cint(56)
const S_IRWXO* = cint(7)
const S_IRWXU* = cint(448)
const S_ISGID* = cint(1024)
const S_ISUID* = cint(2048)
const S_ISVTX* = cint(512)
const S_IWGRP* = cint(16)
const S_IWOTH* = cint(2)
const S_IWUSR* = cint(128)
const S_IXGRP* = cint(8)
const S_IXOTH* = cint(1)
const S_IXUSR* = cint(64)

# <sys/statvfs.h>
const ST_RDONLY* = cint(1)
const ST_NOSUID* = cint(2)

# <sys/wait.h>
const WNOHANG* = cint(1)
const WUNTRACED* = cint(2)

# <spawn.h>
const POSIX_SPAWN_RESETIDS* = cint(1)
const POSIX_SPAWN_SETPGROUP* = cint(2)
const POSIX_SPAWN_SETSCHEDPARAM* = cint(4)
const POSIX_SPAWN_SETSCHEDULER* = cint(8)
const POSIX_SPAWN_SETSIGDEF* = cint(16)
const POSIX_SPAWN_SETSIGMASK* = cint(32)

# <stdio.h>
const IOFBF* = cint(0)
const IONBF* = cint(2)

# <time.h>
const CLOCKS_PER_SEC* = clong(100)
const CLOCK_REALTIME* = cint(1)
const TIMER_ABSTIME* = cint(4)
const CLOCK_MONOTONIC* = cint(4)

# <unistd.h>
const F_OK* = cint(0)
const R_OK* = cint(4)
const W_OK* = cint(2)
const X_OK* = cint(1)
const F_LOCK* = cint(1)
const F_TEST* = cint(3)
const F_TLOCK* = cint(2)
const F_ULOCK* = cint(0)
const PC_2_SYMLINKS* = cint(13)
const PC_ALLOC_SIZE_MIN* = cint(15)
const PC_ASYNC_IO* = cint(9)
const PC_CHOWN_RESTRICTED* = cint(6)
const PC_FILESIZEBITS* = cint(12)
const PC_LINK_MAX* = cint(0)
const PC_MAX_CANON* = cint(1)
const PC_MAX_INPUT* = cint(2)
const PC_NAME_MAX* = cint(3)
const PC_NO_TRUNC* = cint(7)
const PC_PATH_MAX* = cint(4)
const PC_PIPE_BUF* = cint(5)
const PC_PRIO_IO* = cint(10)
const PC_REC_INCR_XFER_SIZE* = cint(16)
const PC_REC_MIN_XFER_SIZE* = cint(18)
const PC_REC_XFER_ALIGN* = cint(19)
const PC_SYMLINK_MAX* = cint(14)
const PC_SYNC_IO* = cint(11)
const PC_VDISABLE* = cint(8)
const SC_2_C_BIND* = cint(108)
const SC_2_C_DEV* = cint(109)
const SC_2_CHAR_TERM* = cint(107)
const SC_2_FORT_DEV* = cint(110)
const SC_2_FORT_RUN* = cint(111)
const SC_2_LOCALEDEF* = cint(112)
const SC_2_PBS* = cint(113)
const SC_2_PBS_ACCOUNTING* = cint(114)
const SC_2_PBS_CHECKPOINT* = cint(115)
const SC_2_PBS_LOCATE* = cint(116)
const SC_2_PBS_MESSAGE* = cint(117)
const SC_2_PBS_TRACK* = cint(118)
const SC_2_SW_DEV* = cint(119)
const SC_2_UPE* = cint(120)
const SC_2_VERSION* = cint(121)
const SC_ADVISORY_INFO* = cint(54)
const SC_AIO_LISTIO_MAX* = cint(34)
const SC_AIO_MAX* = cint(35)
const SC_AIO_PRIO_DELTA_MAX* = cint(36)
const SC_ARG_MAX* = cint(0)
const SC_ASYNCHRONOUS_IO* = cint(21)
const SC_ATEXIT_MAX* = cint(55)
const SC_BARRIERS* = cint(56)
const SC_BC_BASE_MAX* = cint(57)
const SC_BC_DIM_MAX* = cint(58)
const SC_BC_SCALE_MAX* = cint(59)
const SC_BC_STRING_MAX* = cint(60)
const SC_CHILD_MAX* = cint(1)
const SC_CLK_TCK* = cint(2)
const SC_CLOCK_SELECTION* = cint(61)
const SC_COLL_WEIGHTS_MAX* = cint(62)
const SC_CPUTIME* = cint(63)
const SC_DELAYTIMER_MAX* = cint(37)
const SC_EXPR_NEST_MAX* = cint(64)
const SC_FSYNC* = cint(22)
const SC_GETGR_R_SIZE_MAX* = cint(50)
const SC_GETPW_R_SIZE_MAX* = cint(51)
const SC_HOST_NAME_MAX* = cint(65)
const SC_IOV_MAX* = cint(66)
const SC_IPV6* = cint(67)
const SC_JOB_CONTROL* = cint(5)
const SC_LINE_MAX* = cint(68)
const SC_LOGIN_NAME_MAX* = cint(52)
const SC_MAPPED_FILES* = cint(23)
const SC_MEMLOCK* = cint(24)
const SC_MEMLOCK_RANGE* = cint(25)
const SC_MEMORY_PROTECTION* = cint(26)
const SC_MESSAGE_PASSING* = cint(27)
const SC_MONOTONIC_CLOCK* = cint(69)
const SC_MQ_OPEN_MAX* = cint(13)
const SC_MQ_PRIO_MAX* = cint(14)
const SC_NGROUPS_MAX* = cint(3)
const SC_OPEN_MAX* = cint(4)
const SC_PAGE_SIZE* = cint(8)
const SC_PRIORITIZED_IO* = cint(28)
const SC_PRIORITY_SCHEDULING* = cint(101)
const SC_RAW_SOCKETS* = cint(70)
const SC_RE_DUP_MAX* = cint(73)
const SC_READER_WRITER_LOCKS* = cint(71)
const SC_REALTIME_SIGNALS* = cint(29)
const SC_REGEXP* = cint(72)
const SC_RTSIG_MAX* = cint(15)
const SC_SAVED_IDS* = cint(6)
const SC_SEM_NSEMS_MAX* = cint(16)
const SC_SEM_VALUE_MAX* = cint(17)
const SC_SEMAPHORES* = cint(30)
const SC_SHARED_MEMORY_OBJECTS* = cint(31)
const SC_SHELL* = cint(74)
const SC_SIGQUEUE_MAX* = cint(18)
const SC_SPAWN* = cint(75)
const SC_SPIN_LOCKS* = cint(76)
const SC_SPORADIC_SERVER* = cint(77)
const SC_SS_REPL_MAX* = cint(78)
const SC_STREAM_MAX* = cint(100)
const SC_SYMLOOP_MAX* = cint(79)
const SC_SYNCHRONIZED_IO* = cint(32)
const SC_THREAD_ATTR_STACKADDR* = cint(43)
const SC_THREAD_ATTR_STACKSIZE* = cint(44)
const SC_THREAD_CPUTIME* = cint(80)
const SC_THREAD_DESTRUCTOR_ITERATIONS* = cint(53)
const SC_THREAD_KEYS_MAX* = cint(38)
const SC_THREAD_PRIO_INHERIT* = cint(46)
const SC_THREAD_PRIO_PROTECT* = cint(47)
const SC_THREAD_PRIORITY_SCHEDULING* = cint(45)
const SC_THREAD_PROCESS_SHARED* = cint(48)
const SC_THREAD_SAFE_FUNCTIONS* = cint(49)
const SC_THREAD_SPORADIC_SERVER* = cint(81)
const SC_THREAD_STACK_MIN* = cint(39)
const SC_THREAD_THREADS_MAX* = cint(40)
const SC_THREADS* = cint(42)
const SC_TIMEOUTS* = cint(82)
const SC_TIMER_MAX* = cint(19)
const SC_TIMERS* = cint(33)
const SC_TRACE* = cint(83)
const SC_TRACE_EVENT_FILTER* = cint(84)
const SC_TRACE_EVENT_NAME_MAX* = cint(85)
const SC_TRACE_INHERIT* = cint(86)
const SC_TRACE_LOG* = cint(87)
const SC_TRACE_NAME_MAX* = cint(88)
const SC_TRACE_SYS_MAX* = cint(89)
const SC_TRACE_USER_EVENT_MAX* = cint(90)
const SC_TTY_NAME_MAX* = cint(41)
const SC_TYPED_MEMORY_OBJECTS* = cint(91)
const SC_TZNAME_MAX* = cint(20)
const SC_V6_ILP32_OFF32* = cint(92)
const SC_V6_ILP32_OFFBIG* = cint(93)
const SC_V6_LP64_OFF64* = cint(94)
const SC_V6_LPBIG_OFFBIG* = cint(95)
const SC_VERSION* = cint(7)
const SC_XBS5_ILP32_OFF32* = cint(92)
const SC_XBS5_ILP32_OFFBIG* = cint(93)
const SC_XBS5_LP64_OFF64* = cint(94)
const SC_XBS5_LPBIG_OFFBIG* = cint(95)
const SC_XOPEN_CRYPT* = cint(96)
const SC_XOPEN_ENH_I18N* = cint(97)
const SC_XOPEN_LEGACY* = cint(98)
const SC_XOPEN_REALTIME* = cint(99)
const SC_XOPEN_REALTIME_THREADS* = cint(102)
const SC_XOPEN_SHM* = cint(103)
const SC_XOPEN_STREAMS* = cint(104)
const SC_XOPEN_UNIX* = cint(105)
const SC_XOPEN_VERSION* = cint(106)
const SC_NPROCESSORS_ONLN* = cint(10)
const SEEK_SET* = cint(0)
const SEEK_CUR* = cint(1)
const SEEK_END* = cint(2)
