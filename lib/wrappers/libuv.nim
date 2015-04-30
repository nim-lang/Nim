## libuv is still fast moving target
## This file was last updated against a development HEAD revision of https://github.com/joyent/libuv/

## Use the following link to see changes (in uv.h) since then and don't forget to update the information here.
## https://github.com/joyent/libuv/compare/9f6024a6fa9d254527b4b59af724257df870288b...master

when defined(Windows):
  import winlean
else:
  import posix

type
  TPort* = distinct int16  ## port type

  cssize = int
  coff = int
  csize = int

  AllocProc* = proc (handle: PHandle, suggested_size: csize): TBuf {.cdecl.}
  ReadProc* = proc (stream: PStream, nread: cssize, buf: TBuf) {.cdecl.}
  ReadProc2* = proc (stream: PPipe, nread: cssize, buf: TBuf, pending: THandleType) {.cdecl.}
  WriteProc* = proc (req: PWrite, status: cint) {.cdecl.}
  ConnectProc* = proc (req: PConnect, status: cint) {.cdecl.}
  ShutdownProc* = proc (req: PShutdown, status: cint) {.cdecl.}
  ConnectionProc* = proc (server: PStream, status: cint) {.cdecl.}
  CloseProc* = proc (handle: PHandle) {.cdecl.}
  TimerProc* = proc (handle: PTimer, status: cint) {.cdecl.}
  AsyncProc* = proc (handle: PAsync, status: cint) {.cdecl.}
  PrepareProc* = proc (handle: PPrepare, status: cint) {.cdecl.}
  CheckProc* = proc (handle: PCheck, status: cint) {.cdecl.}
  IdleProc* = proc (handle: PIdle, status: cint) {.cdecl.}

  PSockAddr* = ptr SockAddr

  GetAddrInfoProc* = proc (handle: PGetAddrInfo, status: cint, res: ptr AddrInfo)

  ExitProc* = proc (a2: PProcess, exit_status: cint, term_signal: cint)
  FsProc* = proc (req: PFS)
  WorkProc* = proc (req: PWork)
  AfterWorkProc* = proc (req: PWork)

  FsEventProc* = proc (handle: PFsEvent, filename: cstring, events: cint, status: cint)

  TErrorCode* {.size: sizeof(cint).} = enum
    UNKNOWN = - 1, OK = 0, EOF, EACCESS, EAGAIN, EADDRINUSE, EADDRNOTAVAIL,
    EAFNOSUPPORT, EALREADY, EBADF, EBUSY, ECONNABORTED, ECONNREFUSED,
    ECONNRESET, EDESTADDRREQ, EFAULT, EHOSTUNREACH, EINTR, EINVAL, EISCONN,
    EMFILE, EMSGSIZE, ENETDOWN, ENETUNREACH, ENFILE, ENOBUFS, ENOMEM, ENONET,
    ENOPROTOOPT, ENOTCONN, ENOTSOCK, ENOTSUP, ENOENT, EPIPE, EPROTO,
    EPROTONOSUPPORT, EPROTOTYPE, ETIMEDOUT, ECHARSET, EAIFAMNOSUPPORT,
    EAINONAME, EAISERVICE, EAISOCKTYPE, ESHUTDOWN, EEXIST

  THandleType* {.size: sizeof(cint).} = enum
    UNKNOWN_HANDLE = 0, TCP, UDP, NAMED_PIPE, TTY, FILE, TIMER, PREPARE, CHECK,
    IDLE, ASYNC, ARES_TASK, ARES_EVENT, PROCESS, FS_EVENT

  TReqType* {.size: sizeof(cint).} = enum
    rUNKNOWN_REQ = 0,
    rCONNECT,
    rACCEPT,
    rREAD,
    rWRITE,
    rSHUTDOWN,
    rWAKEUP,
    rUDP_SEND,
    rFS,
    rWORK,
    rGETADDRINFO,
    rREQ_TYPE_PRIVATE

  TErr* {.pure, final, importc: "uv_err_t", header: "uv.h".} = object
    code* {.importc: "code".}: TErrorCode
    sys_errno* {.importc: "sys_errno_".}: cint

  TFsEventType* = enum
    evRENAME = 1,
    evCHANGE = 2

  TFsEvent* {.pure, final, importc: "uv_fs_event_t", header: "uv.h".} = object
    loop* {.importc: "loop".}: PLoop
    typ* {.importc: "type".}: THandleType
    close_cb* {.importc: "close_cb".}: CloseProc
    data* {.importc: "data".}: pointer
    filename {.importc: "filename".}: cstring

  PFsEvent* = ptr TFsEvent

  TFsEvents* {.pure, final, importc: "uv_fs_event_t", header: "uv.h".} = object
    loop* {.importc: "loop".}: PLoop
    typ* {.importc: "type".}: THandleType
    close_cb* {.importc: "close_cb".}: CloseProc
    data* {.importc: "data".}: pointer
    filename* {.importc: "filename".}: cstring

  TBuf* {.pure, final, importc: "uv_buf_t", header: "uv.h"} = object
    base* {.importc: "base".}: cstring
    len* {.importc: "len".}: csize

  TAnyHandle* {.pure, final, importc: "uv_any_handle", header: "uv.h".} = object
    tcp* {.importc: "tcp".}: TTcp
    pipe* {.importc: "pipe".}: TPipe
    prepare* {.importc: "prepare".}: TPrepare
    check* {.importc: "check".}: TCheck
    idle* {.importc: "idle".}: TIdle
    async* {.importc: "async".}: TAsync
    timer* {.importc: "timer".}: TTimer
    getaddrinfo* {.importc: "getaddrinfo".}: TGetaddrinfo
    fs_event* {.importc: "fs_event".}: TFsEvents

  TAnyReq* {.pure, final, importc: "uv_any_req", header: "uv.h".} = object
    req* {.importc: "req".}: TReq
    write* {.importc: "write".}: TWrite
    connect* {.importc: "connect".}: TConnect
    shutdown* {.importc: "shutdown".}: TShutdown
    fs_req* {.importc: "fs_req".}: Tfs
    work_req* {.importc: "work_req".}: TWork

  ## better import this
  uint64 = int64

  TCounters* {.pure, final, importc: "uv_counters_t", header: "uv.h".} = object
    eio_init* {.importc: "eio_init".}: uint64
    req_init* {.importc: "req_init".}: uint64
    handle_init* {.importc: "handle_init".}: uint64
    stream_init* {.importc: "stream_init".}: uint64
    tcp_init* {.importc: "tcp_init".}: uint64
    udp_init* {.importc: "udp_init".}: uint64
    pipe_init* {.importc: "pipe_init".}: uint64
    tty_init* {.importc: "tty_init".}: uint64
    prepare_init* {.importc: "prepare_init".}: uint64
    check_init* {.importc: "check_init".}: uint64
    idle_init* {.importc: "idle_init".}: uint64
    async_init* {.importc: "async_init".}: uint64
    timer_init* {.importc: "timer_init".}: uint64
    process_init* {.importc: "process_init".}: uint64
    fs_event_init* {.importc: "fs_event_init".}: uint64

  TLoop* {.pure, final, importc: "uv_loop_t", header: "uv.h".} = object
    # ares_handles_* {.importc: "uv_ares_handles_".}: pointer # XXX: This seems to be a private field? 
    eio_want_poll_notifier* {.importc: "uv_eio_want_poll_notifier".}: TAsync
    eio_done_poll_notifier* {.importc: "uv_eio_done_poll_notifier".}: TAsync
    eio_poller* {.importc: "uv_eio_poller".}: TIdle
    counters* {.importc: "counters".}: TCounters
    last_err* {.importc: "last_err".}: TErr
    data* {.importc: "data".}: pointer

  PLoop* = ptr TLoop

  TShutdown* {.pure, final, importc: "uv_shutdown_t", header: "uv.h".} = object
    typ* {.importc: "type".}: TReqType
    data* {.importc: "data".}: pointer
    handle* {.importc: "handle".}: PStream
    cb* {.importc: "cb".}: ShutdownProc

  PShutdown* = ptr TShutdown

  THandle* {.pure, final, importc: "uv_handle_t", header: "uv.h".} = object
    loop* {.importc: "loop".}: PLoop
    typ* {.importc: "type".}: THandleType
    close_cb* {.importc: "close_cb".}: CloseProc
    data* {.importc: "data".}: pointer

  PHandle* = ptr THandle

  TStream* {.pure, final, importc: "uv_stream_t", header: "uv.h".} = object
    loop* {.importc: "loop".}: PLoop
    typ* {.importc: "type".}: THandleType
    alloc_cb* {.importc: "alloc_cb".}: AllocProc
    read_cb* {.importc: "read_cb".}: ReadProc
    read2_cb* {.importc: "read2_cb".}: ReadProc2
    close_cb* {.importc: "close_cb".}: CloseProc
    data* {.importc: "data".}: pointer
    write_queue_size* {.importc: "write_queue_size".}: csize

  PStream* = ptr TStream

  TWrite* {.pure, final, importc: "uv_write_t", header: "uv.h".} = object
    typ* {.importc: "type".}: TReqType
    data* {.importc: "data".}: pointer
    cb* {.importc: "cb".}: WriteProc
    send_handle* {.importc: "send_handle".}: PStream
    handle* {.importc: "handle".}: PStream

  PWrite* = ptr TWrite

  TTcp* {.pure, final, importc: "uv_tcp_t", header: "uv.h".} = object
    loop* {.importc: "loop".}: PLoop
    typ* {.importc: "type".}: THandleType
    alloc_cb* {.importc: "alloc_cb".}: AllocProc
    read_cb* {.importc: "read_cb".}: ReadProc
    read2_cb* {.importc: "read2_cb".}: ReadProc2
    close_cb* {.importc: "close_cb".}: CloseProc
    data* {.importc: "data".}: pointer
    write_queue_size* {.importc: "write_queue_size".}: csize

  PTcp* = ptr TTcp

  TConnect* {.pure, final, importc: "uv_connect_t", header: "uv.h".} = object
    typ* {.importc: "type".}: TReqType
    data* {.importc: "data".}: pointer
    cb* {.importc: "cb".}: ConnectProc
    handle* {.importc: "handle".}: PStream

  PConnect* = ptr TConnect

  TUdpFlags* = enum
    UDP_IPV6ONLY = 1, UDP_PARTIAL = 2

  ## XXX: better import this
  cunsigned = int

  UdpSendProc* = proc (req: PUdpSend, status: cint)
  UdpRecvProc* = proc (handle: PUdp, nread: cssize, buf: TBuf, adr: ptr SockAddr, flags: cunsigned)

  TUdp* {.pure, final, importc: "uv_udp_t", header: "uv.h".} = object
    loop* {.importc: "loop".}: PLoop
    typ* {.importc: "type".}: THandleType
    close_cb* {.importc: "close_cb".}: CloseProc
    data* {.importc: "data".}: pointer

  PUdp* = ptr TUdp

  TUdpSend* {.pure, final, importc: "uv_udp_send_t", header: "uv.h".} = object
    typ* {.importc: "type".}: TReqType
    data* {.importc: "data".}: pointer
    handle* {.importc: "handle".}: PUdp
    cb* {.importc: "cb".}: UdpSendProc

  PUdpSend* = ptr TUdpSend

  tTTy* {.pure, final, importc: "uv_tty_t", header: "uv.h".} = object
    loop* {.importc: "loop".}: PLoop
    typ* {.importc: "type".}: THandleType
    alloc_cb* {.importc: "alloc_cb".}: AllocProc
    read_cb* {.importc: "read_cb".}: ReadProc
    read2_cb* {.importc: "read2_cb".}: ReadProc2
    close_cb* {.importc: "close_cb".}: CloseProc
    data* {.importc: "data".}: pointer
    write_queue_size* {.importc: "write_queue_size".}: csize

  pTTy* = ptr tTTy

  TPipe* {.pure, final, importc: "uv_pipe_t", header: "uv.h".} = object
    loop* {.importc: "loop".}: PLoop
    typ* {.importc: "type".}: THandleType
    alloc_cb* {.importc: "alloc_cb".}: AllocProc
    read_cb* {.importc: "read_cb".}: ReadProc
    read2_cb* {.importc: "read2_cb".}: ReadProc2
    close_cb* {.importc: "close_cb".}: CloseProc
    data* {.importc: "data".}: pointer
    write_queue_size* {.importc: "write_queue_size".}: csize
    ipc {.importc: "ipc".}: int

  PPipe* = ptr TPipe

  TPrepare* {.pure, final, importc: "uv_prepare_t", header: "uv.h".} = object
    loop* {.importc: "loop".}: PLoop
    typ* {.importc: "type".}: THandleType
    close_cb* {.importc: "close_cb".}: CloseProc
    data* {.importc: "data".}: pointer

  PPrepare* = ptr TPrepare

  TCheck* {.pure, final, importc: "uv_check_t", header: "uv.h".} = object
    loop* {.importc: "loop".}: PLoop
    typ* {.importc: "type".}: THandleType
    close_cb* {.importc: "close_cb".}: CloseProc
    data* {.importc: "data".}: pointer

  PCheck* = ptr TCheck

  TIdle* {.pure, final, importc: "uv_idle_t", header: "uv.h".} = object
    loop* {.importc: "loop".}: PLoop
    typ* {.importc: "type".}: THandleType
    close_cb* {.importc: "close_cb".}: CloseProc
    data* {.importc: "data".}: pointer

  PIdle* = ptr TIdle

  TAsync* {.pure, final, importc: "uv_async_t", header: "uv.h".} = object
    loop* {.importc: "loop".}: PLoop
    typ* {.importc: "type".}: THandleType
    close_cb* {.importc: "close_cb".}: CloseProc
    data* {.importc: "data".}: pointer

  PAsync* = ptr TAsync

  TTimer* {.pure, final, importc: "uv_timer_t", header: "uv.h".} = object
    loop* {.importc: "loop".}: PLoop
    typ* {.importc: "type".}: THandleType
    close_cb* {.importc: "close_cb".}: CloseProc
    data* {.importc: "data".}: pointer

  PTimer* = ptr TTimer

  TGetAddrInfo* {.pure, final, importc: "uv_getaddrinfo_t", header: "uv.h".} = object
    typ* {.importc: "type".}: TReqType
    data* {.importc: "data".}: pointer
    loop* {.importc: "loop".}: PLoop

  PGetAddrInfo* = ptr TGetAddrInfo

  TProcessOptions* {.pure, final, importc: "uv_process_options_t", header: "uv.h".} = object
    exit_cb* {.importc: "exit_cb".}: ExitProc
    file* {.importc: "file".}: cstring
    args* {.importc: "args".}: cstringArray
    env* {.importc: "env".}: cstringArray
    cwd* {.importc: "cwd".}: cstring
    windows_verbatim_arguments* {.importc: "windows_verbatim_arguments".}: cint
    stdin_stream* {.importc: "stdin_stream".}: PPipe
    stdout_stream* {.importc: "stdout_stream".}: PPipe
    stderr_stream* {.importc: "stderr_stream".}: PPipe

  PProcessOptions* = ptr TProcessOptions

  TProcess* {.pure, final, importc: "uv_process_t", header: "uv.h".} = object
    loop* {.importc: "loop".}: PLoop
    typ* {.importc: "type".}: THandleType
    close_cb* {.importc: "close_cb".}: CloseProc
    data* {.importc: "data".}: pointer
    exit_cb* {.importc: "exit_cb".}: ExitProc
    pid* {.importc: "pid".}: cint

  PProcess* = ptr TProcess

  TWork* {.pure, final, importc: "uv_work_t", header: "uv.h".} = object
    typ* {.importc: "type".}: TReqType
    data* {.importc: "data".}: pointer
    loop* {.importc: "loop".}: PLoop
    work_cb* {.importc: "work_cb".}: WorkProc
    after_work_cb* {.importc: "after_work_cb".}: AfterWorkProc

  PWork* = ptr TWork

  TFsType* {.size: sizeof(cint).} = enum
    FS_UNKNOWN = - 1, FS_CUSTOM, FS_OPEN, FS_CLOSE, FS_READ, FS_WRITE,
    FS_SENDFILE, FS_STAT, FS_LSTAT, FS_FSTAT, FS_FTRUNCATE, FS_UTIME, FS_FUTIME,
    FS_CHMOD, FS_FCHMOD, FS_FSYNC, FS_FDATASYNC, FS_UNLINK, FS_RMDIR, FS_MKDIR,
    FS_RENAME, FS_READDIR, FS_LINK, FS_SYMLINK, FS_READLINK, FS_CHOWN, FS_FCHOWN

  TFS* {.pure, final, importc: "uv_fs_t", header: "uv.h".} = object
    typ* {.importc: "type".}: TReqType
    data* {.importc: "data".}: pointer
    loop* {.importc: "loop".}: PLoop
    fs_type* {.importc: "fs_type".}: TFsType
    cb* {.importc: "cb".}: FsProc
    result* {.importc: "result".}: cssize
    fsPtr* {.importc: "ptr".}: pointer
    path* {.importc: "path".}: cstring
    errorno* {.importc: "errorno".}: cint

  PFS* = ptr TFS

  TReq* {.pure, final, importc: "uv_req_t", header: "uv.h".} = object
    typ* {.importc: "type".}: TReqType
    data* {.importc: "data".}: pointer

  PReq* = ptr TReq

  TAresOptions* {.pure, final, importc: "ares_options", header: "uv.h".} = object
    flags* {.importc: "flags".}: int
    timeout* {.importc: "timeout".}: int
    tries* {.importc: "tries".}: int
    ndots* {.importc: "ndots".}: int
    udp_port* {.importc: "udp_port".}: TPort
    tcp_port* {.importc: "tcp_port".}: TPort
    socket_send_buffer_size* {.importc: "socket_send_buffer_size".}: int
    socket_recv_buffer_size* {.importc: "socket_receive_buffer_size".}: int
    servers* {.importc: "servers".}: ptr InAddr
    nservers* {.importc: "nservers".}: int
    domains* {.importc: "domains".}: ptr cstring
    ndomains* {.importc: "ndomains".}: int
    lookups* {.importc: "lookups".}: cstring

  #XXX: not yet exported
  #ares_sock_state_cb sock_state_cb;
  #void *sock_state_cb_data;
  #struct apattern *sortlist;
  #int nsort;

  PAresOptions* = ptr TAresOptions
  PAresChannel* = pointer

proc loop_new*(): PLoop{.
    importc: "uv_loop_new", header: "uv.h".}

proc loop_delete*(a2: PLoop){.
    importc: "uv_loop_delete", header: "uv.h".}

proc default_loop*(): PLoop{.
    importc: "uv_default_loop", header: "uv.h".}

proc run*(a2: PLoop): cint{.
    importc: "uv_run", header: "uv.h".}

proc addref*(a2: PLoop){.
    importc: "uv_ref", header: "uv.h".}

proc unref*(a2: PLoop){.
    importc: "uv_unref", header: "uv.h".}

proc update_time*(a2: PLoop){.
    importc: "uv_update_time", header: "uv.h".}

proc now*(a2: PLoop): int64{.
    importc: "uv_now", header: "uv.h".}

proc last_error*(a2: PLoop): TErr{.
    importc: "uv_last_error", header: "uv.h".}

proc strerror*(err: TErr): cstring{.
    importc: "uv_strerror", header: "uv.h".}

proc err_name*(err: TErr): cstring{.
    importc: "uv_err_name", header: "uv.h".}

proc shutdown*(req: PShutdown, handle: PStream, cb: ShutdownProc): cint{.
    importc: "uv_shutdown", header: "uv.h".}

proc is_active*(handle: PHandle): cint{.
    importc: "uv_is_active", header: "uv.h".}

proc close*(handle: PHandle, close_cb: CloseProc){.
    importc: "uv_close", header: "uv.h".}

proc buf_init*(base: cstring, len: csize): TBuf{.
    importc: "uv_buf_init", header: "uv.h".}

proc listen*(stream: PStream, backlog: cint, cb: ConnectionProc): cint{.
    importc: "uv_listen", header: "uv.h".}

proc accept*(server: PStream, client: PStream): cint{.
    importc: "uv_accept", header: "uv.h".}

proc read_start*(a2: PStream, alloc_cb: AllocProc, read_cb: ReadProc): cint{.
    importc: "uv_read_start", header: "uv.h".}

proc read_start*(a2: PStream, alloc_cb: AllocProc, read_cb: ReadProc2): cint{.
    importc: "uv_read2_start", header: "uv.h".}

proc read_stop*(a2: PStream): cint{.
    importc: "uv_read_stop", header: "uv.h".}

proc write*(req: PWrite, handle: PStream, bufs: ptr TBuf, bufcnt: cint, cb: WriteProc): cint{.
    importc: "uv_write", header: "uv.h".}

proc write*(req: PWrite, handle: PStream, bufs: ptr TBuf, bufcnt: cint, send_handle: PStream, cb: WriteProc): cint{.
    importc: "uv_write2", header: "uv.h".}

proc tcp_init*(a2: PLoop, handle: PTcp): cint{.
    importc: "uv_tcp_init", header: "uv.h".}

proc tcp_bind*(handle: PTcp, a3: SockAddrIn): cint{.
    importc: "uv_tcp_bind", header: "uv.h".}

proc tcp_bind6*(handle: PTcp, a3: TSockAddrIn6): cint{.
    importc: "uv_tcp_bind6", header: "uv.h".}

proc tcp_getsockname*(handle: PTcp, name: ptr SockAddr, namelen: var cint): cint{.
    importc: "uv_tcp_getsockname", header: "uv.h".}

proc tcp_getpeername*(handle: PTcp, name: ptr SockAddr, namelen: var cint): cint{.
    importc: "uv_tcp_getpeername", header: "uv.h".}

proc tcp_connect*(req: PConnect, handle: PTcp, address: SockAddrIn, cb: ConnectProc): cint{.
    importc: "uv_tcp_connect", header: "uv.h".}

proc tcp_connect6*(req: PConnect, handle: PTcp, address: TSockAddrIn6, cb: ConnectProc): cint{.
    importc: "uv_tcp_connect6", header: "uv.h".}

proc udp_init*(a2: PLoop, handle: PUdp): cint{.
    importc: "uv_udp_init", header: "uv.h".}

proc udp_bind*(handle: PUdp, adr: SockAddrIn, flags: cunsigned): cint{.
    importc: "uv_udp_bind", header: "uv.h".}

proc udp_bind6*(handle: PUdp, adr: TSockAddrIn6, flags: cunsigned): cint{.
    importc: "uv_udp_bind6", header: "uv.h".}

proc udp_getsockname*(handle: PUdp, name: ptr SockAddr, namelen: var cint): cint{.
    importc: "uv_udp_getsockname", header: "uv.h".}

proc udp_send*(req: PUdpSend, handle: PUdp, bufs: ptr TBuf, bufcnt: cint, adr: SockAddrIn, send_cb: UdpSendProc): cint{.
    importc: "uv_udp_send", header: "uv.h".}

proc udp_send6*(req: PUdpSend, handle: PUdp, bufs: ptr TBuf, bufcnt: cint, adr: TSockAddrIn6, send_cb: UdpSendProc): cint{.
    importc: "uv_udp_send6", header: "uv.h".}

proc udp_recv_start*(handle: PUdp, alloc_cb: AllocProc, recv_cb: UdpRecvProc): cint{.
    importc: "uv_udp_recv_start", header: "uv.h".}

proc udp_recv_stop*(handle: PUdp): cint{.
    importc: "uv_udp_recv_stop", header: "uv.h".}

proc tty_init*(a2: PLoop, a3: pTTy, fd: File): cint{.
    importc: "uv_tty_init", header: "uv.h".}

proc tty_set_mode*(a2: pTTy, mode: cint): cint{.
    importc: "uv_tty_set_mode", header: "uv.h".}

proc tty_get_winsize*(a2: pTTy, width: var cint, height: var cint): cint{.
    importc: "uv_tty_get_winsize", header: "uv.h".}

proc tty_reset_mode*() {.
    importc: "uv_tty_reset_mode", header: "uv.h".}

proc guess_handle*(file: File): THandleType{.
    importc: "uv_guess_handle", header: "uv.h".}

proc pipe_init*(a2: PLoop, handle: PPipe, ipc: int): cint{.
    importc: "uv_pipe_init", header: "uv.h".}

proc pipe_open*(a2: PPipe, file: File){.
    importc: "uv_pipe_open", header: "uv.h".}

proc pipe_bind*(handle: PPipe, name: cstring): cint{.
    importc: "uv_pipe_bind", header: "uv.h".}

proc pipe_connect*(req: PConnect, handle: PPipe, name: cstring, cb: ConnectProc): cint{.
    importc: "uv_pipe_connect", header: "uv.h".}

proc prepare_init*(a2: PLoop, prepare: PPrepare): cint{.
    importc: "uv_prepare_init", header: "uv.h".}

proc prepare_start*(prepare: PPrepare, cb: PrepareProc): cint{.
    importc: "uv_prepare_start", header: "uv.h".}

proc prepare_stop*(prepare: PPrepare): cint{.
    importc: "uv_prepare_stop", header: "uv.h".}

proc check_init*(a2: PLoop, check: PCheck): cint{.
    importc: "uv_check_init", header: "uv.h".}

proc check_start*(check: PCheck, cb: CheckProc): cint{.
    importc: "uv_check_start", header: "uv.h".}

proc check_stop*(check: PCheck): cint{.
    importc: "uv_check_stop", header: "uv.h".}

proc idle_init*(a2: PLoop, idle: PIdle): cint{.
    importc: "uv_idle_init", header: "uv.h".}

proc idle_start*(idle: PIdle, cb: IdleProc): cint{.
    importc: "uv_idle_start", header: "uv.h".}

proc idle_stop*(idle: PIdle): cint{.
    importc: "uv_idle_stop", header: "uv.h".}

proc async_init*(a2: PLoop, async: PAsync, async_cb: AsyncProc): cint{.
    importc: "uv_async_init", header: "uv.h".}

proc async_send*(async: PAsync): cint{.
    importc: "uv_async_send", header: "uv.h".}

proc timer_init*(a2: PLoop, timer: PTimer): cint{.
    importc: "uv_timer_init", header: "uv.h".}

proc timer_start*(timer: PTimer, cb: TimerProc, timeout: int64, repeat: int64): cint{.
    importc: "uv_timer_start", header: "uv.h".}

proc timer_stop*(timer: PTimer): cint{.
    importc: "uv_timer_stop", header: "uv.h".}

proc timer_again*(timer: PTimer): cint{.
    importc: "uv_timer_again", header: "uv.h".}

proc timer_set_repeat*(timer: PTimer, repeat: int64){.
    importc: "uv_timer_set_repeat", header: "uv.h".}

proc timer_get_repeat*(timer: PTimer): int64{.
    importc: "uv_timer_get_repeat", header: "uv.h".}

proc ares_init_options*(a2: PLoop, channel: PAresChannel, options: PAresOptions, optmask: cint): cint{.
    importc: "uv_ares_init_options", header: "uv.h".}

proc ares_destroy*(a2: PLoop, channel: PAresChannel){.
    importc: "uv_ares_destroy", header: "uv.h".}

proc getaddrinfo*(a2: PLoop, handle: PGetAddrInfo,getaddrinfo_cb: GetAddrInfoProc, node: cstring, service: cstring, hints: ptr AddrInfo): cint{.
    importc: "uv_getaddrinfo", header: "uv.h".}

proc freeaddrinfo*(ai: ptr AddrInfo){.
    importc: "uv_freeaddrinfo", header: "uv.h".}

proc spawn*(a2: PLoop, a3: PProcess, options: TProcessOptions): cint{.
    importc: "uv_spawn", header: "uv.h".}

proc process_kill*(a2: PProcess, signum: cint): cint{.
    importc: "uv_process_kill", header: "uv.h".}

proc queue_work*(loop: PLoop, req: PWork, work_cb: WorkProc, after_work_cb: AfterWorkProc): cint{.
    importc: "uv_queue_work", header: "uv.h".}

proc req_cleanup*(req: PFS){.
    importc: "uv_fs_req_cleanup", header: "uv.h".}

proc close*(loop: PLoop, req: PFS, file: File, cb: FsProc): cint{.
    importc: "uv_fs_close", header: "uv.h".}

proc open*(loop: PLoop, req: PFS, path: cstring, flags: cint, mode: cint, cb: FsProc): cint{.
    importc: "uv_fs_open", header: "uv.h".}

proc read*(loop: PLoop, req: PFS, file: File, buf: pointer, length: csize, offset: coff, cb: FsProc): cint{.
    importc: "uv_fs_read", header: "uv.h".}

proc unlink*(loop: PLoop, req: PFS, path: cstring, cb: FsProc): cint{.
    importc: "uv_fs_unlink", header: "uv.h".}

proc write*(loop: PLoop, req: PFS, file: File, buf: pointer, length: csize, offset: coff, cb: FsProc): cint{.
    importc: "uv_fs_write", header: "uv.h".}

proc mkdir*(loop: PLoop, req: PFS, path: cstring, mode: cint, cb: FsProc): cint{.
    importc: "uv_fs_mkdir", header: "uv.h".}

proc rmdir*(loop: PLoop, req: PFS, path: cstring, cb: FsProc): cint{.
    importc: "uv_fs_rmdir", header: "uv.h".}

proc readdir*(loop: PLoop, req: PFS, path: cstring, flags: cint, cb: FsProc): cint{.
    importc: "uv_fs_readdir", header: "uv.h".}

proc stat*(loop: PLoop, req: PFS, path: cstring, cb: FsProc): cint{.
    importc: "uv_fs_stat", header: "uv.h".}

proc fstat*(loop: PLoop, req: PFS, file: File, cb: FsProc): cint{.
    importc: "uv_fs_fstat", header: "uv.h".}

proc rename*(loop: PLoop, req: PFS, path: cstring, new_path: cstring, cb: FsProc): cint{.
    importc: "uv_fs_rename", header: "uv.h".}

proc fsync*(loop: PLoop, req: PFS, file: File, cb: FsProc): cint{.
    importc: "uv_fs_fsync", header: "uv.h".}

proc fdatasync*(loop: PLoop, req: PFS, file: File, cb: FsProc): cint{.
    importc: "uv_fs_fdatasync", header: "uv.h".}

proc ftruncate*(loop: PLoop, req: PFS, file: File, offset: coff, cb: FsProc): cint{.
    importc: "uv_fs_ftruncate", header: "uv.h".}

proc sendfile*(loop: PLoop, req: PFS, out_fd: File, in_fd: File, in_offset: coff, length: csize, cb: FsProc): cint{.
    importc: "uv_fs_sendfile", header: "uv.h".}

proc chmod*(loop: PLoop, req: PFS, path: cstring, mode: cint, cb: FsProc): cint{.
    importc: "uv_fs_chmod", header: "uv.h".}

proc utime*(loop: PLoop, req: PFS, path: cstring, atime: cdouble, mtime: cdouble, cb: FsProc): cint{.
    importc: "uv_fs_utime", header: "uv.h".}

proc futime*(loop: PLoop, req: PFS, file: File, atime: cdouble, mtime: cdouble, cb: FsProc): cint{.
    importc: "uv_fs_futime", header: "uv.h".}

proc lstat*(loop: PLoop, req: PFS, path: cstring, cb: FsProc): cint{.
    importc: "uv_fs_lstat", header: "uv.h".}

proc link*(loop: PLoop, req: PFS, path: cstring, new_path: cstring, cb: FsProc): cint{.
    importc: "uv_fs_link", header: "uv.h".}

proc symlink*(loop: PLoop, req: PFS, path: cstring, new_path: cstring, flags: cint, cb: FsProc): cint{.
    importc: "uv_fs_symlink", header: "uv.h".}

proc readlink*(loop: PLoop, req: PFS, path: cstring, cb: FsProc): cint{.
    importc: "uv_fs_readlink", header: "uv.h".}

proc fchmod*(loop: PLoop, req: PFS, file: File, mode: cint, cb: FsProc): cint{.
    importc: "uv_fs_fchmod", header: "uv.h".}

proc chown*(loop: PLoop, req: PFS, path: cstring, uid: cint, gid: cint, cb: FsProc): cint{.
    importc: "uv_fs_chown", header: "uv.h".}

proc fchown*(loop: PLoop, req: PFS, file: File, uid: cint, gid: cint, cb: FsProc): cint{.
    importc: "uv_fs_fchown", header: "uv.h".}

proc event_init*(loop: PLoop, handle: PFSEvent, filename: cstring, cb: FsEventProc): cint{.
    importc: "uv_fs_event_init", header: "uv.h".}

proc ip4_addr*(ip: cstring, port: cint): SockAddrIn{.
    importc: "uv_ip4_addr", header: "uv.h".}

proc ip6_addr*(ip: cstring, port: cint): TSockAddrIn6{.
    importc: "uv_ip6_addr", header: "uv.h".}

proc ip4_name*(src: ptr SockAddrIn, dst: cstring, size: csize): cint{.
    importc: "uv_ip4_name", header: "uv.h".}

proc ip6_name*(src: ptr TSockAddrIn6, dst: cstring, size: csize): cint{.
    importc: "uv_ip6_name", header: "uv.h".}

proc exepath*(buffer: cstring, size: var csize): cint{.
    importc: "uv_exepath", header: "uv.h".}

proc hrtime*(): uint64{.
    importc: "uv_hrtime", header: "uv.h".}

proc loadavg*(load: var array[0..2, cdouble]) {.
    importc: "uv_loadavg", header: "uv.h"}

proc get_free_memory*(): cdouble {.
    importc: "uv_get_free_memory", header: "uv.h".}

proc get_total_memory*(): cdouble {.
    importc: "uv_get_total_memory", header: "uv.h".}

