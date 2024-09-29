import std/tables
import ast

type
  LayeredIdTable* {.acyclic.} = object
    topLayer*: TypeMapping
    nextLayer*: ref LayeredIdTable
    previousLen*: int # used to track if bindings were added

proc initLayeredTypeMap*(pt: sink TypeMapping = initTypeMapping()): LayeredIdTable =
  result = LayeredIdTable(topLayer: pt, nextLayer: nil)

proc currentLen*(pt: LayeredIdTable): int =
  pt.previousLen + pt.topLayer.len

proc newTypeMapLayer*(pt: LayeredIdTable): LayeredIdTable =
  result = LayeredIdTable(topLayer: initTable[ItemId, PType](), previousLen: pt.currentLen)
  new(result.nextLayer)
  result.nextLayer[] = pt

proc setToPreviousLayer*(pt: var LayeredIdTable) =
  # not splitting the expression breaks refc
  let y = pt.nextLayer
  pt = y[]

proc lookup(typeMap: ref LayeredIdTable, key: ItemId): PType =
  result = nil
  var tm = typeMap
  while tm != nil:
    result = getOrDefault(tm.topLayer, key)
    if result != nil: return
    tm = tm.nextLayer

proc lookup(typeMap: LayeredIdTable, key: ItemId): PType {.inline.} =
  result = getOrDefault(typeMap.topLayer, key)
  if result == nil and typeMap.nextLayer != nil:
    result = lookup(typeMap.nextLayer, key)

template lookup*(typeMap: ref LayeredIdTable, key: PType): PType =
  lookup(typeMap, key.itemId)

template lookup*(typeMap: LayeredIdTable, key: PType): PType =
  lookup(typeMap, key.itemId)

proc put*(typeMap: var LayeredIdTable, key, value: PType) {.inline.} =
  typeMap.topLayer[key.itemId] = value
