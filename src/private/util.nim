import tables

proc fget*[K, V](self: Table[K, V], key: K): V =
  if self.hasKey(key):
    return self[key]
  else:
    raise newException(KeyError, "Key does not exist in table: " & $key)
