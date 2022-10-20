from std/private/ospaths2 {.all.} import joinPathImpl, joinPath, splitPath,
                                      ReadDirEffect, WriteDirEffect
export ReadDirEffect, WriteDirEffect

type
  Path* = distinct string


func joinPath*(head, tail: Path): Path {.inline.} =
  result = Path(joinPath(head.string, tail.string))

func joinPath*(parts: varargs[Path]): Path =
  var estimatedLen = 0
  for p in parts: estimatedLen += p.string.len
  var res = newStringOfCap(estimatedLen)
  var state = 0
  for i in 0..high(parts):
    joinPathImpl(res, state, parts[i].string)
  result = Path(res)

func `/`*(head, tail: Path): Path {.inline.} =
  joinPath(head, tail)

func splitPath*(path: Path): tuple[head, tail: Path] {.inline.} =
  let res = splitPath(path.string)
  result = (Path(res.head), Path(res.tail))
