import std/tables
import ast

type
  LayeredIdTable* {.acyclic.} = ref object
    topLayer*: TypeMapping
    nextLayer*: LayeredIdTable
    previousLen*: int # used to track if bindings were added

proc initLayeredTypeMap*(pt: sink TypeMapping = initTypeMapping()): LayeredIdTable =
  result = LayeredIdTable(topLayer: pt, nextLayer: nil)

proc shallowCopy*(pt: LayeredIdTable): LayeredIdTable {.inline.} =
  result = LayeredIdTable(topLayer: pt.topLayer, nextLayer: pt.nextLayer, previousLen: pt.previousLen)

proc currentLen*(pt: LayeredIdTable): int =
  pt.previousLen + pt.topLayer.len

proc newTypeMapLayer*(pt: LayeredIdTable): LayeredIdTable =
  result = LayeredIdTable(topLayer: initTable[ItemId, PType](), nextLayer: pt, previousLen: pt.currentLen)

proc setToPreviousLayer*(pt: var LayeredIdTable) {.inline.} =
  pt = pt.nextLayer

proc lookup(typeMap: LayeredIdTable, key: ItemId): PType =
  result = nil
  var tm = typeMap
  while tm != nil:
    result = getOrDefault(tm.topLayer, key)
    if result != nil: return
    tm = tm.nextLayer

template lookup*(typeMap: LayeredIdTable, key: PType): PType =
  lookup(typeMap, key.itemId)

proc put*(typeMap: LayeredIdTable, key, value: PType) {.inline.} =
  typeMap.topLayer[key.itemId] = value
