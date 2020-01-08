proc `$`(t: typedesc): string {.magic: "TypeTrait".}

proc newImpl[T](a: var ref T) {.magic: "New", noSideEffect.}

type SysCounter* = object
  name*: cstring
  size*: int
  nameLen*: int
  count*: int

var sysCounters*: array[1000, SysCounter]
var sysCountersLen* = 0

proc new*[T](a: var ref T) {.noSideEffect.} =
  ## we avoid allocations, do everything on stack

  # TODO: how do get a unique hash (in case of name collisions for different types T)
  const name = $T
  var i2 = 0
  {.noSideEffect.}:
    while true:
      if i2 == sysCountersLen:
        sysCounters[sysCountersLen] = SysCounter(name: name.cstring, nameLen: name.len, size: T.sizeof)
        if sysCountersLen < sysCounters.len - 1:
          sysCountersLen.inc
        break

      var ok = true
      # TODO: strncmp ?
      if sysCounters[i2].nameLen == name.len:
        var j = 0
        while true:
          if j >= name.len:
            break
          if name[j] != sysCounters[i2].name[j]:
            ok = false
            break
          j.inc
        if ok:
          break
      i2.inc
    if i2 < sysCounters.len:
      sysCounters[i2].count.inc

  newImpl(a)
