proc `'ns`*(num: string): TimeInterval {.inline.} =
  ## Custom numeric literal for a TimeInterval of `num` nanoseconds (10^−9 seconds).
  runnableExamples:
    assert 19'ns == initTimeInterval(nanoseconds = 19)
    assert 1000_000_000'ns == 1'seconds
  nanoseconds(parseInt(num))

proc `'us`*(num: string): TimeInterval {.inline.} =
  ## Custom numeric literal for a TimeInterval of `num` microseconds (10^−6 seconds).
  runnableExamples:
    assert 3'us == initTimeInterval(microseconds = 3)
    assert 1000_000'us == 1'seconds
  microseconds(parseInt(num))

proc `'ms`*(num: string): TimeInterval {.inline.} =
  ## Custom numeric literal for a TimeInterval of `num` milliseconds (10^−3 seconds).
  runnableExamples:
    assert 11'ms == initTimeInterval(milliseconds = 11)
    assert 1000'ms == 1'seconds
  milliseconds(parseInt(num))

proc `'seconds`*(num: string): TimeInterval {.inline.} =
  ## Custom numeric literal for a TimeInterval of `num` seconds.
  runnableExamples:
    assert 2'seconds == initTimeInterval(seconds = 2)
    assert 60'seconds == 1'minutes
  seconds(parseInt(num))

proc `'minutes`*(num: string): TimeInterval {.inline.} =
  ## Custom numeric literal for a TimeInterval of `num` minutes.
  runnableExamples:
    assert 13'minutes == initTimeInterval(minutes = 13)
    assert 60'minutes == 1'hours
  minutes(parseInt(num))

proc `'hours`*(num: string): TimeInterval {.inline.} =
  ## Custom numeric literal for a TimeInterval of `num` hours.
  runnableExamples:
    assert 17'hours == initTimeInterval(hours = 17)
    assert 24'hours == 1'days
  hours(parseInt(num))

proc `'days`*(num: string): TimeInterval {.inline.} =
  ## Custom numeric literal for a TimeInterval of `num` days.
  runnableExamples:
    assert 5'days == initTimeInterval(days = 5)
    assert 7'days == 1'weeks
  days(parseInt(num))

proc `'weeks`*(num: string): TimeInterval {.inline.} =
  ## Custom numeric literal for a TimeInterval of `num` weeks.
  runnableExamples:
    assert 19'weeks == initTimeInterval(weeks = 19)
    assert 1'weeks == 7'days
  weeks(parseInt(num))
