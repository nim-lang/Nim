import std/tables
import ast

type
  LayeredIdTable* {.acyclic.} = ref object
    topLayer*: TypeMapping
    nextLayer*: LayeredIdTable
    previousLen*: int # used to track if bindings were added

proc initLayeredTypeMap*(pt: sink TypeMapping = initTypeMapping()): LayeredIdTable =
  result = LayeredIdTable()
  result.topLayer = pt

proc currentLen*(pt: LayeredIdTable): int =
  pt.previousLen + pt.topLayer.len

proc newTypeMapLayer*(pt: LayeredIdTable): LayeredIdTable =
  result = LayeredIdTable(nextLayer: pt, topLayer: initTable[ItemId, PType](), previousLen: pt.currentLen)

proc setToPreviousLayer*(pt: var LayeredIdTable) =
  pt = pt.nextLayer

proc lookup*(typeMap: LayeredIdTable, key: PType): PType =
  result = nil
  var tm = typeMap
  while tm != nil:
    result = getOrDefault(tm.topLayer, key.itemId)
    if result != nil: return
    tm = tm.nextLayer

proc put*(typeMap: LayeredIdTable, key, value: PType) {.inline.} =
  typeMap.topLayer[key.itemId] = value
