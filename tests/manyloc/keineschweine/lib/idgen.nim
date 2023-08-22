type
  PIDGen*[T: Ordinal] = ref TIDGen[T]
  TIDGen*[T: Ordinal] = object
    max: T
    freeIDs: seq[T]
  EOutOfIDs* = object of EInvalidKey

#proc free[T](idg: PIDgen[T]) =
#  result.freeIDs = nil
proc newIDGen*[T: Ordinal](): PIDGen[T] =
  new(result)#, free)
  result.max = 0.T
  result.freeIDs = @[]
proc next*[T](idg: PIDGen[T]): T =
  if idg.freeIDs.len > 0:
    result = idg.freeIDs.pop
  elif idg.max < high(T)-T(1):
    inc idg.max
    result = idg.max
  else:
    raise newException(EOutOfIDs, "ID generator hit max value")
proc del*[T](idg: PIDGen[T]; id: T) =
  idg.freeIDs.add id
