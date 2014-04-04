#
#
#            Nimrod's Runtime Library
#        (c) Copyright 2012 Dominik Picheta
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## This module implements a redis client. It allows you to connect to a
## redis-server instance, send commands and receive replies.
##
## **Beware**: Most (if not all) functions that return a ``TRedisString`` may
## return ``redisNil``, and functions which return a ``TRedisList`` 
## may return ``nil``.

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
  result.socket = socket(buffered = false)
  if result.socket == InvalidSocket:
    OSError(OSLastError())
  result.socket.connect(host, port)

proc raiseInvalidReply(expected, got: char) =
  raise newException(EInvalidReply, 
          "Expected '$1' at the beginning of a status reply got '$2'" %
          [$expected, $got])

proc raiseNoOK(status: string) =
  if status != "QUEUED" and status != "OK":
    raise newException(EInvalidReply, "Expected \"OK\" got \"$1\"" % status)

proc parseStatus(r: TRedis): TRedisStatus =
  var line = ""
  r.socket.readLine(line)
  if line == "":
    raise newException(ERedis, "Server closed connection prematurely")

  if line[0] == '-':
    raise newException(ERedis, strip(line))
  if line[0] != '+':
    raiseInvalidReply('+', line[0])
  
  return line.substr(1) # Strip '+'
  
proc parseInteger(r: TRedis): TRedisInteger =
  var line = ""
  r.socket.readLine(line)

  if line == "+QUEUED":  # inside of multi
    return -1

  if line == "":
    raise newException(ERedis, "Server closed connection prematurely")

  if line[0] == '-':
    raise newException(ERedis, strip(line))
  if line[0] != ':':
    raiseInvalidReply(':', line[0])
  
  # Strip ':'
  if parseBiggestInt(line, result, 1) == 0:
    raise newException(EInvalidReply, "Unable to parse integer.") 

proc recv(sock: TSocket, size: int): TaintedString =
  result = newString(size).TaintedString
  if sock.recv(cstring(result), size) != size:
    raise newException(EInvalidReply, "recv failed")

proc parseBulk(r: TRedis, allowMBNil = False): TRedisString =
  var line = ""
  r.socket.readLine(line.TaintedString)

  if line == "+QUEUED" or line == "+OK": # inside of a transaction (multi)
    return nil

  # Error.
  if line[0] == '-':
    raise newException(ERedis, strip(line))
  
  # Some commands return a /bulk/ value or a /multi-bulk/ nil. Odd.
  if allowMBNil:
    if line == "*-1":
       return RedisNil
  
  if line[0] != '$':
    raiseInvalidReply('$', line[0])
  
  var numBytes = parseInt(line.substr(1))
  if numBytes == -1:
    return RedisNil

  var s = r.socket.recv(numBytes+2)
  result = strip(s.string)

proc parseMultiBulk(r: TRedis): TRedisList =
  var line = TaintedString""
  r.socket.readLine(line)

  if line == "+QUEUED": # inside of a transaction (multi)
    return nil
    
  if line.string[0] != '*':
    raiseInvalidReply('*', line.string[0])
  
  var numElems = parseInt(line.string.substr(1))
  if numElems == -1: return nil
  result = @[]
  for i in 1..numElems:
    result.add(r.parseBulk())

proc sendCommand(r: TRedis, cmd: string, args: varargs[string]) =
  var request = "*" & $(1 + args.len()) & "\c\L"
  request.add("$" & $cmd.len() & "\c\L")
  request.add(cmd & "\c\L")
  for i in items(args):
    request.add("$" & $i.len() & "\c\L")
    request.add(i & "\c\L")
  r.socket.send(request)

proc sendCommand(r: TRedis, cmd: string, arg1: string,
                 args: varargs[string]) =
  var request = "*" & $(2 + args.len()) & "\c\L"
  request.add("$" & $cmd.len() & "\c\L")
  request.add(cmd & "\c\L")
  request.add("$" & $arg1.len() & "\c\L")
  request.add(arg1 & "\c\L")
  for i in items(args):
    request.add("$" & $i.len() & "\c\L")
    request.add(i & "\c\L")
  r.socket.send(request)

# Keys

proc del*(r: TRedis, keys: varargs[string]): TRedisInteger =
  ## Delete a key or multiple keys
  r.sendCommand("DEL", keys)
  return r.parseInteger()

proc exists*(r: TRedis, key: string): bool =
  ## Determine if a key exists
  r.sendCommand("EXISTS", key)
  return r.parseInteger() == 1

proc expire*(r: TRedis, key: string, seconds: int): bool =
  ## Set a key's time to live in seconds. Returns `false` if the key could
  ## not be found or the timeout could not be set.
  r.sendCommand("EXPIRE", key, $seconds)
  return r.parseInteger() == 1

proc expireAt*(r: TRedis, key: string, timestamp: int): bool =
  ## Set the expiration for a key as a UNIX timestamp. Returns `false` 
  ## if the key could not be found or the timeout could not be set.
  r.sendCommand("EXPIREAT", key, $timestamp)
  return r.parseInteger() == 1

proc keys*(r: TRedis, pattern: string): TRedisList =
  ## Find all keys matching the given pattern
  r.sendCommand("KEYS", pattern)
  return r.parseMultiBulk()

proc move*(r: TRedis, key: string, db: int): bool =
  ## Move a key to another database. Returns `true` on a successful move.
  r.sendCommand("MOVE", key, $db)
  return r.parseInteger() == 1

proc persist*(r: TRedis, key: string): bool =
  ## Remove the expiration from a key. 
  ## Returns `true` when the timeout was removed.
  r.sendCommand("PERSIST", key)
  return r.parseInteger() == 1
  
proc randomKey*(r: TRedis): TRedisString =
  ## Return a random key from the keyspace
  r.sendCommand("RANDOMKEY")
  return r.parseBulk()

proc rename*(r: TRedis, key, newkey: string): TRedisStatus =
  ## Rename a key.
  ## 
  ## **WARNING:** Overwrites `newkey` if it exists!
  r.sendCommand("RENAME", key, newkey)
  raiseNoOK(r.parseStatus())
  
proc renameNX*(r: TRedis, key, newkey: string): bool =
  ## Same as ``rename`` but doesn't continue if `newkey` exists.
  ## Returns `true` if key was renamed.
  r.sendCommand("RENAMENX", key, newkey)
  return r.parseInteger() == 1

proc ttl*(r: TRedis, key: string): TRedisInteger =
  ## Get the time to live for a key
  r.sendCommand("TTL", key)
  return r.parseInteger()
  
proc keyType*(r: TRedis, key: string): TRedisStatus =
  ## Determine the type stored at key
  r.sendCommand("TYPE", key)
  return r.parseStatus()
  

# Strings

proc append*(r: TRedis, key, value: string): TRedisInteger =
  ## Append a value to a key
  r.sendCommand("APPEND", key, value)
  return r.parseInteger()

proc decr*(r: TRedis, key: string): TRedisInteger =
  ## Decrement the integer value of a key by one
  r.sendCommand("DECR", key)
  return r.parseInteger()
  
proc decrBy*(r: TRedis, key: string, decrement: int): TRedisInteger =
  ## Decrement the integer value of a key by the given number
  r.sendCommand("DECRBY", key, $decrement)
  return r.parseInteger()
  
proc get*(r: TRedis, key: string): TRedisString =
  ## Get the value of a key. Returns `redisNil` when `key` doesn't exist.
  r.sendCommand("GET", key)
  return r.parseBulk()

proc getBit*(r: TRedis, key: string, offset: int): TRedisInteger =
  ## Returns the bit value at offset in the string value stored at key
  r.sendCommand("GETBIT", key, $offset)
  return r.parseInteger()

proc getRange*(r: TRedis, key: string, start, stop: int): TRedisString =
  ## Get a substring of the string stored at a key
  r.sendCommand("GETRANGE", key, $start, $stop)
  return r.parseBulk()

proc getSet*(r: TRedis, key: string, value: string): TRedisString =
  ## Set the string value of a key and return its old value. Returns `redisNil`
  ## when key doesn't exist.
  r.sendCommand("GETSET", key, value)
  return r.parseBulk()

proc incr*(r: TRedis, key: string): TRedisInteger =
  ## Increment the integer value of a key by one.
  r.sendCommand("INCR", key)
  return r.parseInteger()

proc incrBy*(r: TRedis, key: string, increment: int): TRedisInteger =
  ## Increment the integer value of a key by the given number
  r.sendCommand("INCRBY", key, $increment)
  return r.parseInteger()

proc setk*(r: TRedis, key, value: string) = 
  ## Set the string value of a key.
  ##
  ## NOTE: This function had to be renamed due to a clash with the `set` type.
  r.sendCommand("SET", key, value)
  raiseNoOK(r.parseStatus())

proc setNX*(r: TRedis, key, value: string): bool =
  ## Set the value of a key, only if the key does not exist. Returns `true`
  ## if the key was set.
  r.sendCommand("SETNX", key, value)
  return r.parseInteger() == 1

proc setBit*(r: TRedis, key: string, offset: int, 
             value: string): TRedisInteger =
  ## Sets or clears the bit at offset in the string value stored at key
  r.sendCommand("SETBIT", key, $offset, value)
  return r.parseInteger()
  
proc setEx*(r: TRedis, key: string, seconds: int, value: string): TRedisStatus =
  ## Set the value and expiration of a key
  r.sendCommand("SETEX", key, $seconds, value)
  raiseNoOK(r.parseStatus())

proc setRange*(r: TRedis, key: string, offset: int, 
               value: string): TRedisInteger =
  ## Overwrite part of a string at key starting at the specified offset
  r.sendCommand("SETRANGE", key, $offset, value)
  return r.parseInteger()

proc strlen*(r: TRedis, key: string): TRedisInteger =
  ## Get the length of the value stored in a key. Returns 0 when key doesn't
  ## exist.
  r.sendCommand("STRLEN", key)
  return r.parseInteger()

# Hashes
proc hDel*(r: TRedis, key, field: string): bool =
  ## Delete a hash field at `key`. Returns `true` if the field was removed.
  r.sendCommand("HDEL", key, field)
  return r.parseInteger() == 1

proc hExists*(r: TRedis, key, field: string): bool =
  ## Determine if a hash field exists.
  r.sendCommand("HEXISTS", key, field)
  return r.parseInteger() == 1

proc hGet*(r: TRedis, key, field: string): TRedisString =
  ## Get the value of a hash field
  r.sendCommand("HGET", key, field)
  return r.parseBulk()

proc hGetAll*(r: TRedis, key: string): TRedisList =
  ## Get all the fields and values in a hash
  r.sendCommand("HGETALL", key)
  return r.parseMultiBulk()

proc hIncrBy*(r: TRedis, key, field: string, incr: int): TRedisInteger =
  ## Increment the integer value of a hash field by the given number
  r.sendCommand("HINCRBY", key, field, $incr)
  return r.parseInteger()

proc hKeys*(r: TRedis, key: string): TRedisList =
  ## Get all the fields in a hash
  r.sendCommand("HKEYS", key)
  return r.parseMultiBulk()

proc hLen*(r: TRedis, key: string): TRedisInteger =
  ## Get the number of fields in a hash
  r.sendCommand("HLEN", key)
  return r.parseInteger()

proc hMGet*(r: TRedis, key: string, fields: varargs[string]): TRedisList =
  ## Get the values of all the given hash fields
  r.sendCommand("HMGET", key, fields)
  return r.parseMultiBulk()

proc hMSet*(r: TRedis, key: string, 
            fieldValues: openarray[tuple[field, value: string]]) =
  ## Set multiple hash fields to multiple values
  var args = @[key]
  for field, value in items(fieldValues):
    args.add(field)
    args.add(value)
  r.sendCommand("HMSET", args)
  raiseNoOK(r.parseStatus())

proc hSet*(r: TRedis, key, field, value: string): TRedisInteger =
  ## Set the string value of a hash field
  r.sendCommand("HSET", key, field, value)
  return r.parseInteger()
  
proc hSetNX*(r: TRedis, key, field, value: string): TRedisInteger =
  ## Set the value of a hash field, only if the field does **not** exist
  r.sendCommand("HSETNX", key, field, value)
  return r.parseInteger()

proc hVals*(r: TRedis, key: string): TRedisList =
  ## Get all the values in a hash
  r.sendCommand("HVALS", key)
  return r.parseMultiBulk()
  
# Lists

proc bLPop*(r: TRedis, keys: varargs[string], timeout: int): TRedisList =
  ## Remove and get the *first* element in a list, or block until 
  ## one is available
  var args: seq[string] = @[]
  for i in items(keys): args.add(i)
  args.add($timeout)
  r.sendCommand("BLPOP", args)
  return r.parseMultiBulk()

proc bRPop*(r: TRedis, keys: varargs[string], timeout: int): TRedisList =
  ## Remove and get the *last* element in a list, or block until one 
  ## is available.
  var args: seq[string] = @[]
  for i in items(keys): args.add(i)
  args.add($timeout)
  r.sendCommand("BRPOP", args)
  return r.parseMultiBulk()

proc bRPopLPush*(r: TRedis, source, destination: string,
                 timeout: int): TRedisString =
  ## Pop a value from a list, push it to another list and return it; or
  ## block until one is available.
  ##
  ## http://redis.io/commands/brpoplpush
  r.sendCommand("BRPOPLPUSH", source, destination, $timeout)
  return r.parseBulk(true) # Multi-Bulk nil allowed.

proc lIndex*(r: TRedis, key: string, index: int): TRedisString =
  ## Get an element from a list by its index
  r.sendCommand("LINDEX", key, $index)
  return r.parseBulk()

proc lInsert*(r: TRedis, key: string, before: bool, pivot, value: string):
              TRedisInteger =
  ## Insert an element before or after another element in a list
  var pos = if before: "BEFORE" else: "AFTER"
  r.sendCommand("LINSERT", key, pos, pivot, value)
  return r.parseInteger()
  
proc lLen*(r: TRedis, key: string): TRedisInteger =
  ## Get the length of a list
  r.sendCommand("LLEN", key)
  return r.parseInteger()

proc lPop*(r: TRedis, key: string): TRedisString =
  ## Remove and get the first element in a list
  r.sendCommand("LPOP", key)
  return r.parseBulk()

proc lPush*(r: TRedis, key, value: string, create: bool = True): TRedisInteger =
  ## Prepend a value to a list. Returns the length of the list after the push.
  ## The ``create`` param specifies whether a list should be created if it
  ## doesn't exist at ``key``. More specifically if ``create`` is True, `LPUSH` 
  ## will be used, otherwise `LPUSHX`.
  if create:
    r.sendCommand("LPUSH", key, value)
  else:
    r.sendCommand("LPUSHX", key, value)
  return r.parseInteger()

proc lRange*(r: TRedis, key: string, start, stop: int): TRedisList =
  ## Get a range of elements from a list. Returns `nil` when `key` 
  ## doesn't exist.
  r.sendCommand("LRANGE", key, $start, $stop)
  return r.parseMultiBulk()

proc lRem*(r: TRedis, key: string, value: string, count: int = 0): TRedisInteger =
  ## Remove elements from a list. Returns the number of elements that have been
  ## removed.
  r.sendCommand("LREM", key, $count, value)
  return r.parseInteger()

proc lSet*(r: TRedis, key: string, index: int, value: string) =
  ## Set the value of an element in a list by its index
  r.sendCommand("LSET", key, $index, value)
  raiseNoOK(r.parseStatus())

proc lTrim*(r: TRedis, key: string, start, stop: int) =
  ## Trim a list to the specified range
  r.sendCommand("LTRIM", key, $start, $stop)
  raiseNoOK(r.parseStatus())

proc rPop*(r: TRedis, key: string): TRedisString =
  ## Remove and get the last element in a list
  r.sendCommand("RPOP", key)
  return r.parseBulk()
  
proc rPopLPush*(r: TRedis, source, destination: string): TRedisString =
  ## Remove the last element in a list, append it to another list and return it
  r.sendCommand("RPOPLPUSH", source, destination)
  return r.parseBulk()
  
proc rPush*(r: TRedis, key, value: string, create: bool = True): TRedisInteger =
  ## Append a value to a list. Returns the length of the list after the push.
  ## The ``create`` param specifies whether a list should be created if it
  ## doesn't exist at ``key``. More specifically if ``create`` is True, `RPUSH` 
  ## will be used, otherwise `RPUSHX`.
  if create:
    r.sendCommand("RPUSH", key, value)
  else:
    r.sendCommand("RPUSHX", key, value)
  return r.parseInteger()

# Sets

proc sadd*(r: TRedis, key: string, member: string): TRedisInteger =
  ## Add a member to a set
  r.sendCommand("SADD", key, member)
  return r.parseInteger()

proc scard*(r: TRedis, key: string): TRedisInteger =
  ## Get the number of members in a set
  r.sendCommand("SCARD", key)
  return r.parseInteger()

proc sdiff*(r: TRedis, keys: varargs[string]): TRedisList =
  ## Subtract multiple sets
  r.sendCommand("SDIFF", keys)
  return r.parseMultiBulk()

proc sdiffstore*(r: TRedis, destination: string,
                keys: varargs[string]): TRedisInteger =
  ## Subtract multiple sets and store the resulting set in a key
  r.sendCommand("SDIFFSTORE", destination, keys)
  return r.parseInteger()

proc sinter*(r: TRedis, keys: varargs[string]): TRedisList =
  ## Intersect multiple sets
  r.sendCommand("SINTER", keys)
  return r.parseMultiBulk()

proc sinterstore*(r: TRedis, destination: string,
                 keys: varargs[string]): TRedisInteger =
  ## Intersect multiple sets and store the resulting set in a key
  r.sendCommand("SINTERSTORE", destination, keys)
  return r.parseInteger()

proc sismember*(r: TRedis, key: string, member: string): TRedisInteger =
  ## Determine if a given value is a member of a set
  r.sendCommand("SISMEMBER", key, member)
  return r.parseInteger()

proc smembers*(r: TRedis, key: string): TRedisList =
  ## Get all the members in a set
  r.sendCommand("SMEMBERS", key)
  return r.parseMultiBulk()

proc smove*(r: TRedis, source: string, destination: string,
           member: string): TRedisInteger =
  ## Move a member from one set to another
  r.sendCommand("SMOVE", source, destination, member)
  return r.parseInteger()

proc spop*(r: TRedis, key: string): TRedisString =
  ## Remove and return a random member from a set
  r.sendCommand("SPOP", key)
  return r.parseBulk()

proc srandmember*(r: TRedis, key: string): TRedisString =
  ## Get a random member from a set
  r.sendCommand("SRANDMEMBER", key)
  return r.parseBulk()

proc srem*(r: TRedis, key: string, member: string): TRedisInteger =
  ## Remove a member from a set
  r.sendCommand("SREM", key, member)
  return r.parseInteger()

proc sunion*(r: TRedis, keys: varargs[string]): TRedisList =
  ## Add multiple sets
  r.sendCommand("SUNION", keys)
  return r.parseMultiBulk()

proc sunionstore*(r: TRedis, destination: string,
                 key: varargs[string]): TRedisInteger =
  ## Add multiple sets and store the resulting set in a key 
  r.sendCommand("SUNIONSTORE", destination, key)
  return r.parseInteger()

# Sorted sets

proc zadd*(r: TRedis, key: string, score: int, member: string): TRedisInteger =
  ## Add a member to a sorted set, or update its score if it already exists
  r.sendCommand("ZADD", key, $score, member)
  return r.parseInteger()

proc zcard*(r: TRedis, key: string): TRedisInteger =
  ## Get the number of members in a sorted set
  r.sendCommand("ZCARD", key)
  return r.parseInteger()

proc zcount*(r: TRedis, key: string, min: string, max: string): TRedisInteger =
  ## Count the members in a sorted set with scores within the given values
  r.sendCommand("ZCOUNT", key, min, max)
  return r.parseInteger()

proc zincrby*(r: TRedis, key: string, increment: string,
             member: string): TRedisString =
  ## Increment the score of a member in a sorted set
  r.sendCommand("ZINCRBY", key, increment, member)
  return r.parseBulk()

proc zinterstore*(r: TRedis, destination: string, numkeys: string,
                 keys: openarray[string], weights: openarray[string] = [],
                 aggregate: string = ""): TRedisInteger =
  ## Intersect multiple sorted sets and store the resulting sorted set in
  ## a new key
  var args = @[destination, numkeys]
  for i in items(keys): args.add(i)
  
  if weights.len != 0:
    args.add("WITHSCORE")
    for i in items(weights): args.add(i)
  if aggregate.len != 0:
    args.add("AGGREGATE")
    args.add(aggregate)
    
  r.sendCommand("ZINTERSTORE", args)
  
  return r.parseInteger()

proc zrange*(r: TRedis, key: string, start: string, stop: string,
            withScores: bool): TRedisList =
  ## Return a range of members in a sorted set, by index
  if not withScores:
    r.sendCommand("ZRANGE", key, start, stop)
  else:
    r.sendCommand("ZRANGE", "WITHSCORES", key, start, stop)
  return r.parseMultiBulk()

proc zrangebyscore*(r: TRedis, key: string, min: string, max: string, 
                   withScore: bool = false, limit: bool = False,
                   limitOffset: int = 0, limitCount: int = 0): TRedisList =
  ## Return a range of members in a sorted set, by score
  var args = @[key, min, max]
  
  if withScore: args.add("WITHSCORE")
  if limit: 
    args.add("LIMIT")
    args.add($limitOffset)
    args.add($limitCount)
    
  r.sendCommand("ZRANGEBYSCORE", args)
  return r.parseMultiBulk()

proc zrank*(r: TRedis, key: string, member: string): TRedisString =
  ## Determine the index of a member in a sorted set
  r.sendCommand("ZRANK", key, member)
  return r.parseBulk()

proc zrem*(r: TRedis, key: string, member: string): TRedisInteger =
  ## Remove a member from a sorted set
  r.sendCommand("ZREM", key, member)
  return r.parseInteger()

proc zremrangebyrank*(r: TRedis, key: string, start: string,
                     stop: string): TRedisInteger =
  ## Remove all members in a sorted set within the given indexes
  r.sendCommand("ZREMRANGEBYRANK", key, start, stop)
  return r.parseInteger()

proc zremrangebyscore*(r: TRedis, key: string, min: string,
                      max: string): TRedisInteger =
  ## Remove all members in a sorted set within the given scores
  r.sendCommand("ZREMRANGEBYSCORE", key, min, max)
  return r.parseInteger()

proc zrevrange*(r: TRedis, key: string, start: string, stop: string,
               withScore: bool): TRedisList =
  ## Return a range of members in a sorted set, by index, 
  ## with scores ordered from high to low
  if withScore:
    r.sendCommand("ZREVRANGE", "WITHSCORE", key, start, stop)
  else: r.sendCommand("ZREVRANGE", key, start, stop)
  return r.parseMultiBulk()

proc zrevrangebyscore*(r: TRedis, key: string, min: string, max: string, 
                   withScore: bool = false, limit: bool = False,
                   limitOffset: int = 0, limitCount: int = 0): TRedisList =
  ## Return a range of members in a sorted set, by score, with
  ## scores ordered from high to low
  var args = @[key, min, max]
  
  if withScore: args.add("WITHSCORE")
  if limit: 
    args.add("LIMIT")
    args.add($limitOffset)
    args.add($limitCount)
  
  r.sendCommand("ZREVRANGEBYSCORE", args)
  return r.parseMultiBulk()

proc zrevrank*(r: TRedis, key: string, member: string): TRedisString =
  ## Determine the index of a member in a sorted set, with
  ## scores ordered from high to low
  r.sendCommand("ZREVRANK", key, member)
  return r.parseBulk()

proc zscore*(r: TRedis, key: string, member: string): TRedisString =
  ## Get the score associated with the given member in a sorted set
  r.sendCommand("ZSCORE", key, member)
  return r.parseBulk()

proc zunionstore*(r: TRedis, destination: string, numkeys: string,
                 keys: openarray[string], weights: openarray[string] = [],
                 aggregate: string = ""): TRedisInteger =
  ## Add multiple sorted sets and store the resulting sorted set in a new key 
  var args = @[destination, numkeys]
  for i in items(keys): args.add(i)
  
  if weights.len != 0:
    args.add("WEIGHTS")
    for i in items(weights): args.add(i)
  if aggregate.len != 0:
    args.add("AGGREGATE")
    args.add(aggregate)
    
  r.sendCommand("ZUNIONSTORE", args)
  
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

proc discardMulti*(r: TRedis) =
  ## Discard all commands issued after MULTI
  r.sendCommand("DISCARD")
  raiseNoOK(r.parseStatus())

proc exec*(r: TRedis): TRedisList =
  ## Execute all commands issued after MULTI
  r.sendCommand("EXEC")

  return r.parseMultiBulk()

proc multi*(r: TRedis) =
  ## Mark the start of a transaction block
  r.sendCommand("MULTI")
  raiseNoOK(r.parseStatus())

proc unwatch*(r: TRedis) =
  ## Forget about all watched keys
  r.sendCommand("UNWATCH")
  raiseNoOK(r.parseStatus())

proc watch*(r: TRedis, key: varargs[string]) =
  ## Watch the given keys to determine execution of the MULTI/EXEC block 
  r.sendCommand("WATCH", key)
  raiseNoOK(r.parseStatus())

# Connection

proc auth*(r: TRedis, password: string) =
  ## Authenticate to the server
  r.sendCommand("AUTH", password)
  raiseNoOK(r.parseStatus())

proc echoServ*(r: TRedis, message: string): TRedisString =
  ## Echo the given string
  r.sendCommand("ECHO", message)
  return r.parseBulk()

proc ping*(r: TRedis): TRedisStatus =
  ## Ping the server
  r.sendCommand("PING")
  return r.parseStatus()

proc quit*(r: TRedis) =
  ## Close the connection
  r.sendCommand("QUIT")
  raiseNoOK(r.parseStatus())

proc select*(r: TRedis, index: int): TRedisStatus =
  ## Change the selected database for the current connection 
  r.sendCommand("SELECT", $index)
  return r.parseStatus()

# Server

proc bgrewriteaof*(r: TRedis) =
  ## Asynchronously rewrite the append-only file
  r.sendCommand("BGREWRITEAOF")
  raiseNoOK(r.parseStatus())

proc bgsave*(r: TRedis) =
  ## Asynchronously save the dataset to disk
  r.sendCommand("BGSAVE")
  raiseNoOK(r.parseStatus())

proc configGet*(r: TRedis, parameter: string): TRedisList =
  ## Get the value of a configuration parameter
  r.sendCommand("CONFIG", "GET", parameter)
  return r.parseMultiBulk()

proc configSet*(r: TRedis, parameter: string, value: string) =
  ## Set a configuration parameter to the given value
  r.sendCommand("CONFIG", "SET", parameter, value)
  raiseNoOK(r.parseStatus())

proc configResetStat*(r: TRedis) =
  ## Reset the stats returned by INFO
  r.sendCommand("CONFIG", "RESETSTAT")
  raiseNoOK(r.parseStatus())

proc dbsize*(r: TRedis): TRedisInteger =
  ## Return the number of keys in the selected database
  r.sendCommand("DBSIZE")
  return r.parseInteger()

proc debugObject*(r: TRedis, key: string): TRedisStatus =
  ## Get debugging information about a key
  r.sendCommand("DEBUG", "OBJECT", key)
  return r.parseStatus()

proc debugSegfault*(r: TRedis) =
  ## Make the server crash
  r.sendCommand("DEBUG", "SEGFAULT")

proc flushall*(r: TRedis): TRedisStatus =
  ## Remove all keys from all databases
  r.sendCommand("FLUSHALL")
  raiseNoOK(r.parseStatus())

proc flushdb*(r: TRedis): TRedisStatus =
  ## Remove all keys from the current database
  r.sendCommand("FLUSHDB")
  raiseNoOK(r.parseStatus())

proc info*(r: TRedis): TRedisString =
  ## Get information and statistics about the server
  r.sendCommand("INFO")
  return r.parseBulk()

proc lastsave*(r: TRedis): TRedisInteger =
  ## Get the UNIX time stamp of the last successful save to disk
  r.sendCommand("LASTSAVE")
  return r.parseInteger()

discard """
proc monitor*(r: TRedis) =
  ## Listen for all requests received by the server in real time
  r.socket.send("MONITOR\c\L")
  raiseNoOK(r.parseStatus())
"""

proc save*(r: TRedis) =
  ## Synchronously save the dataset to disk
  r.sendCommand("SAVE")
  raiseNoOK(r.parseStatus())

proc shutdown*(r: TRedis) =
  ## Synchronously save the dataset to disk and then shut down the server
  r.sendCommand("SHUTDOWN")
  var s = "".TaintedString
  r.socket.readLine(s)
  if s.string.len != 0: raise newException(ERedis, s.string)

proc slaveof*(r: TRedis, host: string, port: string) =
  ## Make the server a slave of another instance, or promote it as master
  r.sendCommand("SLAVEOF", host, port)
  raiseNoOK(r.parseStatus())

iterator hPairs*(r: TRedis, key: string): tuple[key, value: string] =
  ## Iterator for keys and values in a hash.
  var 
    contents = r.hGetAll(key)
    k = ""
  for i in items(contents):
    if k == "":
      k = i
    else:
      yield (k, i)
      k = ""
      

when false:
  # sorry, deactivated for the test suite
  var r = open()
  r.auth("pass")

  r.setk("nim:test", "Testing something.")
  r.setk("nim:utf8", "こんにちは")
  r.setk("nim:esc", "\\ths ągt\\")
  
  echo r.get("nim:esc")
  echo r.incr("nim:int")
  echo r.incr("nim:int")
  echo r.get("nim:int")
  echo r.get("nim:utf8")
  echo repr(r.get("blahasha"))
  echo r.randomKey()
  
  var p = r.lrange("mylist", 0, -1)
  for i in items(p):
    echo("  ", i)

  echo(r.debugObject("test"))

  r.configSet("timeout", "299")
  for i in items(r.configGet("timeout")): echo ">> ", i

  echo r.echoServ("BLAH")

