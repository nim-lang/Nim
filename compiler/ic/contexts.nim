import std/tables
import ".."/[ast, lineinfos, idents]
import packed_ast, bitabs

type
  PackedEncoder* = object
    thisModule*: int32
    lastFile*: FileIndex # remember the last lookup entry.
    lastLit*: LitId
    filenames*: Table[FileIndex, LitId]
    pendingTypes*: seq[PType]
    pendingSyms*: seq[PSym]
    typeMap*: Table[ItemId, TypeId]  # ItemId.item -> TypeId
    symMap*: Table[ItemId, SymId]    # ItemId.item -> SymId

  Resolver* = proc(module: int32; name: string): PSym
  PackedDecoder* = object
    thisModule*: int32
    lastFile*: FileIndex # remember the last lookup entry.
    lastLit*: LitId
    filenames*: Table[LitId, FileIndex]
    typeMap*: Table[ItemId, PType]  # ItemId.item -> PType
    symMap*: Table[ItemId, PSym]    # ItemId.item -> PSym
    resolver*: Resolver
    idents*: IdentCache

proc initDecoder*(c: var PackedDecoder; module: PSym) =
  ## prep a context for a new module
  c.thisModule = module.itemId.module

proc initDecoder*(c: var PackedDecoder; cache: IdentCache;
                  resolver: Resolver) =
  ## setup a context with the critical resolution tools it needs
  c.idents = cache
  c.resolver = resolver

proc initEncoder*(c: var PackedEncoder; m: PSym) =
  ## setup a context for serializing to packed ast
  c.thisModule = m.itemId.module

proc thisModule*(c: PackedEncoder): int32 = c.thisModule

