discard """
  matrix: "--mm:refc"
  action: compile
"""

type
  SomePointer = ref | ptr | pointer | proc
  Option[T] = object
    when T is SomePointer:
      val: T
    else:
      val: T
      has: bool

proc some*[T](val: T): Option[T] {.inline.} =
  when T is SomePointer:
    result.val = val
  else:
    result.has = true
    result.val = val

proc none*(T: typedesc): Option[T] {.inline.} =
  discard

type
  Events = object
    # remove this proc and it works
    cb: proc (guild: Option[Guild])
  
  Guild = ref object

proc channelPinsUpdate*() =
  var guild = none Guild
  guild = some Guild()

channelPinsUpdate()
