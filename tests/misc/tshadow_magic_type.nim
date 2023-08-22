discard """
output: '''
mylist
'''
"""


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
  discard

proc lrange*(key: string): TRedisList =
  var foo = TListItem(kind: RedisString, str: key)
  result = @[foo]

var p = lrange("mylist")
for i in items(p):
  echo(i.str)
