import std/tables
import ast

type
  LayeredIdTableObj* {.acyclic.} = object
    topLayer*: TypeMapping
    nextLayer*: ref LayeredIdTableObj
    previousLen*: int # used to track if bindings were added

const useRef = defined(gcMarkAndSweep)

when useRef:
  type LayeredIdTable* = ref LayeredIdTableObj
else:
  type LayeredIdTable* = LayeredIdTableObj

proc initLayeredTypeMap*(pt: sink TypeMapping = initTypeMapping()): LayeredIdTable =
  result = LayeredIdTable(topLayer: pt, nextLayer: nil)

proc shallowCopy*(pt: LayeredIdTable): LayeredIdTable {.inline.} =
  result = LayeredIdTable(topLayer: pt.topLayer, nextLayer: pt.nextLayer, previousLen: pt.previousLen)

proc currentLen*(pt: LayeredIdTable): int =
  pt.previousLen + pt.topLayer.len

proc newTypeMapLayer*(pt: LayeredIdTable): LayeredIdTable =
  result = LayeredIdTable(topLayer: initTable[ItemId, PType](), previousLen: pt.currentLen)
  when useRef:
    result.nextLayer = pt
  else:
    new(result.nextLayer)
    result.nextLayer[] = pt

proc setToPreviousLayer*(pt: var LayeredIdTable) {.inline.} =
  when useRef:
    pt = pt.nextLayer
  else:
    when defined(gcDestructors):
      pt = pt.nextLayer[]
    else:
      pt = shallowCopy(pt.nextLayer[])

proc lookup(typeMap: ref LayeredIdTableObj, key: ItemId): PType =
  result = nil
  var tm = typeMap
  while tm != nil:
    result = getOrDefault(tm.topLayer, key)
    if result != nil: return
    tm = tm.nextLayer

template lookup*(typeMap: ref LayeredIdTableObj, key: PType): PType =
  lookup(typeMap, key.itemId)

when not useRef:
  proc lookup(typeMap: LayeredIdTableObj, key: ItemId): PType {.inline.} =
    result = getOrDefault(typeMap.topLayer, key)
    if result == nil and typeMap.nextLayer != nil:
      result = lookup(typeMap.nextLayer, key)

  template lookup*(typeMap: LayeredIdTableObj, key: PType): PType =
    lookup(typeMap, key.itemId)

proc put*(typeMap: var LayeredIdTable, key, value: PType) {.inline.} =
  typeMap.topLayer[key.itemId] = value
