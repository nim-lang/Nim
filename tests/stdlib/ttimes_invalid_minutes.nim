# Regression tests for out-of-range minute values in std/times.parse.
# Before the fix, the parser checks parsed.hour instead of parsed.minute,
# allowing invalid minutes to reach DateTime construction as a RangeDefect.

import std/[times, unittest]

suite "times.parse validates minute ranges":
  test "valid minute boundaries for mm":
    check parse("2026-10-17 12:00", "yyyy-MM-dd HH:mm", utc()).minute == 0
    check parse("2026-10-17 12:59", "yyyy-MM-dd HH:mm", utc()).minute == 59

  test "valid minute boundaries for m":
    check parse("2026-10-17 12:0", "yyyy-MM-dd HH:m", utc()).minute == 0
    check parse("2026-10-17 12:59", "yyyy-MM-dd HH:m", utc()).minute == 59

  test "mm rejects minute 60 with TimeParseError":
    expect TimeParseError:
      discard parse("2026-10-17 12:60", "yyyy-MM-dd HH:mm", utc())

  test "mm rejects minute 99 with TimeParseError":
    expect TimeParseError:
      discard parse("2026-10-17 12:99", "yyyy-MM-dd HH:mm", utc())

  test "m rejects minute 60 with TimeParseError":
    expect TimeParseError:
      discard parse("2026-10-17 12:60", "yyyy-MM-dd HH:m", utc())

  test "m rejects minute 99 with TimeParseError":
    expect TimeParseError:
      discard parse("2026-10-17 12:99", "yyyy-MM-dd HH:m", utc())
