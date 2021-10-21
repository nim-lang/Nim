proc `'ns`*(num: string): Duration {.inline.} =
  runnableExamples:
    assert 19'ns == initDuration(nanoseconds = 19)
    assert 1000_000_000'ns == 1's
  initDuration(nanoseconds = parseInt(num))

proc `'us`*(num: string): Duration {.inline.} =
  runnableExamples:
    assert 3'us == initDuration(microseconds = 3)
    assert 1000_000'us == 1's
  initDuration(microseconds = parseInt(num))

proc `'ms`*(num: string): Duration {.inline.} =
  runnableExamples:
    assert 11'ms == initDuration(milliseconds = 11)
    assert 1000'ms == 1's
  initDuration(milliseconds = parseInt(num))

proc `'s`*(num: string): Duration {.inline.} =
  runnableExamples:
    assert 2's == initDuration(seconds = 2)
    assert 60's == 1'min
  initDuration(seconds = parseInt(num))

proc `'min`*(num: string): Duration {.inline.} =
  runnableExamples:
    assert 13'min == initDuration(minutes = 13)
    assert 60'min == 1'hour
  initDuration(minutes = parseInt(num))

proc `'hour`*(num: string): Duration {.inline.} =
  runnableExamples:
    assert 17'hour == initDuration(hours = 17)
    assert 24'hour == 1'day
  initDuration(hours = parseInt(num))

proc `'day`*(num: string): Duration {.inline.} =
  runnableExamples:
    assert 5'day == initDuration(days = 5)
    assert 7'day == 1'week
  initDuration(days = parseInt(num))

proc `'week`*(num: string): Duration {.inline.} =
  runnableExamples:
    assert 19'week == initDuration(weeks = 19)
  initDuration(weeks = parseInt(num))
