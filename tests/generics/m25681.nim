import std/enumutils  # needed for items(HoleyEnum)

func test*(T: typedesc): seq[int] =
  const res = block:
    var s: seq[int]
    for f in T:
      s.add f.ord
    s
  res
