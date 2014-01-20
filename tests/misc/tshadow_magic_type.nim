type
  TListItemType* = enum
    RedisNil, RedisString

  TListItem* = object
    case kind*: TListItemType
    of RedisString:
      str*: string
    else: nil
  TRedisList* = seq[TListItem]

# Caused by this.
proc seq*() =
  nil

proc lrange*(key: string): TRedisList =
  var foo: TListItem
  foo.kind = RedisNil
  result = @[foo]

when isMainModule:
  var p = lrange("mylist")
  for i in items(p):
    echo(i.str)
