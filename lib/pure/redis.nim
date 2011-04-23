#
#
#            Nimrod's Runtime Library
#        (c) Copyright 2011 Dominik Picheta
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## This module implements a redis client. It allows you to connect to a redis-server instance, send commands and receive replies.
##
## **Beware**: Most (if not all) functions that return a `TRedisString` may
## return `redisNil`.

import sockets, os, strutils, parseutils

const
  redisNil* = "\0\0"

type
  TRedis* {.pure, final.} = object
    socket: TSocket
    connected: bool
  
  TRedisStatus* = string
  TRedisInteger* = biggestInt
  TRedisString* = string ## Bulk reply
  TRedisList* = seq[TRedisString] ## Multi-bulk reply

  EInvalidReply* = object of ESynch ## Invalid reply from redis
  ERedis* = object of ESynch        ## Error in redis

proc open*(host = "localhost", port = 6379.TPort): TRedis =
  ## Opens a connection to the redis server.
  result.socket = socket()
  if result.socket == InvalidSocket:
    OSError()
  result.socket.connect(host, port)

proc stripNewline(s: string): string =
  ## Strips trailing new line
  const
    chars: set[Char] = {'\c', '\L'}
    first = 0
    
  var last = len(s)-1
  
  while last >= 0 and s[last] in chars: dec(last)
  result = copy(s, first, last)

proc raiseInvalidReply(expected, got: char) =
  raise newException(EInvalidReply, 
          "Expected '$1' at the beginning of a status reply got '$2'" %
          [$expected, $got])

proc raiseNoOK(status: string) =
  if status != "OK":
    raise newException(EInvalidReply, "Expected \"OK\" got \"$1\"" % status)

proc parseStatus(r: TRedis): TRedisStatus =
  var line = r.socket.recv()
  
  if line[0] == '-':
    raise newException(ERedis, stripNewline(line))
  if line[0] != '+':
    raiseInvalidReply('+', line[0])
  
  return line.copy(1, line.len-3) # Strip '+' and \c\L.
  
proc parseInteger(r: TRedis): TRedisInteger =
  var line = r.socket.recv()
  
  if line[0] == '-':
    raise newException(ERedis, stripNewline(line))
  if line[0] != ':':
    raiseInvalidReply(':', line[0])
  
  return parseBiggestInt(line, result, 1) # Strip ':' and \c\L.

proc recv(sock: TSocket, size: int): string =
  result = newString(size)
  if sock.recv(cstring(result), size) != size:
    raise newException(EInvalidReply, "recv failed")

proc parseBulk(r: TRedis, allowMBNil = False): TRedisString =
  var line = ""
  if not r.socket.recvLine(line):
    raise newException(EInvalidReply, "recvLine failed")
  
  # Error.
  if line[0] == '-':
    raise newException(ERedis, stripNewline(line))
  
  # Some commands return a /bulk/ value or a /multi-bulk/ nil. Odd.
  if allowMBNil:
    if line == "*-1":
       result = RedisNil
       return
  
  if line[0] != '$':
    raiseInvalidReply('$', line[0])
  
  var numBytes = parseInt(line.copy(1))
  if numBytes == -1:
    result = RedisNil
    return
  var s = r.socket.recv(numBytes+2)
  result = stripNewline(s)

proc parseMultiBulk(r: TRedis): TRedisList =
  var line = ""
  if not r.socket.recvLine(line):
    raise newException(EInvalidReply, "recvLine failed")
    
  if line[0] != '*':
    raiseInvalidReply('*', line[0])
  
  var numElems = parseInt(line.copy(1))
  if numElems == -1: return nil
  result = @[]
  for i in 1..numElems:
    result.add(r.parseBulk())

# Keys

proc del*(r: TRedis, keys: openArray[string]): TRedisInteger =
  ## Delete a key or multiple keys
  r.socket.send("DEL $1\c\L" % keys.join(" "))
  return r.parseInteger()

proc exists*(r: TRedis, key: string): bool =
  ## Determine if a key exists
  r.socket.send("EXISTS $1\c\L" % key)
  return r.parseInteger() == 1

proc expire*(r: TRedis, key: string, seconds: int): bool =
  ## Set a key's time to live in seconds. Returns `false` if the key could
  ## not be found or the timeout could not be set.
  r.socket.send("EXPIRE $1 $2\c\L" % [key, $seconds])
  return r.parseInteger() == 1

proc expireAt*(r: TRedis, key: string, timestamp: int): bool =
  ## Set the expiration for a key as a UNIX timestamp. Returns `false` 
  ## if the key could not be found or the timeout could not be set.
  r.socket.send("EXPIREAT $1 $2\c\L" % [key, $timestamp])
  return r.parseInteger() == 1

proc keys*(r: TRedis, pattern: string): TRedisList =
  ## Find all keys matching the given pattern
  r.socket.send("KEYS $1\c\L" % pattern)
  return r.parseMultiBulk()

proc move*(r: TRedis, key: string, db: int): bool =
  ## Move a key to another database. Returns `true` on a successful move.
  r.socket.send("MOVE $1 $2\c\L" % [key, $db])
  return r.parseInteger() == 1

proc persist*(r: TRedis, key: string): bool =
  ## Remove the expiration from a key. 
  ## Returns `true` when the timeout was removed.
  r.socket.send("PERSIST $1\c\L" % key)
  return r.parseInteger() == 1
  
proc randomKey*(r: TRedis): TRedisString =
  ## Return a random key from the keyspace
  r.socket.send("RANDOMKEY\c\L")
  return r.parseBulk()

proc rename*(r: TRedis, key, newkey: string): TRedisStatus =
  ## Rename a key.
  ## 
  ## **WARNING:** Overwrites `newkey` if it exists!
  r.socket.send("RENAME $1 $2\c\L" % [key, newkey])
  raiseNoOK(r.parseStatus())
  
proc renameNX*(r: TRedis, key, newkey: string): bool =
  ## Same as ``rename`` but doesn't continue if `newkey` exists.
  ## Returns `true` if key was renamed.
  r.socket.send("RENAMENX $1 $2\c\L" % [key, newkey])
  return r.parseInteger() == 1

proc ttl*(r: TRedis, key: string): TRedisInteger =
  ## Get the time to live for a key
  r.socket.send("TTL $1\c\L" % key)
  return r.parseInteger()
  
proc keyType*(r: TRedis, key: string): TRedisStatus =
  ## Determine the type stored at key
  r.socket.send("TYPE $1\c\L" % key)
  return r.parseStatus()
  

# Strings

proc append*(r: TRedis, key, value: string): TRedisInteger =
  ## Append a value to a key
  r.socket.send("APPEND $1 \"$2\"\c\L" % [key, value])
  return r.parseInteger()

proc decr*(r: TRedis, key: string): TRedisInteger =
  ## Decrement the integer value of a key by one
  r.socket.send("DECR $1\c\L" % key)
  return r.parseInteger()
  
proc decrBy*(r: TRedis, key: string, decrement: int): TRedisInteger =
  ## Decrement the integer value of a key by the given number
  r.socket.send("DECRBY $1 $2\c\L" % [key, $decrement])
  return r.parseInteger()
  
proc get*(r: TRedis, key: string): TRedisString =
  ## Get the value of a key. Returns `nil` when `key` doesn't exist.
  r.socket.send("GET $1\c\L" % key)
  return r.parseBulk()

proc getBit*(r: TRedis, key: string, offset: int): TRedisInteger =
  ## Returns the bit value at offset in the string value stored at key
  r.socket.send("GETBIT $1 $2\c\L" % [key, $offset])
  return r.parseInteger()

proc getRange*(r: TRedis, key: string, start, stop: int): TRedisString =
  ## Get a substring of the string stored at a key
  r.socket.send("GETRANGE $1 $2 $3\c\L" % [key, $start, $stop])
  return r.parseBulk()

proc getSet*(r: TRedis, key: string, value: string): TRedisString =
  ## Set the string value of a key and return its old value. Returns `nil` when
  ## key doesn't exist.
  r.socket.send("GETSET $1 \"$2\"\c\L" % [key, value])
  return r.parseBulk()

proc incr*(r: TRedis, key: string): TRedisInteger =
  ## Increment the integer value of a key by one.
  r.socket.send("INCR $1\c\L" % key)
  return r.parseInteger()

proc incrBy*(r: TRedis, key: string, increment: int): TRedisInteger =
  ## Increment the integer value of a key by the given number
  r.socket.send("INCRBY $1 $2\c\L" % [key, $increment])
  return r.parseInteger()

proc setk*(r: TRedis, key, value: string) = 
  ## Set the string value of a key.
  ##
  ## NOTE: This function had to be renamed due to a clash with the `set` type.
  r.socket.send("SET $1 \"$2\"\c\L" % [key, value])
  raiseNoOK(r.parseStatus())

proc setNX*(r: TRedis, key, value: string): bool =
  ## Set the value of a key, only if the key does not exist. Returns `true`
  ## if the key was set.
  r.socket.send("SETNX $1 \"$2\"\c\L" % [key, value])
  return r.parseInteger() == 1

proc setBit*(r: TRedis, key: string, offset: int, 
  value: string): TRedisInteger =
  ## Sets or clears the bit at offset in the string value stored at key
  r.socket.send("SETBIT $1 $2 \"$3\"\c\L" % [key, $offset, value])
  return r.parseInteger()
  
proc setEx*(r: TRedis, key: string, seconds: int, value: string): TRedisStatus =
  ## Set the value and expiration of a key
  r.socket.send("SETEX $1 $2 \"$3\"\c\L" % [key, $seconds, value])
  raiseNoOK(r.parseStatus())

proc setRange*(r: TRedis, key: string, offset: int, 
  value: string): TRedisInteger =
  ## Overwrite part of a string at key starting at the specified offset
  r.socket.send("SETRANGE $1 $2 \"$3\"\c\L" % [key, $offset, value])
  return r.parseInteger()

proc strlen*(r: TRedis, key: string): TRedisInteger =
  ## Get the length of the value stored in a key. Returns 0 when key doesn't
  ## exist.
  r.socket.send("STRLEN $1\c\L" % key)
  return r.parseInteger()

# Hashes
proc hDel*(r: TRedis, key, field: string): bool =
  ## Delete a hash field at `key`. Returns `true` if field was removed.
  r.socket.send("HDEL $1 $2\c\L" % [key, field])
  return r.parseInteger() == 1

proc hExists*(r: TRedis, key, field: string): bool =
  ## Determine if a hash field exists.
  r.socket.send("HEXISTS $1 $2\c\L" % [key, field])
  return r.parseInteger() == 1

proc hGet*(r: TRedis, key, field: string): TRedisString =
  ## Get the value of a hash field
  r.socket.send("HGET $1 $2\c\L" % [key, field])
  return r.parseBulk()

proc hGetAll*(r: TRedis, key: string): TRedisList =
  ## Get all the fields and values in a hash
  r.socket.send("HGETALL $1\c\L" % key)
  return r.parseMultiBulk()

proc hIncrBy*(r: TRedis, key, field: string, incr: int): TRedisInteger =
  ## Increment the integer value of a hash field by the given number
  r.socket.send("HINCRBY $1 $2 $3\c\L" % [key, field, $incr])
  return r.parseInteger()

proc hKeys*(r: TRedis, key: string): TRedisList =
  ## Get all the fields in a hash
  r.socket.send("HKEYS $1\c\L" % key)
  return r.parseMultiBulk()

proc hLen*(r: TRedis, key: string): TRedisInteger =
  ## Get the number of fields in a hash
  r.socket.send("HLEN $1\c\L" % key)
  return r.parseInteger()

proc hMGet*(r: TRedis, key: string, fields: openarray[string]): TRedisList =
  ## Get the values of all the given hash fields
  r.socket.send("HMGET $1 $2\c\L" % [key, fields.join()])
  return r.parseMultiBulk()

proc hMSet*(r: TRedis, key: string, 
            fieldValues: openarray[tuple[field, value: string]]) =
  ## Set multiple hash fields to multiple values
  var fieldVals = ""
  for field, value in items(fieldValues):
    fieldVals.add(field & " " & value)
  r.socket.send("HMSET $1 $2\c\L" % [key, fieldVals])
  raiseNoOK(r.parseStatus())

proc hSet*(r: TRedis, key, field, value: string) =
  ## Set the string value of a hash field
  r.socket.send("HSET $1 $2 \"$3\"\c\L" % [key, field, value])
  raiseNoOK(r.parseStatus())
  
proc hSetNX*(r: TRedis, key, field, value: string) =
  ## Set the value of a hash field, only if the field does **not** exist
  r.socket.send("HSETNX $1 $2 \"$3\"\c\L" % [key, field, value])
  raiseNoOK(r.parseStatus())

proc hVals*(r: TRedis, key: string): TRedisList =
  ## Get all the values in a hash
  r.socket.send("HVALS $1\c\L" % key)
  return r.parseMultiBulk()
  
# Lists

proc bLPop*(r: TRedis, keys: openarray[string], timeout: int): TRedisList =
  ## Remove and get the *first* element in a list, or block until 
  ## one is available
  r.socket.send("BLPOP $1 $2\c\L" % [keys.join(), $timeout])
  return r.parseMultiBulk()

proc bRPop*(r: TRedis, keys: openarray[string], timeout: int): TRedisList =
  ## Remove and get the *last* element in a list, or block until one 
  ## is available.
  r.socket.send("BRPOP $1 $2\c\L" % [keys.join(), $timeout])
  return r.parseMultiBulk()

proc bRPopLPush*(r: TRedis, source, destination: string,
                 timeout: int): TRedisString =
  ## Pop a value from a list, push it to another list and return it; or
  ## block until one is available.
  ##
  ## http://redis.io/commands/brpoplpush
  r.socket.send("BRPOPLPUSH $1 $2 $3\c\L" % [source, destination, $timeout])
  return r.parseBulk(true) # Multi-Bulk nil allowed.

proc lIndex*(r: TRedis, key: string, index: int): TRedisString =
  ## Get an element from a list by its index
  r.socket.send("LINDEX $1 $2\c\L" % [key, $index])
  return r.parseBulk()

proc lInsert*(r: TRedis, key: string, before: bool, pivot, value: string):
              TRedisInteger =
  ## Insert an element before or after another element in a list
  var pos = if before: "BEFORE" else: "AFTER"
  r.socket.send("LINSERT $1 $2 $3 \"$4\"\c\L" % [key, pos, pivot, value])
  return r.parseInteger()
  
proc lLen*(r: TRedis, key: string): TRedisInteger =
  ## Get the length of a list
  r.socket.send("LLEN $1\c\L" % key)
  return r.parseInteger()

proc lPop*(r: TRedis, key: string): TRedisString =
  ## Remove and get the first element in a list
  r.socket.send("LPOP $1\c\L" % key)
  return r.parseBulk()

proc lPush*(r: TRedis, key, value: string, create: bool = True): TRedisInteger =
  ## Prepend a value to a list. Returns the length of the list after the push.
  ## The ``create`` param specifies whether a list should be created if it
  ## doesn't exist at ``key``. More specifically if ``create`` is True, `LPUSH` will
  ## be used, otherwise `LPUSHX`.
  if create:
    r.socket.send("LPUSH $1 \"$2\"\c\L" % [key, value])
  else:
    r.socket.send("LPUSHX $1 \"$2\"\c\L" % [key, value])
  return r.parseInteger()

proc lRange*(r: TRedis, key: string, start, stop: int): TRedisList =
  ## Get a range of elements from a list. Returns `nil` when `key` 
  ## doesn't exist.
  r.socket.send("LRANGE $1 $2 $3\c\L" % [key, $start, $stop])
  return r.parseMultiBulk()

proc lRem*(r: TRedis, key: string, value: string, count: int = 0): TRedisInteger =
  ## Remove elements from a list. Returns the number of elements that have been
  ## removed.
  r.socket.send("LREM $1 $2 \"$3\"\c\L" % [key, $count, value])
  return r.parseInteger()

proc lSet*(r: TRedis, key: string, index: int, value: string) =
  ## Set the value of an element in a list by its index
  r.socket.send("LSET $1 $2 \"$3\"\c\L" % [key, $index, value])
  raiseNoOK(r.parseStatus())

proc lTrim*(r: TRedis, key: string, start, stop: int) =
  ## Trim a list to the specified range
  r.socket.send("LTRIM $1 $2 $3\c\L" % [key, $start, $stop])
  raiseNoOK(r.parseStatus())

proc rPop*(r: TRedis, key: string): TRedisString =
  ## Remove and get the last element in a list
  r.socket.send("RPOP $1\c\L" % key)
  return r.parseBulk()
  
proc rPopLPush*(r: TRedis, source, destination: string): TRedisString =
  ## Remove the last element in a list, append it to another list and return it
  r.socket.send("RPOPLPUSH $1 $2\c\L" % [source, destination])
  return r.parseBulk()
  
proc rPush*(r: TRedis, key, value: string, create: bool = True): TRedisInteger =
  ## Append a value to a list. Returns the length of the list after the push.
  ## The ``create`` param specifies whether a list should be created if it
  ## doesn't exist at ``key``. More specifically if ``create`` is True, `RPUSH` will
  ## be used, otherwise `RPUSHX`.
  if create:
    r.socket.send("RPUSH $1 \"$2\"\c\L" % [key, value])
  else:
    r.socket.send("RPUSHX $1 \"$2\"\c\L" % [key, value])
  return r.parseInteger()

# Sets

proc sadd*(r: TRedis, key: string, member: string): TRedisInteger =
  ## Add a member to a set
  r.socket.send("SADD $# \"$#\"\c\L" % [key, member])
  return r.parseInteger()

proc scard*(r: TRedis, key: string): TRedisInteger =
  ## Get the number of members in a set
  r.socket.send("SCARD $#\c\L" % key)
  return r.parseInteger()

proc sdiff*(r: TRedis, key: openarray[string]): TRedisList =
  ## Subtract multiple sets
  r.socket.send("SDIFF $#\c\L" % key)
  return r.parseMultiBulk()

proc sdiffstore*(r: TRedis, destination: string,
                key: openarray[string]): TRedisInteger =
  ## Subtract multiple sets and store the resulting set in a key
  r.socket.send("SDIFFSTORE $# $#\c\L" % [destination, key.join()])
  return r.parseInteger()

proc sinter*(r: TRedis, key: openarray[string]): TRedisList =
  ## Intersect multiple sets
  r.socket.send("SINTER $#\c\L" % key)
  return r.parseMultiBulk()

proc sinterstore*(r: TRedis, destination: string,
                 key: openarray[string]): TRedisInteger =
  ## Intersect multiple sets and store the resulting set in a key
  r.socket.send("SINTERSTORE $# $#\c\L" % [destination, key.join()])
  return r.parseInteger()

proc sismember*(r: TRedis, key: string, member: string): TRedisInteger =
  ## Determine if a given value is a member of a set
  r.socket.send("SISMEMBER $# \"$#\"\c\L" % [key, member])
  return r.parseInteger()

proc smembers*(r: TRedis, key: string): TRedisList =
  ## Get all the members in a set
  r.socket.send("SMEMBERS $#\c\L" % key)
  return r.parseMultiBulk()

proc smove*(r: TRedis, source: string, destination: string,
           member: string): TRedisInteger =
  ## Move a member from one set to another
  r.socket.send("SMOVE $# $# \"$#\"\c\L" % [source, destination, member])
  return r.parseInteger()

proc spop*(r: TRedis, key: string): TRedisString =
  ## Remove and return a random member from a set
  r.socket.send("SPOP $#\c\L" % key)
  return r.parseBulk()

proc srandmember*(r: TRedis, key: string): TRedisString =
  ## Get a random member from a set
  r.socket.send("SRANDMEMBER $#\c\L" % key)
  return r.parseBulk()

proc srem*(r: TRedis, key: string, member: string): TRedisInteger =
  ## Remove a member from a set
  r.socket.send("SREM $# \"$#\"\c\L" % [key, member])
  return r.parseInteger()

proc sunion*(r: TRedis, key: openarray[string]): TRedisList =
  ## Add multiple sets
  r.socket.send("SUNION $#\c\L" % key)
  return r.parseMultiBulk()

proc sunionstore*(r: TRedis, destination: string,
                 key: openarray[string]): TRedisInteger =
  ## Add multiple sets and store the resulting set in a key 
  r.socket.send("SUNIONSTORE $# $#\c\L" % [destination, key.join()])
  return r.parseInteger()

# Sorted sets

proc zadd*(r: TRedis, key: string, score: int, member: string): TRedisInteger =
  ## Add a member to a sorted set, or update its score if it already exists
  r.socket.send("ZADD $# $# \"$#\"\c\L" % [key, $score, member])
  return r.parseInteger()

proc zcard*(r: TRedis, key: string): TRedisInteger =
  ## Get the number of members in a sorted set
  r.socket.send("ZCARD $#\c\L" % key)
  return r.parseInteger()

proc zcount*(r: TRedis, key: string, min: string, max: string): TRedisInteger =
  ## Count the members in a sorted set with scores within the given values
  r.socket.send("ZCOUNT $# $# $#\c\L" % [key, min, max])
  return r.parseInteger()

proc zincrby*(r: TRedis, key: string, increment: string,
             member: string): TRedisString =
  ## Increment the score of a member in a sorted set
  r.socket.send("ZINCRBY $# $# \"$#\"\c\L" % [key, increment, member])
  return r.parseBulk()

proc zinterstore*(r: TRedis, destination: string, numkeys: string,
                 key: openarray[string], weights: openarray[string] = [],
                 aggregate: string = ""): TRedisInteger =
  ## Intersect multiple sorted sets and store the resulting sorted set in a new key
  var command = "ZINTERSTORE $# $# $#" % [destination, numkeys, key.join()]
  
  if weights.len != 0:
    command.add(" " & weights.join())
  if aggregate.len != 0:
    command.add(" " & aggregate.join())
    
  r.socket.send(command & "\c\L")
  
  return r.parseInteger()

proc zrange*(r: TRedis, key: string, start: string, stop: string,
            withScores: bool): TRedisList =
  ## Return a range of members in a sorted set, by index
  if not withScores:
    r.socket.send("ZRANGE $# $# $#\c\L" % [key, start, stop.join()])
  else:
    r.socket.send("ZRANGE $# $# $# WITHSCORES\c\L" % [key, start, stop.join()])
  return r.parseMultiBulk()

proc zrangebyscore*(r: TRedis, key: string, min: string, max: string, 
                   withScore: bool = false, limit: bool = False,
                   limitOffset: int = 0, limitCount: int = 0): TRedisList =
  ## Return a range of members in a sorted set, by score
  var command = "ZRANGEBYSCORE $# $# $#" % [key, min, max.join()]
  
  if withScore: command.add(" WITHSCORE")
  if limit: command.add(" LIMIT " & $limitOffset & " " & $limitCount)
  
  r.socket.send(command & "\c\L")
  return r.parseMultiBulk()

proc zrank*(r: TRedis, key: string, member: string): TRedisString =
  ## Determine the index of a member in a sorted set
  r.socket.send("ZRANK $# \"$#\"\c\L" % [key, member])
  return r.parseBulk()

proc zrem*(r: TRedis, key: string, member: string): TRedisInteger =
  ## Remove a member from a sorted set
  r.socket.send("ZREM $# \"$#\"\c\L" % [key, member])
  return r.parseInteger()

proc zremrangebyrank*(r: TRedis, key: string, start: string,
                     stop: string): TRedisInteger =
  ## Remove all members in a sorted set within the given indexes
  r.socket.send("ZREMRANGEBYRANK $# $# $#\c\L" % [key, start, stop])
  return r.parseInteger()

proc zremrangebyscore*(r: TRedis, key: string, min: string,
                      max: string): TRedisInteger =
  ## Remove all members in a sorted set within the given scores
  r.socket.send("ZREMRANGEBYSCORE $# $# $#\c\L" % [key, min, max])
  return r.parseInteger()

proc zrevrange*(r: TRedis, key: string, start: string, stop: string,
               withScore: bool): TRedisList =
  ## Return a range of members in a sorted set, by index, 
  ## with scores ordered from high to low
  if withScore:
    r.socket.send("ZREVRANGE $# $# $# WITHSCORE\c\L" %
                  [key, start, stop.join()])
  else: r.socket.send("ZREVRANGE $# $# $#\c\L" % [key, start, stop.join()])
  return r.parseMultiBulk()

proc zrevrangebyscore*(r: TRedis, key: string, min: string, max: string, 
                   withScore: bool = false, limit: bool = False,
                   limitOffset: int = 0, limitCount: int = 0): TRedisList =
  ## Return a range of members in a sorted set, by score, with
  ## scores ordered from high to low
  var command = "ZREVRANGEBYSCORE $# $# $#" % [key, min, max.join()]
  
  if withScore: command.add(" WITHSCORE")
  if limit: command.add(" LIMIT " & $limitOffset & " " & $limitCount)
  
  r.socket.send(command & "\c\L")
  return r.parseMultiBulk()

proc zrevrank*(r: TRedis, key: string, member: string): TRedisString =
  ## Determine the index of a member in a sorted set, with
  ## scores ordered from high to low
  r.socket.send("ZREVRANK $# \"$#\"\c\L" % [key, member])
  return r.parseBulk()

proc zscore*(r: TRedis, key: string, member: string): TRedisString =
  ## Get the score associated with the given member in a sorted set
  r.socket.send("ZSCORE $# \"$#\"\c\L" % [key, member])
  return r.parseBulk()

proc zunionstore*(r: TRedis, destination: string, numkeys: string,
                 key: openarray[string], weights: openarray[string] = [],
                 aggregate: string = ""): TRedisInteger =
  ## Add multiple sorted sets and store the resulting sorted set in a new key 
  var command = "ZUNIONSTORE $# $# $#" % [destination, numkeys, key.join()]
  
  if weights.len != 0:
    command.add(" " & weights.join())
  if aggregate.len != 0:
    command.add(" " & aggregate.join())
    
  r.socket.send(command & "\c\L")
  
  return r.parseInteger()


# Pub/Sub

# TODO: pub/sub -- I don't think this will work synchronously.
discard """
proc psubscribe*(r: TRedis, pattern: openarray[string]): ???? =
  ## Listen for messages published to channels matching the given patterns
  r.socket.send("PSUBSCRIBE $#\c\L" % pattern)
  return ???

proc publish*(r: TRedis, channel: string, message: string): TRedisInteger =
  ## Post a message to a channel
  r.socket.send("PUBLISH $# $#\c\L" % [channel, message])
  return r.parseInteger()

proc punsubscribe*(r: TRedis, [pattern: openarray[string], : string): ???? =
  ## Stop listening for messages posted to channels matching the given patterns
  r.socket.send("PUNSUBSCRIBE $# $#\c\L" % [[pattern.join(), ])
  return ???

proc subscribe*(r: TRedis, channel: openarray[string]): ???? =
  ## Listen for messages published to the given channels
  r.socket.send("SUBSCRIBE $#\c\L" % channel.join)
  return ???

proc unsubscribe*(r: TRedis, [channel: openarray[string], : string): ???? =
  ## Stop listening for messages posted to the given channels 
  r.socket.send("UNSUBSCRIBE $# $#\c\L" % [[channel.join(), ])
  return ???

"""

# Transactions

proc discardCmds*(r: TRedis) =
  ## Discard all commands issued after MULTI
  r.socket.send("DISCARD\c\L")
  raiseNoOK(r.parseStatus())

proc exec*(r: TRedis): TRedisList =
  ## Execute all commands issued after MULTI
  r.socket.send("EXEC\c\L")
  return r.parseMultiBulk()

proc multi*(r: TRedis) =
  ## Mark the start of a transaction block
  r.socket.send("MULTI\c\L")
  raiseNoOK(r.parseStatus())

proc unwatch*(r: TRedis) =
  ## Forget about all watched keys
  r.socket.send("UNWATCH\c\L")
  raiseNoOK(r.parseStatus())

proc watch*(r: TRedis, key: openarray[string]) =
  ## Watch the given keys to determine execution of the MULTI/EXEC block 
  r.socket.send("WATCH $#\c\L" % key.join())
  raiseNoOK(r.parseStatus())

# Connection

proc auth*(r: TRedis, password: string) =
  ## Authenticate to the server
  r.socket.send("AUTH $#\c\L" % password)
  raiseNoOK(r.parseStatus())

proc echoServ*(r: TRedis, message: string): TRedisString =
  ## Echo the given string
  r.socket.send("ECHO $#\c\L" % message)
  return r.parseBulk()

proc ping*(r: TRedis): TRedisStatus =
  ## Ping the server
  r.socket.send("PING\c\L")
  return r.parseStatus()

proc quit*(r: TRedis) =
  ## Close the connection
  r.socket.send("QUIT\c\L")
  raiseNoOK(r.parseStatus())

proc select*(r: TRedis, index: string): TRedisStatus =
  ## Change the selected database for the current connection 
  r.socket.send("SELECT $#\c\L" % index)
  return r.parseStatus()

# Server

proc bgrewriteaof*(r: TRedis) =
  ## Asynchronously rewrite the append-only file
  r.socket.send("BGREWRITEAOF\c\L")
  raiseNoOK(r.parseStatus())

proc bgsave*(r: TRedis) =
  ## Asynchronously save the dataset to disk
  r.socket.send("BGSAVE\c\L")
  raiseNoOK(r.parseStatus())

proc configGet*(r: TRedis, parameter: string): TRedisString =
  ## Get the value of a configuration parameter
  r.socket.send("CONFIG GET $#\c\L" % parameter)
  return r.parseBulk()

proc configSet*(r: TRedis, parameter: string, value: string) =
  ## Set a configuration parameter to the given value
  r.socket.send("CONFIG SET $# $#\c\L" % [parameter, value])
  raiseNoOK(r.parseStatus())

proc configResetStat*(r: TRedis) =
  ## Reset the stats returned by INFO
  r.socket.send("CONFIG RESETSTAT\c\L")
  raiseNoOK(r.parseStatus())

proc dbsize*(r: TRedis): TRedisInteger =
  ## Return the number of keys in the selected database
  r.socket.send("DBSIZE\c\L")
  return r.parseInteger()

proc debugObject*(r: TRedis, key: string): TRedisStatus =
  ## Get debugging information about a key
  r.socket.send("DEBUG OBJECT $#\c\L" % key)
  return r.parseStatus()

proc debugSegfault*(r: TRedis) =
  ## Make the server crash
  r.socket.send("DEBUG-SEGFAULT\c\L")

proc flushall*(r: TRedis): TRedisStatus =
  ## Remove all keys from all databases
  r.socket.send("FLUSHALL\c\L")
  raiseNoOK(r.parseStatus())

proc flushdb*(r: TRedis): TRedisStatus =
  ## Remove all keys from the current database
  r.socket.send("FLUSHDB\c\L")
  raiseNoOK(r.parseStatus())

proc info*(r: TRedis): TRedisString =
  ## Get information and statistics about the server
  r.socket.send("INFO\c\L")
  return r.parseBulk()

proc lastsave*(r: TRedis): TRedisInteger =
  ## Get the UNIX time stamp of the last successful save to disk
  r.socket.send("LASTSAVE\c\L")
  return r.parseInteger()

discard """
proc monitor*(r: TRedis) =
  ## Listen for all requests received by the server in real time
  r.socket.send("MONITOR\c\L")
  raiseNoOK(r.parseStatus())
"""

proc save*(r: TRedis) =
  ## Synchronously save the dataset to disk
  r.socket.send("SAVE\c\L")
  raiseNoOK(r.parseStatus())

proc shutdown*(r: TRedis): TRedisStatus =
  ## Synchronously save the dataset to disk and then shut down the server
  r.socket.send("SHUTDOWN\c\L")
  var s = r.socket.recv()
  if s != "": raise newException(ERedis, s)

proc slaveof*(r: TRedis, host: string, port: string) =
  ## Make the server a slave of another instance, or promote it as master
  r.socket.send("SLAVEOF $# $#\c\L" % [host, port])
  raiseNoOK(r.parseStatus())

when isMainModule:
  var r = open()
  r.setk("nim:test", "WORKS!!!")
  r.setk("nim:utf8", "こんにちは")
  echo r.incr("nim:int")
  echo r.incr("nim:int")
  echo r.get("nim:int")
  echo r.get("nim:utf8")
  echo repr(r.get("blahasha"))
  var p = r.lrange("mylist", 0, -1)
  for i in items(p):
    echo("  ", i)

  echo(r.debugObject("test"))

