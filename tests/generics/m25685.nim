import std/[sets, tables]

func impl*(flag: static bool): seq[uint64] =
  var all = initHashSet[uint64]()
  all.incl 1
  for idx in all:
    result.add idx

proc keys*[T](x: T): seq[string] =
  var t = initTable[string, int]()
  t["a"] = 1
  for k, v in t:
    result.add k

proc iterAny*[T](x: T): seq[int] =
  # `items` for `T` comes from the instantiation context:
  for a in x:
    result.add a

template bar*(): seq[uint64] =
  impl(flag = true)
