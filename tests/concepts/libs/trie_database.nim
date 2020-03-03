type
  KeccakHash* = object
    data*: string

  BytesRange* = object
    bytes*: string

  TrieDatabase* = concept db
    put(var db, KeccakHash, string) is bool
    del(var db, KeccakHash) is bool
    get(db, KeccakHash) is string

