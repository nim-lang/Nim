import mfakeassert

func rereplace*(s, sub: string; by: string = ""): string {.used.} =
  ## competes for priority in suggestion, here first, but never used in test

  fakeAssert(true, "always works")
  result = by

func replace*(s, sub: string; by: string = ""): string =
  ## this is a test version of strutils.replace, it simply returns `by`

  fakeAssert("".len == 0, "empty string is empty")
  result = by

func rerereplace*(s, sub: string; by: string = ""): string {.used.} =
  ## isn't used and appears last, lowest priority

  fakeAssert(false, "never works")
  result = by
