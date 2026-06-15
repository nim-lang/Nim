# Helper module for tsighashstable.nim (not a test itself; no `discard`).
#
# Models nim-serialization's auto-serialization registry: a flavor records which
# types it auto-serializes in a `std/macrocache` keyed by `signatureHash(T)`,
# computed through a generic `{.compileTime.}` func. The registration happens
# here (at this module's compile time); the lookup happens in the importer.
#
# Under `nim ic` the two modules are compiled separately, so the generic
# `getSig[T]` is instantiated independently on each side. `signatureHash` must
# therefore hash the *type* `T` denotes, not the generic parameter symbol — the
# latter mixes in a per-module `disamb` counter and diverges across the NIF
# boundary, making the lookup miss.

import std/[macrocache, macros, typetraits]

type DefaultFlavor* = object

macro calcSig*(T: typed): untyped =
  doAssert(T.typeKind == ntyTypeDesc)
  result = newLit(signatureHash(T))

func getSig*(F: type DefaultFlavor, T: distinct type): string {.compileTime.} =
  calcSig(T)

func getTable*(F: type DefaultFlavor): CacheTable {.compileTime.} =
  CacheTable("nsrzStableTable" & typetraits.name(F))

func setAuto*(F: type DefaultFlavor, T: distinct type) {.compileTime.} =
  let sig = F.getSig(T)
  let table = F.getTable()
  if not table.hasKey(sig):
    table[sig] = newLit(1)

func getAuto*(F: type DefaultFlavor, T: distinct type): bool {.compileTime.} =
  let sig = F.getSig(T)
  let table = F.getTable()
  table.hasKey(sig)

template autoCheck*(F: distinct type, T: distinct type, body) =
  when not F.getAuto(T):
    {.error: "auto serialization not enabled for `" & typetraits.name(T) & "`".}
  else:
    body

static:
  setAuto(DefaultFlavor, string)
  setAuto(DefaultFlavor, SomeInteger)
  setAuto(DefaultFlavor, seq)
