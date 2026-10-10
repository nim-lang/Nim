#
#
#           The Nim Compiler
#        (c) Copyright 2026 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## `ItemId` is the identity of a symbol or type: a `(module, item)` pair.
##
## The fields are private on purpose: the module half reserves bit 30 as the
## "backend minted" marker, so all construction and inspection has to go
## through this module's API and the marker bit can never leak into module
## indexing or arithmetic.
##
## Three id spaces coexist per module:
## - Semantic-phase and NIF-loader ids: `itemId(module, item)` with `item > 0`.
## - Backend-minted ids (IC codegen, `nim nifc`: transf labels and temps,
##   lifted hooks): `backendItemId` sets `BackendModuleBit`, so these can
##   never compare equal to a loader id even though both counters mint the
##   same small `item` range in one process. They never cross a process
##   boundary and must never be written to a NIF file.
## - Derived env/tuple-field ids (`lowerings.addField`): the source local's
##   id with `item` negated. `derivedFieldId` preserves the backend marker,
##   keeping the derivation collision-free for both id spaces above.

import std/hashes

when defined(nimPreviewSlimSystem):
  import std/assertions

const
  BackendModuleBit = 0x4000_0000'i32
    # Bit 30 of the module field. Bit 31 stays clear so marked module values
    # remain non-negative and cannot be mistaken for the special negative
    # module ids like `PackageModuleId`.
  PackageModuleId* = -3'i32

type
  ItemId* = object
    moduleBits: int32
    itemBits: int32

proc itemId*(module, item: int32): ItemId {.inline.} =
  assert module < 0 or (module and BackendModuleBit) == 0
  ItemId(moduleBits: module, itemBits: item)

proc backendItemId*(module, item: int32): ItemId {.inline.} =
  ## An id minted during IC codegen; distinct from every `itemId` of the
  ## same module so that the loader's stub counter and the backend's counter
  ## cannot collide in id-keyed tables.
  assert module >= 0 and (module and BackendModuleBit) == 0
  ItemId(moduleBits: module or BackendModuleBit, itemBits: item)

proc module*(x: ItemId): int32 {.inline.} =
  if x.moduleBits >= 0: x.moduleBits and not BackendModuleBit
  else: x.moduleBits

proc item*(x: ItemId): int32 {.inline.} = x.itemBits

proc isBackendMinted*(x: ItemId): bool {.inline.} =
  x.moduleBits >= 0 and (x.moduleBits and BackendModuleBit) != 0

proc derivedFieldId*(source: ItemId): ItemId {.inline.} =
  ## The id of the env/tuple field that `lowerings.addField` derives for a
  ## captured local: `item` negated, module bits (including the backend
  ## marker) preserved.
  ItemId(moduleBits: source.moduleBits, itemBits: -abs(source.itemBits))

proc matchesDerivedFieldId*(field, source: ItemId): bool {.inline.} =
  ## Does `field` carry the id `derivedFieldId` would derive for `source`?
  ## `source` may itself already be the derived field id.
  field.moduleBits == source.moduleBits and
    field.itemBits == -abs(source.itemBits)

proc `==`*(a, b: ItemId): bool {.inline.} =
  # raw bit comparison: a backend-minted id never equals a loader id
  a.itemBits == b.itemBits and a.moduleBits == b.moduleBits

proc hash*(x: ItemId): Hash =
  var h: Hash = hash(x.moduleBits)
  h = h !& hash(x.itemBits)
  result = !$h

proc `$`*(x: ItemId): string =
  result = "(module: " & $x.module & ", item: " & $x.itemBits
  if x.isBackendMinted: result.add ", backend"
  result.add ")"

const
  moduleShift = when defined(cpu32): 20 else: 24

proc toId*(a: ItemId): int {.inline.} =
  ## Packs an ItemId into a single int. Uses the raw module bits so the
  ## backend marker keeps the two id spaces disjoint (bit 30 shifts to
  ## bit 54; like the module/item split itself this needs a 64-bit int).
  (a.moduleBits.int shl moduleShift) + a.itemBits.int
