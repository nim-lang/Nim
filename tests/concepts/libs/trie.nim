import
  hashes, tables, trie_database

type
  MemDBTable = Table[KeccakHash, string]

  MemDB* = object
    tbl: MemDBTable

proc hash*(key: KeccakHash): int =
  hashes.hash(key.data)

proc get*(db: MemDB, key: KeccakHash): string =
  db.tbl[key]

proc del*(db: var MemDB, key: KeccakHash): bool =
  if db.tbl.hasKey(key):
    db.tbl.del(key)
    return true
  else:
    return false

proc put*(db: var MemDB, key: KeccakHash, value: string): bool =
  db.tbl[key] = value
  return true

