discard """
  file: "tioselectors.nim"
  output: "All tests passed!"
"""
import ioselectors

const hasThreadSupport = compileOption("threads")

template processTest(t, x: untyped) =
  #stdout.write(t)
  #stdout.flushFile()
  if not x: echo(t & " FAILED\r\n")

when not defined(windows):
  import os, posix, osproc, nativesockets, times

  const supportedPlatform = defined(macosx) or defined(freebsd) or
                            defined(netbsd) or defined(openbsd) or
                            defined(linux)

  proc socket_notification_test(): bool =
    proc create_test_socket(): SocketHandle =
      var sock = posix.socket(posix.AF_INET, posix.SOCK_STREAM,
                              posix.IPPROTO_TCP)
      var x: int = fcntl(sock, F_GETFL, 0)
      if x == -1: raiseOSError(osLastError())
      else:
        var mode = x or O_NONBLOCK
        if fcntl(sock, F_SETFL, mode) == -1:
          raiseOSError(osLastError())
      result = sock

    var client_message = "SERVER HELLO =>"
    var server_message = "CLIENT HELLO"
    var buffer : array[128, char]

    var selector = newSelector[int]()
    var client_socket = create_test_socket()
    var server_socket = create_test_socket()

    registerHandle(selector, server_socket, {Event.Read}, 0)
    registerHandle(selector, client_socket, {Event.Write}, 0)

    var option : int32 = 1
    if setsockopt(server_socket, cint(SOL_SOCKET), cint(SO_REUSEADDR),
                  addr(option), sizeof(option).SockLen) < 0:
      raiseOSError(osLastError())

    var aiList = getAddrInfo("0.0.0.0", Port(13337))
    if bindAddr(server_socket, aiList.ai_addr,
                aiList.ai_addrlen.Socklen) < 0'i32:
      dealloc(aiList)
      raiseOSError(osLastError())
    discard server_socket.listen()
    dealloc(aiList)

    aiList = getAddrInfo("127.0.0.1", Port(13337))
    discard posix.connect(client_socket, aiList.ai_addr,
                          aiList.ai_addrlen.Socklen)
    dealloc(aiList)
    var rc1 = selector.select(100)
    assert(len(rc1) == 2)

    var sockAddress: SockAddr
    var addrLen = sizeof(sockAddress).Socklen
    var server2_socket = accept(server_socket,
                                cast[ptr SockAddr](addr(sockAddress)),
                                addr(addrLen))
    assert(server2_socket != osInvalidSocket)
    selector.registerHandle(server2_socket, {Event.Read}, 0)

    if posix.send(client_socket, addr(client_message[0]),
                  len(client_message), 0) == -1:
      raiseOSError(osLastError())

    selector.updateHandle(client_socket, {Event.Read})

    var rc2 = selector.select(100)
    assert(len(rc2) == 1)

    var read_count = posix.recv(server2_socket, addr (buffer[0]), 128, 0)
    if read_count == -1:
      raiseOSError(osLastError())

    assert(read_count == len(client_message))
    var test1 = true
    for i in 0..<read_count:
      if client_message[i] != buffer[i]:
        test1 = false
        break
    assert(test1)

    selector.updateHandle(server2_socket, {Event.Write})
    var rc3 = selector.select(0)
    assert(len(rc3) == 1)
    if posix.send(server2_socket, addr(server_message[0]),
                  len(server_message), 0) == -1:
      raiseOSError(osLastError())
    selector.updateHandle(server2_socket, {Event.Read})

    var rc4 = selector.select(100)
    assert(len(rc4) == 1)
    read_count = posix.recv(client_socket, addr(buffer[0]), 128, 0)
    if read_count == -1:
      raiseOSError(osLastError())

    assert(read_count == len(server_message))
    var test2 = true
    for i in 0..<read_count:
      if server_message[i] != buffer[i]:
        test2 = false
        break
    assert(test2)

    selector.unregister(server_socket)
    selector.unregister(server2_socket)
    selector.unregister(client_socket)
    discard posix.close(server_socket)
    discard posix.close(server2_socket)
    discard posix.close(client_socket)
    assert(selector.isEmpty())
    close(selector)
    result = true

  proc event_notification_test(): bool =
    var selector = newSelector[int]()
    var event = newSelectEvent()
    selector.registerEvent(event, 1)
    selector.flush()
    event.setEvent()
    var rc1 = selector.select(0)
    event.setEvent()
    var rc2 = selector.select(0)
    var rc3 = selector.select(0)
    assert(len(rc1) == 1 and len(rc2) == 1 and len(rc3) == 0)
    var ev1 = rc1[0].data
    var ev2 = rc2[0].data
    assert(ev1 == 1 and ev2 == 1)
    selector.unregister(event)
    event.close()
    assert(selector.isEmpty())
    selector.close()
    result = true

  when supportedPlatform:
    proc timer_notification_test(): bool =
      var selector = newSelector[int]()
      var timer = selector.registerTimer(100, false, 0)
      var rc1 = selector.select(140)
      var rc2 = selector.select(140)
      assert(len(rc1) == 1 and len(rc2) == 1)
      selector.unregister(timer)
      selector.flush()
      selector.registerTimer(100, true, 0)
      var rc3 = selector.select(120)
      var rc4 = selector.select(120)
      assert(len(rc3) == 1 and len(rc4) == 0)
      assert(selector.isEmpty())
      selector.close()
      result = true

    proc process_notification_test(): bool =
      var selector = newSelector[int]()
      var process2 = startProcess("/bin/sleep", "", ["2"], nil,
                           {poStdErrToStdOut, poUsePath})
      discard startProcess("/bin/sleep", "", ["1"], nil,
                           {poStdErrToStdOut, poUsePath})

      selector.registerProcess(process2.processID, 0)
      var rc1 = selector.select(1500)
      var rc2 = selector.select(1500)
      var r = len(rc1) + len(rc2)
      assert(r == 1)
      result = true

    proc signal_notification_test(): bool =
      var sigset1n, sigset1o, sigset2n, sigset2o: Sigset
      var pid = posix.getpid()

      discard sigemptyset(sigset1n)
      discard sigemptyset(sigset1o)
      discard sigemptyset(sigset2n)
      discard sigemptyset(sigset2o)

      when hasThreadSupport:
        if pthread_sigmask(SIG_BLOCK, sigset1n, sigset1o) == -1:
          raiseOSError(osLastError())
      else:
        if sigprocmask(SIG_BLOCK, sigset1n, sigset1o) == -1:
          raiseOSError(osLastError())

      var selector = newSelector[int]()
      var s1 = selector.registerSignal(SIGUSR1, 1)
      var s2 = selector.registerSignal(SIGUSR2, 2)
      var s3 = selector.registerSignal(SIGTERM, 3)
      selector.flush()

      discard posix.kill(pid, SIGUSR1)
      discard posix.kill(pid, SIGUSR2)
      discard posix.kill(pid, SIGTERM)
      var rc = selector.select(0)
      selector.unregister(s1)
      selector.unregister(s2)
      selector.unregister(s3)

      when hasThreadSupport:
        if pthread_sigmask(SIG_BLOCK, sigset2n, sigset2o) == -1:
          raiseOSError(osLastError())
      else:
        if sigprocmask(SIG_BLOCK, sigset2n, sigset2o) == -1:
          raiseOSError(osLastError())

      assert(len(rc) == 3)
      assert(rc[0].data + rc[1].data + rc[2].data == 6) # 1 + 2 + 3
      assert(equalMem(addr sigset1o, addr sigset2o, sizeof(Sigset)))
      assert(selector.isEmpty())
      result = true

  when hasThreadSupport:

    var counter = 0

    proc event_wait_thread(event: SelectEvent) {.thread.} =
      var selector = newSelector[int]()
      selector.registerEvent(event, 1)
      selector.flush()
      var rc = selector.select(1000)
      if len(rc) == 1:
        inc(counter)
      selector.unregister(event)
      assert(selector.isEmpty())

    proc mt_event_test(): bool =
      var
        thr: array [0..7, Thread[SelectEvent]]
      var selector = newSelector[int]()
      var sock = newNativeSocket()
      var event = newSelectEvent()
      for i in 0..high(thr):
        createThread(thr[i], event_wait_thread, event)
      selector.registerHandle(sock, {Event.Read}, 1)
      discard selector.select(500)
      selector.unregister(sock)
      event.setEvent()
      joinThreads(thr)
      assert(counter == 1)
      result = true

  processTest("Socket notification test...", socket_notification_test())
  processTest("User event notification test...", event_notification_test())
  when hasThreadSupport:
    processTest("Multithreaded user event notification test...",
                mt_event_test())
  when supportedPlatform:
    processTest("Timer notification test...", timer_notification_test())
    processTest("Process notification test...", process_notification_test())
    processTest("Signal notification test...", signal_notification_test())
  echo("All tests passed!")
else:
  import nativesockets, winlean, os, osproc

  proc socket_notification_test(): bool =
    proc create_test_socket(): SocketHandle =
      var sock = newNativeSocket()
      setBlocking(sock, false)
      result = sock

    var client_message = "SERVER HELLO =>"
    var server_message = "CLIENT HELLO"
    var buffer : array[128, char]

    var selector = newSelector[int]()
    var client_socket = create_test_socket()
    var server_socket = create_test_socket()

    selector.registerHandle(server_socket, {Event.Read}, 0)
    selector.registerHandle(client_socket, {Event.Write}, 0)

    var option : int32 = 1
    if setsockopt(server_socket, cint(SOL_SOCKET), cint(SO_REUSEADDR),
                  addr(option), sizeof(option).SockLen) < 0:
      raiseOSError(osLastError())

    var aiList = getAddrInfo("0.0.0.0", Port(13337))
    if bindAddr(server_socket, aiList.ai_addr,
                aiList.ai_addrlen.Socklen) < 0'i32:
      dealloc(aiList)
      raiseOSError(osLastError())
    discard server_socket.listen()
    dealloc(aiList)

    aiList = getAddrInfo("127.0.0.1", Port(13337))
    discard connect(client_socket, aiList.ai_addr,
                    aiList.ai_addrlen.Socklen)
    dealloc(aiList)
    # for some reason Windows select doesn't return both
    # descriptors from first call, so we need to make 2 calls
    discard selector.select(100)
    var rcm = selector.select(100)
    assert(len(rcm) == 2)

    var sockAddress = SockAddr()
    var addrLen = sizeof(sockAddress).Socklen
    var server2_socket = accept(server_socket,
                                cast[ptr SockAddr](addr(sockAddress)),
                                addr(addrLen))
    assert(server2_socket != osInvalidSocket)
    selector.registerHandle(server2_socket, {Event.Read}, 0)

    if send(client_socket, cast[pointer](addr(client_message[0])),
            cint(len(client_message)), 0) == -1:
      raiseOSError(osLastError())

    selector.updateHandle(client_socket, {Event.Read})

    var rc2 = selector.select(100)
    assert(len(rc2) == 1)

    var read_count = recv(server2_socket, addr (buffer[0]), 128, 0)
    if read_count == -1:
      raiseOSError(osLastError())

    assert(read_count == len(client_message))
    var test1 = true
    for i in 0..<read_count:
      if client_message[i] != buffer[i]:
        test1 = false
        break
    assert(test1)

    if send(server2_socket, cast[pointer](addr(server_message[0])),
                  cint(len(server_message)), 0) == -1:
      raiseOSError(osLastError())

    var rc3 = selector.select(0)
    assert(len(rc3) == 1)
    read_count = recv(client_socket, addr(buffer[0]), 128, 0)
    if read_count == -1:
      raiseOSError(osLastError())

    assert(read_count == len(server_message))
    var test2 = true
    for i in 0..<read_count:
      if server_message[i] != buffer[i]:
        test2 = false
        break
    assert(test2)

    selector.unregister(server_socket)
    selector.unregister(server2_socket)
    selector.unregister(client_socket)
    close(server_socket)
    close(server2_socket)
    close(client_socket)
    assert(selector.isEmpty())
    close(selector)
    result = true

  proc event_notification_test(): bool =
    var selector = newSelector[int]()
    var event = newSelectEvent()
    selector.registerEvent(event, 1)
    selector.flush()
    event.setEvent()
    var rc1 = selector.select(0)
    event.setEvent()
    var rc2 = selector.select(0)
    var rc3 = selector.select(0)
    assert(len(rc1) == 1 and len(rc2) == 1 and len(rc3) == 0)
    var ev1 = rc1[0].data
    var ev2 = rc2[0].data
    assert(ev1 == 1 and ev2 == 1)
    selector.unregister(event)
    event.close()
    assert(selector.isEmpty())
    selector.close()
    result = true

  when hasThreadSupport:
    var counter = 0

    proc event_wait_thread(event: SelectEvent) {.thread.} =
      var selector = newSelector[int]()
      selector.registerEvent(event, 1)
      selector.flush()
      var rc = selector.select(500)
      if len(rc) == 1:
        inc(counter)
      selector.unregister(event)
      assert(selector.isEmpty())

    proc mt_event_test(): bool =
      var thr: array [0..7, Thread[SelectEvent]]
      var event = newSelectEvent()
      for i in 0..high(thr):
        createThread(thr[i], event_wait_thread, event)
      event.setEvent()
      joinThreads(thr)
      assert(counter == 1)
      result = true

  processTest("Socket notification test...", socket_notification_test())
  processTest("User event notification test...", event_notification_test())
  when hasThreadSupport:
    processTest("Multithreaded user event notification test...",
                 mt_event_test())
  echo("All tests passed!")
