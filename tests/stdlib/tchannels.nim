discard """
  timeout:  60.0 # but typically < 1s (in isolation but other tests running in parallel can affect this since based on epochTime)
  disabled: "freebsd"
  matrix: "--gc:arc --threads:on; --gc:arc --threads:on -d:danger"
"""

when true:
  # bug #17380: this was either blocking (without -d:danger) or crashing with SIGSEGV (with -d:danger)
  import std/[channels, isolation]
  const
    N1 = 10
    N2 = 100
  var
    sender: array[N1, Thread[void]]
    receiver: array[5, Thread[void]] 

  var chan = newChannel[seq[string]](N1 * N2) # large enough to not block
  proc sendHandler() =
    chan.send(isolate(@["Hello, Nim"]))
  proc recvHandler() =
    template fn =
      let x = chan.recv()
    fn()

  template benchmark() =
    for t in mitems(sender):
      t.createThread(sendHandler)
    joinThreads(sender)
    for t in mitems(receiver):
      t.createThread(recvHandler)
    joinThreads(receiver)
  for i in 0..<N2:
    benchmark()
