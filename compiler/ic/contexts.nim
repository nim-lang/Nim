import std/tables
import ".."/[ast, lineinfos, idents]
import packed_ast, bitabs

type
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
