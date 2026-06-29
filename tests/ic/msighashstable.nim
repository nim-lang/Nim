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

func tcOrMember*(F: type DefaultFlavor, TC: distinct type, TM: distinct type): bool {.compileTime.} =
  ## Is `TM` registered, or its parent type class `TC`? Models
  ## `typeClassOrMemberAutoSerialize` — used to auto-serialize any `object`/`tuple`.
  if F.getAuto(TM): return true
  if F.getAuto(TC): return true
  false

template autoCheck*(F: distinct type, T: distinct type, body) =
  when not F.getAuto(T):
    {.error: "auto serialization not enabled for `" & typetraits.name(T) & "`".}
  else:
    body

template autoCheckTC*(F: distinct type, TC: distinct type, M: distinct type, body) =
  when not F.tcOrMember(TC, M):
    {.error: "auto serialization not enabled for `" & typetraits.name(M) &
      "` of typeclass `" & typetraits.name(TC) & "`".}
  else:
    body

static:
  setAuto(DefaultFlavor, string)
  setAuto(DefaultFlavor, SomeInteger)
  setAuto(DefaultFlavor, seq)
  # Builtin *type classes*: `object`/`tuple` are `tyBuiltInTypeClass`, whose
  # `signatureHash` must not mix in the placeholder son's process-local type id
  # or the lookup misses across the NIF boundary (the real nim-serialization bug
  # surfaced by Nimbus: `MultiAddress`/`RequestId` "of typeclass `object`").
  setAuto(DefaultFlavor, object)
  setAuto(DefaultFlavor, tuple)
