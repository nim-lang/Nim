proc `'ns`*(num: string): TimeInterval {.inline.} =
  ## Custom numeric literal for a TimeInterval of `num` nanoseconds (10^−9 seconds).
  runnableExamples:
    assert 19'ns == initTimeInterval(nanoseconds = 19)
    assert 1000_000_000'ns == 1's
  nanoseconds(parseInt(num))

proc `'us`*(num: string): TimeInterval {.inline.} =
  ## Custom numeric literal for a TimeInterval of `num` microseconds (10^−6 seconds).
  runnableExamples:
    assert 3'us == initTimeInterval(microseconds = 3)
    assert 1000_000'us == 1's
  microseconds(parseInt(num))

proc `'ms`*(num: string): TimeInterval {.inline.} =
  ## Custom numeric literal for a TimeInterval of `num` milliseconds (10^−3 seconds).
  runnableExamples:
    assert 11'ms == initTimeInterval(milliseconds = 11)
    assert 1000'ms == 1's
  milliseconds(parseInt(num))

proc `'seconds`*(num: string): TimeInterval {.inline.} =
  ## Custom numeric literal for a TimeInterval of `num` seconds.
  runnableExamples:
    assert 2's == initTimeInterval(seconds = 2)
    assert 60's == 1'min
  seconds(parseInt(num))

proc `'minutes`*(num: string): TimeInterval {.inline.} =
  ## Custom numeric literal for a TimeInterval of `num` minutes.
  runnableExamples:
    assert 13'min == initTimeInterval(minutes = 13)
    assert 60'min == 1'hour
  minutes(parseInt(num))

proc `'hours`*(num: string): TimeInterval {.inline.} =
  ## Custom numeric literal for a TimeInterval of `num` hours.
  runnableExamples:
    assert 17'hour == initTimeInterval(hours = 17)
    assert 24'hour == 1'day
  hours(parseInt(num))

proc `'days`*(num: string): TimeInterval {.inline.} =
  ## Custom numeric literal for a TimeInterval of `num` days.
  runnableExamples:
    assert 5'day == initTimeInterval(days = 5)
    assert 7'day == 1'week
  days(parseInt(num))

proc `'weeks`*(num: string): TimeInterval {.inline.} =
  ## Custom numeric literal for a TimeInterval of `num` weeks.
  runnableExamples:
    assert 19'week == initTimeInterval(weeks = 19)
  weeks(parseInt(num))
