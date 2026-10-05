{.experimental: "openSym".}

import std/hashes

template maxHash(t): untyped = high(t).Hash

template implCaptured() {.dirty.} =
  result = maxHash(t)

template implInjected() {.dirty.} =
  type Hash = uint8
  result = high(t).Hash

proc usesCaptured*[T](t: T): auto =
  implCaptured()

proc usesInjected*[T](t: T): auto =
  implInjected()
