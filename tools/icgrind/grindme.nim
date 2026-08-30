import std/[strutils, tables, algorithm]
import grindlib

type Kind = enum kA, kB, kC
type Item = object
  name: string
  k: Kind
  vals: seq[int]

proc classify(i: Item): string =
  case i.k
  of kA:
    if i.vals.len > 2: result = "many"
    else: result = "few"
  of kB:
    for v in i.vals:
      if v < 0: return "neg"
    result = "pos"
  of kC:
    result = i.name.toUpperAscii

proc total(i: Item): int =
  for v in i.vals: result += v

iterator pairsish(t: Table[string, int]): (string, int) =
  for k, v in t: yield (k, v)

proc build(): Table[string, int] =
  result = initTable[string, int]()
  var items = @[Item(name: "a", k: kA, vals: @[1, 2, 3]),
                Item(name: "b", k: kB, vals: @[-1]),
                Item(name: "c", k: kC, vals: @[])]
  items.sort(proc (x, y: Item): int = cmp(x.name, y.name))
  for it in items:
    result[classify(it)] = total(it)

when isMainModule:
  var t = build()
  var keys: seq[string] = @[]
  for k, v in pairsish(t): keys.add k & "=" & $v
  keys.sort()
  echo keys.join(",")
  echo guardedLib(5), " ", guardedLib(-5)
  echo classifyChar('Q'), bigRange(150000), smallRange(5), inSets('e'), bigSet('q')
  echo viaOpen(@[1, 2, 3]), adder(4)(5), constClosure()(3), noInitVar()
  echo tuples()
