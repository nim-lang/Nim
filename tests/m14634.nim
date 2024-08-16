#[
Tool to investigate underlying reasons for https://github.com/nim-lang/Nim/pull/14634
nim r --threads:on -d:threadsafe tests/m14634.nim
]#

when not defined(windows):
  import std/selectors

  type TestData = object
    s1, s2, s3: int

  proc timerNotificationTestImpl(data: var TestData) =
    var selector = newSelector[int]()
    let t0 = 5
    var timer = selector.registerTimer(t0, false, 0)
    let t = 2000
      # values too close to `t0` cause the test to be flaky in CI on OSX+freebsd
      # When running locally, t0=100, t=98 will succeed some of the time which indicates
      # there is some lag involved. Note that the higher `t-t0` is, the less times
      # the test fails.
    var rc1 = selector.select(t)
    var rc2 = selector.select(t)
    doAssert len(rc1) <= 1 and len(rc2) <= 1
    data.s1 += ord(len(rc1) == 1)
    data.s2 += ord(len(rc2) == 1)
    selector.unregister(timer)
    discard selector.select(0)
    selector.registerTimer(t0, true, 0)
      # same comment as above
    var rc4 = selector.select(t)
    let t2 = 100
      # this can't be too large as it'll actually wait that long:
      # timer_notification_test.n * t2
    var rc5 = selector.select(t2)
    doAssert len(rc4) + len(rc5) <= 1
    data.s3 += ord(len(rc4) + len(rc5) == 1)
    doAssert(selector.isEmpty())
    selector.close()

  proc timerNotificationTest() =
    var data: TestData
    let n = 10
    for i in 0..<n:
      timerNotificationTestImpl(data)
    doAssert data.s1 == n and data.s2 == n and data.s3 == n, $data

  when isMainModule:
    timerNotificationTest()
