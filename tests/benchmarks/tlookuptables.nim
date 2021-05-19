discard """
  joinable: false
"""

#[
nim r -d:numIter:10000000 -d:danger tests/benchmarks/tlookuptables.nim
on OSX:
lookup       genData1 1.111774           2100000000
lookupTables genData1 2.469191           2100000000
lookupNaive  genData1 1.580014           2100000000
lookup       genData2 0.5989679999999993 12250000000
lookupTables genData2 1.704296           12250000000
lookupNaive  genData2 4.306558000000001  12250000000
]#

import std/[times, tables, strutils]
import std/private/lookuptables
import std/private/asciitables

const numIter {.intDefine.} = 100

proc lookupTables[T](a: Table[T, int], key: T): int =
  a[key]

proc lookupNaive[T](a: seq[T], key: T): int =
  for i, ai in a:
    if ai == key: return i
  return -1

proc genData1(): seq[int] =
  # checks performance on small data
  result = @[100, 13, 15, 12, 0, -3, 44]

proc genData2(): seq[int] =
  # size 50
  for i in 0..<50:
    result.add i * 37

var msg = ""

template mainAux(genData, algo) =
  const genDataName = astToStr(genData)
  when genDataName == "genData1": (let factor = 10)
  elif genDataName == "genData2": (let factor = 1)
  else: static: doAssert false, genDataName

  let a = genData()
  const name = astToStr(algo)
  when name == "lookup":
    let tab = initLookupTable(a)
  elif name == "lookupNaive":
    template tab: untyped = a
  elif name == "lookupTables":
    var tab: Table[int, int]
    for i, ai in a:
      tab[ai] = i
  else: static: doAssert false, name
  let t = cpuTime()
  var c = 0
  let n = numIter * factor
  for i in 0..<n:
    for ai in a:
      c += algo(tab, ai)
  let t2 = cpuTime()-t
  let msgi = "$#\t$#\t$#\t$#" % [name, genDataName, $t2, $c]
  echo msgi # show intermediate progress
  msg.add msgi & "\n"

template main2(genData) =
  mainAux(genData, lookup)
  mainAux(genData, lookupTables)
  mainAux(genData, lookupNaive)

proc main() =
  main2(genData1)
  main2(genData2)
  echo "---\n" & msg.alignTable
main()
