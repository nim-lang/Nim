#
#
#            Nim's Runtime Library
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
  Pipeline = ref object
    enabled: bool
    buffer: string
    expected: int ## number of replies expected if pipelined

type
  SendMode = enum
    normal, pipelined, multiple

type
  Redis* = object
    socket: Socket
    connected: bool
    pipeline: Pipeline
  
  RedisStatus* = string
  RedisInteger* = BiggestInt
  RedisString* = string ## Bulk reply
  RedisList* = seq[RedisString] ## Multi-bulk reply

  ReplyError* = object of IOError ## Invalid reply from redis
  RedisError* = object of IOError        ## Error in redis

{.deprecated: [TSendMode: SendMode, TRedis: Redis, TRedisStatus: RedisStatus,
     TRedisInteger: RedisInteger, TRedisString: RedisString,
     TRedisList: RedisList, EInvalidReply: ReplyError, ERedis: RedisError].}

proc newPipeline(): Pipeline =
  new(result)
  result.buffer = ""
  result.enabled = false
  result.expected = 0

proc open*(host = "localhost", port = 6379.Port): Redis =
  ## Opens a connection to the redis server.
  result.socket = socket(buffered = false)
  if result.socket == invalidSocket:
    raiseOSError(osLastError())
  result.socket.connect(host, port)
  result.pipeline = newPipeline()  

proc raiseInvalidReply(expected, got: char) =
  raise newException(ReplyError, 
          "Expected '$1' at the beginning of a status reply got '$2'" %
          [$expected, $got])

proc raiseNoOK(status: string, pipelineEnabled: bool) =
  if pipelineEnabled and not (status == "QUEUED" or status == "PIPELINED"):
    raise newException(ReplyError, "Expected \"QUEUED\" or \"PIPELINED\" got \"$1\"" % status)
  elif not pipelineEnabled and status != "OK":
    raise newException(ReplyError, "Expected \"OK\" got \"$1\"" % status)

template readSocket(r: Redis, dummyVal:expr): stmt =
  var line {.inject.}: TaintedString = ""
  if r.pipeline.enabled:
    return dummyVal
  else:
    readLine(r.socket, line)

proc parseStatus(r: Redis, line: string = ""): RedisStatus =
  if r.pipeline.enabled:
    return "PIPELINED"

  if line == "":
    raise newException(RedisError, "Server closed connection prematurely")

  if line[0] == '-':
    raise newException(RedisError, strip(line))
  if line[0] != '+':
    raiseInvalidReply('+', line[0])
  
  return line.substr(1) # Strip '+'

proc readStatus(r:Redis): RedisStatus =
  r.readSocket("PIPELINED")
  return r.parseStatus(line)
 
proc parseInteger(r: Redis, line: string = ""): RedisInteger =
  if r.pipeline.enabled: return -1
  
  #if line == "+QUEUED":  # inside of multi
  #  return -1

  if line == "":
    raise newException(RedisError, "Server closed connection prematurely")

  if line[0] == '-':
    raise newException(RedisError, strip(line))
  if line[0] != ':':
    raiseInvalidReply(':', line[0])
  
  # Strip ':'
  if parseBiggestInt(line, result, 1) == 0:
    raise newException(ReplyError, "Unable to parse integer.") 

proc readInteger(r: Redis): RedisInteger =
  r.readSocket(-1)
  return r.parseInteger(line)

proc recv(sock: Socket, size: int): TaintedString =
  result = newString(size).TaintedString
  if sock.recv(cstring(result), size) != size:
    raise newException(ReplyError, "recv failed")

proc parseSingleString(r: Redis, line:string, allowMBNil = false): RedisString =
  if r.pipeline.enabled: return ""
  
  # Error.
  if line[0] == '-':
    raise newException(RedisError, strip(line))
  
  # Some commands return a /bulk/ value or a /multi-bulk/ nil. Odd.
  if allowMBNil:
    if line == "*-1":
       return redisNil
  
  if line[0] != '$':
    raiseInvalidReply('$', line[0])
  
  var numBytes = parseInt(line.substr(1))
  if numBytes == -1:
    return redisNil

  var s = r.socket.recv(numBytes+2)
  result = strip(s.string)

proc readSingleString(r: Redis): RedisString =
  r.readSocket("")
  return r.parseSingleString(line)

proc readNext(r: Redis): RedisList

proc parseArrayLines(r: Redis, countLine:string): RedisList =
  if countLine.string[0] != '*':
    raiseInvalidReply('*', countLine.string[0])

  var numElems = parseInt(countLine.string.substr(1))
  if numElems == -1: return nil
  result = @[]

  for i in 1..numElems:
    var parsed = r.readNext()
    if not isNil(parsed):
      for item in parsed:
        result.add(item)

proc readArrayLines(r: Redis): RedisList =
  r.readSocket(nil)
  return r.parseArrayLines(line)  

proc parseBulkString(r: Redis, allowMBNil = false, line:string = ""): RedisString =
  if r.pipeline.enabled: return ""

  return r.parseSingleString(line, allowMBNil)

proc readBulkString(r: Redis, allowMBNil = false): RedisString =
  r.readSocket("")
  return r.parseBulkString(allowMBNil, line)

proc readArray(r: Redis): RedisList =
  r.readSocket(@[])
  return r.parseArrayLines(line)

proc readNext(r: Redis): RedisList =
  r.readSocket(@[])

  var res = case line[0]
    of '+', '-': @[r.parseStatus(line)]
    of ':': @[$(r.parseInteger(line))]
    of '$': @[r.parseBulkString(true,line)]
    of '*': r.parseArrayLines(line)
    else: 
      raise newException(ReplyError, "readNext failed on line: " & line)
      nil
  r.pipeline.expected -= 1
  return res

proc flushPipeline*(r: Redis, wasMulti = false): RedisList =
  ## Send buffered commands, clear buffer, return results
  if r.pipeline.buffer.len > 0:
    r.socket.send(r.pipeline.buffer)
  r.pipeline.buffer = ""
  
  r.pipeline.enabled = false
  result = @[]
  
  var tot = r.pipeline.expected

  for i in 0..tot-1:
    var ret = r.readNext()
    for item in ret:
     if not (item.contains("OK") or item.contains("QUEUED")):
       result.add(item)

  r.pipeline.expected = 0

proc startPipelining*(r: Redis) =
  ## Enable command pipelining (reduces network roundtrips).
  ## Note that when enabled, you must call flushPipeline to actually send commands, except
  ## for multi/exec() which enable and flush the pipeline automatically.
  ## Commands return immediately with dummy values; actual results returned from
  ## flushPipeline() or exec()
  r.pipeline.expected = 0
  r.pipeline.enabled = true

proc sendCommand(r: Redis, cmd: string, args: varargs[string]) =
  var request = "*" & $(1 + args.len()) & "\c\L"
  request.add("$" & $cmd.len() & "\c\L")
  request.add(cmd & "\c\L")
  for i in items(args):
    request.add("$" & $i.len() & "\c\L")
    request.add(i & "\c\L")
  
  if r.pipeline.enabled:
    r.pipeline.buffer.add(request)
    r.pipeline.expected += 1
  else:
    r.socket.send(request)

proc sendCommand(r: Redis, cmd: string, arg1: string,
                 args: varargs[string]) =
  var request = "*" & $(2 + args.len()) & "\c\L"
  request.add("$" & $cmd.len() & "\c\L")
  request.add(cmd & "\c\L")
  request.add("$" & $arg1.len() & "\c\L")
  request.add(arg1 & "\c\L")
  for i in items(args):
    request.add("$" & $i.len() & "\c\L")
    request.add(i & "\c\L")
    
  if r.pipeline.enabled:
    r.pipeline.expected += 1
    r.pipeline.buffer.add(request)
  else:
    r.socket.send(request)

# Keys

proc del*(r: Redis, keys: varargs[string]): RedisInteger =
  ## Delete a key or multiple keys
  r.sendCommand("DEL", keys)
  return r.readInteger()

proc exists*(r: Redis, key: string): bool =
  ## Determine if a key exists
  r.sendCommand("EXISTS", key)
  return r.readInteger() == 1

proc expire*(r: Redis, key: string, seconds: int): bool =
  ## Set a key's time to live in seconds. Returns `false` if the key could
  ## not be found or the timeout could not be set.
  r.sendCommand("EXPIRE", key, $seconds)
  return r.readInteger() == 1

proc expireAt*(r: Redis, key: string, timestamp: int): bool =
  ## Set the expiration for a key as a UNIX timestamp. Returns `false` 
  ## if the key could not be found or the timeout could not be set.
  r.sendCommand("EXPIREAT", key, $timestamp)
  return r.readInteger() == 1

proc keys*(r: Redis, pattern: string): RedisList =
  ## Find all keys matching the given pattern
  r.sendCommand("KEYS", pattern)
  return r.readArray()

proc scan*(r: Redis, cursor: var BiggestInt): RedisList =
  ## Find all keys matching the given pattern and yield it to client in portions
  ## using default Redis values for MATCH and COUNT parameters
  r.sendCommand("SCAN", $cursor)
  let reply = r.readArray()
  cursor = strutils.parseBiggestInt(reply[0])
  return reply[1..high(reply)]

proc scan*(r: Redis, cursor: var BiggestInt, pattern: string): RedisList =
  ## Find all keys matching the given pattern and yield it to client in portions
  ## using cursor as a client query identifier. Using default Redis value for COUNT argument
  r.sendCommand("SCAN", $cursor, ["MATCH", pattern])
  let reply = r.readArray()
  cursor = strutils.parseBiggestInt(reply[0])
  return reply[1..high(reply)]

proc scan*(r: Redis, cursor: var BiggestInt, pattern: string, count: int): RedisList = 
  ## Find all keys matching the given pattern and yield it to client in portions
  ## using cursor as a client query identifier.
  r.sendCommand("SCAN", $cursor, ["MATCH", pattern, "COUNT", $count])
  let reply = r.readArray()
  cursor = strutils.parseBiggestInt(reply[0])
  return reply[1..high(reply)]

proc move*(r: Redis, key: string, db: int): bool =
  ## Move a key to another database. Returns `true` on a successful move.
  r.sendCommand("MOVE", key, $db)
  return r.readInteger() == 1

proc persist*(r: Redis, key: string): bool =
  ## Remove the expiration from a key. 
  ## Returns `true` when the timeout was removed.
  r.sendCommand("PERSIST", key)
  return r.readInteger() == 1
  
proc randomKey*(r: Redis): RedisString =
  ## Return a random key from the keyspace
  r.sendCommand("RANDOMKEY")
  return r.readBulkString()

proc rename*(r: Redis, key, newkey: string): RedisStatus =
  ## Rename a key.
  ## 
  ## **WARNING:** Overwrites `newkey` if it exists!
  r.sendCommand("RENAME", key, newkey)
  raiseNoOK(r.readStatus(), r.pipeline.enabled)
  
proc renameNX*(r: Redis, key, newkey: string): bool =
  ## Same as ``rename`` but doesn't continue if `newkey` exists.
  ## Returns `true` if key was renamed.
  r.sendCommand("RENAMENX", key, newkey)
  return r.readInteger() == 1

proc ttl*(r: Redis, key: string): RedisInteger =
  ## Get the time to live for a key
  r.sendCommand("TTL", key)
  return r.readInteger()
  
proc keyType*(r: Redis, key: string): RedisStatus =
  ## Determine the type stored at key
  r.sendCommand("TYPE", key)
  return r.readStatus()
  

# Strings

proc append*(r: Redis, key, value: string): RedisInteger =
  ## Append a value to a key
  r.sendCommand("APPEND", key, value)
  return r.readInteger()

proc decr*(r: Redis, key: string): RedisInteger =
  ## Decrement the integer value of a key by one
  r.sendCommand("DECR", key)
  return r.readInteger()
  
proc decrBy*(r: Redis, key: string, decrement: int): RedisInteger =
  ## Decrement the integer value of a key by the given number
  r.sendCommand("DECRBY", key, $decrement)
  return r.readInteger()
  
proc get*(r: Redis, key: string): RedisString =
  ## Get the value of a key. Returns `redisNil` when `key` doesn't exist.
  r.sendCommand("GET", key)
  return r.readBulkString()

proc getBit*(r: Redis, key: string, offset: int): RedisInteger =
  ## Returns the bit value at offset in the string value stored at key
  r.sendCommand("GETBIT", key, $offset)
  return r.readInteger()

proc getRange*(r: Redis, key: string, start, stop: int): RedisString =
  ## Get a substring of the string stored at a key
  r.sendCommand("GETRANGE", key, $start, $stop)
  return r.readBulkString()

proc getSet*(r: Redis, key: string, value: string): RedisString =
  ## Set the string value of a key and return its old value. Returns `redisNil`
  ## when key doesn't exist.
  r.sendCommand("GETSET", key, value)
  return r.readBulkString()

proc incr*(r: Redis, key: string): RedisInteger =
  ## Increment the integer value of a key by one.
  r.sendCommand("INCR", key)
  return r.readInteger()

proc incrBy*(r: Redis, key: string, increment: int): RedisInteger =
  ## Increment the integer value of a key by the given number
  r.sendCommand("INCRBY", key, $increment)
  return r.readInteger()

proc setk*(r: Redis, key, value: string) = 
  ## Set the string value of a key.
  ##
  ## NOTE: This function had to be renamed due to a clash with the `set` type.
  r.sendCommand("SET", key, value)
  raiseNoOK(r.readStatus(), r.pipeline.enabled)

proc setNX*(r: Redis, key, value: string): bool =
  ## Set the value of a key, only if the key does not exist. Returns `true`
  ## if the key was set.
  r.sendCommand("SETNX", key, value)
  return r.readInteger() == 1

proc setBit*(r: Redis, key: string, offset: int, 
             value: string): RedisInteger =
  ## Sets or clears the bit at offset in the string value stored at key
  r.sendCommand("SETBIT", key, $offset, value)
  return r.readInteger()
  
proc setEx*(r: Redis, key: string, seconds: int, value: string): RedisStatus =
  ## Set the value and expiration of a key
  r.sendCommand("SETEX", key, $seconds, value)
  raiseNoOK(r.readStatus(), r.pipeline.enabled)

proc setRange*(r: Redis, key: string, offset: int, 
               value: string): RedisInteger =
  ## Overwrite part of a string at key starting at the specified offset
  r.sendCommand("SETRANGE", key, $offset, value)
  return r.readInteger()

proc strlen*(r: Redis, key: string): RedisInteger =
  ## Get the length of the value stored in a key. Returns 0 when key doesn't
  ## exist.
  r.sendCommand("STRLEN", key)
  return r.readInteger()

# Hashes
proc hDel*(r: Redis, key, field: string): bool =
  ## Delete a hash field at `key`. Returns `true` if the field was removed.
  r.sendCommand("HDEL", key, field)
  return r.readInteger() == 1

proc hExists*(r: Redis, key, field: string): bool =
  ## Determine if a hash field exists.
  r.sendCommand("HEXISTS", key, field)
  return r.readInteger() == 1

proc hGet*(r: Redis, key, field: string): RedisString =
  ## Get the value of a hash field
  r.sendCommand("HGET", key, field)
  return r.readBulkString()

proc hGetAll*(r: Redis, key: string): RedisList =
  ## Get all the fields and values in a hash
  r.sendCommand("HGETALL", key)
  return r.readArray()

proc hIncrBy*(r: Redis, key, field: string, incr: int): RedisInteger =
  ## Increment the integer value of a hash field by the given number
  r.sendCommand("HINCRBY", key, field, $incr)
  return r.readInteger()

proc hKeys*(r: Redis, key: string): RedisList =
  ## Get all the fields in a hash
  r.sendCommand("HKEYS", key)
  return r.readArray()

proc hLen*(r: Redis, key: string): RedisInteger =
  ## Get the number of fields in a hash
  r.sendCommand("HLEN", key)
  return r.readInteger()

proc hMGet*(r: Redis, key: string, fields: varargs[string]): RedisList =
  ## Get the values of all the given hash fields
  r.sendCommand("HMGET", key, fields)
  return r.readArray()

proc hMSet*(r: Redis, key: string, 
            fieldValues: openArray[tuple[field, value: string]]) =
  ## Set multiple hash fields to multiple values
  var args = @[key]
  for field, value in items(fieldValues):
    args.add(field)
    args.add(value)
  r.sendCommand("HMSET", args)
  raiseNoOK(r.readStatus(), r.pipeline.enabled)

proc hSet*(r: Redis, key, field, value: string): RedisInteger =
  ## Set the string value of a hash field
  r.sendCommand("HSET", key, field, value)
  return r.readInteger()
  
proc hSetNX*(r: Redis, key, field, value: string): RedisInteger =
  ## Set the value of a hash field, only if the field does **not** exist
  r.sendCommand("HSETNX", key, field, value)
  return r.readInteger()

proc hVals*(r: Redis, key: string): RedisList =
  ## Get all the values in a hash
  r.sendCommand("HVALS", key)
  return r.readArray()
  
# Lists

proc bLPop*(r: Redis, keys: varargs[string], timeout: int): RedisList =
  ## Remove and get the *first* element in a list, or block until 
  ## one is available
  var args: seq[string] = @[]
  for i in items(keys): args.add(i)
  args.add($timeout)
  r.sendCommand("BLPOP", args)
  return r.readArray()

proc bRPop*(r: Redis, keys: varargs[string], timeout: int): RedisList =
  ## Remove and get the *last* element in a list, or block until one 
  ## is available.
  var args: seq[string] = @[]
  for i in items(keys): args.add(i)
  args.add($timeout)
  r.sendCommand("BRPOP", args)
  return r.readArray()

proc bRPopLPush*(r: Redis, source, destination: string,
                 timeout: int): RedisString =
  ## Pop a value from a list, push it to another list and return it; or
  ## block until one is available.
  ##
  ## http://redis.io/commands/brpoplpush
  r.sendCommand("BRPOPLPUSH", source, destination, $timeout)
  return r.readBulkString(true) # Multi-Bulk nil allowed.

proc lIndex*(r: Redis, key: string, index: int): RedisString =
  ## Get an element from a list by its index
  r.sendCommand("LINDEX", key, $index)
  return r.readBulkString()

proc lInsert*(r: Redis, key: string, before: bool, pivot, value: string):
              RedisInteger =
  ## Insert an element before or after another element in a list
  var pos = if before: "BEFORE" else: "AFTER"
  r.sendCommand("LINSERT", key, pos, pivot, value)
  return r.readInteger()
  
proc lLen*(r: Redis, key: string): RedisInteger =
  ## Get the length of a list
  r.sendCommand("LLEN", key)
  return r.readInteger()

proc lPop*(r: Redis, key: string): RedisString =
  ## Remove and get the first element in a list
  r.sendCommand("LPOP", key)
  return r.readBulkString()

proc lPush*(r: Redis, key, value: string, create: bool = true): RedisInteger =
  ## Prepend a value to a list. Returns the length of the list after the push.
  ## The ``create`` param specifies whether a list should be created if it
  ## doesn't exist at ``key``. More specifically if ``create`` is true, `LPUSH` 
  ## will be used, otherwise `LPUSHX`.
  if create:
    r.sendCommand("LPUSH", key, value)
  else:
    r.sendCommand("LPUSHX", key, value)
  return r.readInteger()

proc lRange*(r: Redis, key: string, start, stop: int): RedisList =
  ## Get a range of elements from a list. Returns `nil` when `key` 
  ## doesn't exist.
  r.sendCommand("LRANGE", key, $start, $stop)
  return r.readArray()

proc lRem*(r: Redis, key: string, value: string, count: int = 0): RedisInteger =
  ## Remove elements from a list. Returns the number of elements that have been
  ## removed.
  r.sendCommand("LREM", key, $count, value)
  return r.readInteger()

proc lSet*(r: Redis, key: string, index: int, value: string) =
  ## Set the value of an element in a list by its index
  r.sendCommand("LSET", key, $index, value)
  raiseNoOK(r.readStatus(), r.pipeline.enabled)

proc lTrim*(r: Redis, key: string, start, stop: int)  =
  ## Trim a list to the specified range
  r.sendCommand("LTRIM", key, $start, $stop)
  raiseNoOK(r.readStatus(), r.pipeline.enabled)

proc rPop*(r: Redis, key: string): RedisString =
  ## Remove and get the last element in a list
  r.sendCommand("RPOP", key)
  return r.readBulkString()
  
proc rPopLPush*(r: Redis, source, destination: string): RedisString =
  ## Remove the last element in a list, append it to another list and return it
  r.sendCommand("RPOPLPUSH", source, destination)
  return r.readBulkString()
  
proc rPush*(r: Redis, key, value: string, create: bool = true): RedisInteger =
  ## Append a value to a list. Returns the length of the list after the push.
  ## The ``create`` param specifies whether a list should be created if it
  ## doesn't exist at ``key``. More specifically if ``create`` is true, `RPUSH` 
  ## will be used, otherwise `RPUSHX`.
  if create:
    r.sendCommand("RPUSH", key, value)
  else:
    r.sendCommand("RPUSHX", key, value)
  return r.readInteger()

# Sets

proc sadd*(r: Redis, key: string, member: string): RedisInteger =
  ## Add a member to a set
  r.sendCommand("SADD", key, member)
  return r.readInteger()

proc scard*(r: Redis, key: string): RedisInteger =
  ## Get the number of members in a set
  r.sendCommand("SCARD", key)
  return r.readInteger()

proc sdiff*(r: Redis, keys: varargs[string]): RedisList =
  ## Subtract multiple sets
  r.sendCommand("SDIFF", keys)
  return r.readArray()

proc sdiffstore*(r: Redis, destination: string,
                keys: varargs[string]): RedisInteger =
  ## Subtract multiple sets and store the resulting set in a key
  r.sendCommand("SDIFFSTORE", destination, keys)
  return r.readInteger()

proc sinter*(r: Redis, keys: varargs[string]): RedisList =
  ## Intersect multiple sets
  r.sendCommand("SINTER", keys)
  return r.readArray()

proc sinterstore*(r: Redis, destination: string,
                 keys: varargs[string]): RedisInteger =
  ## Intersect multiple sets and store the resulting set in a key
  r.sendCommand("SINTERSTORE", destination, keys)
  return r.readInteger()

proc sismember*(r: Redis, key: string, member: string): RedisInteger =
  ## Determine if a given value is a member of a set
  r.sendCommand("SISMEMBER", key, member)
  return r.readInteger()

proc smembers*(r: Redis, key: string): RedisList =
  ## Get all the members in a set
  r.sendCommand("SMEMBERS", key)
  return r.readArray()

proc smove*(r: Redis, source: string, destination: string,
           member: string): RedisInteger =
  ## Move a member from one set to another
  r.sendCommand("SMOVE", source, destination, member)
  return r.readInteger()

proc spop*(r: Redis, key: string): RedisString =
  ## Remove and return a random member from a set
  r.sendCommand("SPOP", key)
  return r.readBulkString()

proc srandmember*(r: Redis, key: string): RedisString =
  ## Get a random member from a set
  r.sendCommand("SRANDMEMBER", key)
  return r.readBulkString()

proc srem*(r: Redis, key: string, member: string): RedisInteger =
  ## Remove a member from a set
  r.sendCommand("SREM", key, member)
  return r.readInteger()

proc sunion*(r: Redis, keys: varargs[string]): RedisList =
  ## Add multiple sets
  r.sendCommand("SUNION", keys)
  return r.readArray()

proc sunionstore*(r: Redis, destination: string,
                 key: varargs[string]): RedisInteger =
  ## Add multiple sets and store the resulting set in a key 
  r.sendCommand("SUNIONSTORE", destination, key)
  return r.readInteger()

# Sorted sets

proc zadd*(r: Redis, key: string, score: int, member: string): RedisInteger =
  ## Add a member to a sorted set, or update its score if it already exists
  r.sendCommand("ZADD", key, $score, member)
  return r.readInteger()

proc zcard*(r: Redis, key: string): RedisInteger =
  ## Get the number of members in a sorted set
  r.sendCommand("ZCARD", key)
  return r.readInteger()

proc zcount*(r: Redis, key: string, min: string, max: string): RedisInteger =
  ## Count the members in a sorted set with scores within the given values
  r.sendCommand("ZCOUNT", key, min, max)
  return r.readInteger()

proc zincrby*(r: Redis, key: string, increment: string,
             member: string): RedisString =
  ## Increment the score of a member in a sorted set
  r.sendCommand("ZINCRBY", key, increment, member)
  return r.readBulkString()

proc zinterstore*(r: Redis, destination: string, numkeys: string,
                 keys: openArray[string], weights: openArray[string] = [],
                 aggregate: string = ""): RedisInteger =
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
  
  return r.readInteger()

proc zrange*(r: Redis, key: string, start: string, stop: string,
            withScores: bool): RedisList =
  ## Return a range of members in a sorted set, by index
  if not withScores:
    r.sendCommand("ZRANGE", key, start, stop)
  else:
    r.sendCommand("ZRANGE", "WITHSCORES", key, start, stop)
  return r.readArray()

proc zrangebyscore*(r: Redis, key: string, min: string, max: string, 
                   withScore: bool = false, limit: bool = false,
                   limitOffset: int = 0, limitCount: int = 0): RedisList =
  ## Return a range of members in a sorted set, by score
  var args = @[key, min, max]
  
  if withScore: args.add("WITHSCORE")
  if limit: 
    args.add("LIMIT")
    args.add($limitOffset)
    args.add($limitCount)
    
  r.sendCommand("ZRANGEBYSCORE", args)
  return r.readArray()

proc zrank*(r: Redis, key: string, member: string): RedisString =
  ## Determine the index of a member in a sorted set
  r.sendCommand("ZRANK", key, member)
  return r.readBulkString()

proc zrem*(r: Redis, key: string, member: string): RedisInteger =
  ## Remove a member from a sorted set
  r.sendCommand("ZREM", key, member)
  return r.readInteger()

proc zremrangebyrank*(r: Redis, key: string, start: string,
                     stop: string): RedisInteger =
  ## Remove all members in a sorted set within the given indexes
  r.sendCommand("ZREMRANGEBYRANK", key, start, stop)
  return r.readInteger()

proc zremrangebyscore*(r: Redis, key: string, min: string,
                      max: string): RedisInteger =
  ## Remove all members in a sorted set within the given scores
  r.sendCommand("ZREMRANGEBYSCORE", key, min, max)
  return r.readInteger()

proc zrevrange*(r: Redis, key: string, start: string, stop: string,
               withScore: bool): RedisList =
  ## Return a range of members in a sorted set, by index, 
  ## with scores ordered from high to low
  if withScore:
    r.sendCommand("ZREVRANGE", "WITHSCORE", key, start, stop)
  else: r.sendCommand("ZREVRANGE", key, start, stop)
  return r.readArray()

proc zrevrangebyscore*(r: Redis, key: string, min: string, max: string, 
                   withScore: bool = false, limit: bool = false,
                   limitOffset: int = 0, limitCount: int = 0): RedisList =
  ## Return a range of members in a sorted set, by score, with
  ## scores ordered from high to low
  var args = @[key, min, max]
  
  if withScore: args.add("WITHSCORE")
  if limit: 
    args.add("LIMIT")
    args.add($limitOffset)
    args.add($limitCount)
  
  r.sendCommand("ZREVRANGEBYSCORE", args)
  return r.readArray()

proc zrevrank*(r: Redis, key: string, member: string): RedisString =
  ## Determine the index of a member in a sorted set, with
  ## scores ordered from high to low
  r.sendCommand("ZREVRANK", key, member)
  return r.readBulkString()

proc zscore*(r: Redis, key: string, member: string): RedisString =
  ## Get the score associated with the given member in a sorted set
  r.sendCommand("ZSCORE", key, member)
  return r.readBulkString()

proc zunionstore*(r: Redis, destination: string, numkeys: string,
                 keys: openArray[string], weights: openArray[string] = [],
                 aggregate: string = ""): RedisInteger =
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
  
  return r.readInteger()

# HyperLogLog

proc pfadd*(r: Redis, key: string, elements: varargs[string]): RedisInteger = 
  ## Add variable number of elements into special 'HyperLogLog' set type
  r.sendCommand("PFADD", key, elements)
  return r.readInteger()

proc pfcount*(r: Redis, key: string): RedisInteger =
  ## Count approximate number of elements in 'HyperLogLog'
  r.sendCommand("PFCOUNT", key)
  return r.readInteger()

proc pfmerge*(r: Redis, destination: string, sources: varargs[string]) =
  ## Merge several source HyperLogLog's into one specified by destKey
  r.sendCommand("PFMERGE", destination, sources)
  raiseNoOK(r.readStatus(), r.pipeline.enabled)

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
  return r.readInteger()

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

proc discardMulti*(r: Redis) =
  ## Discard all commands issued after MULTI
  r.sendCommand("DISCARD")
  raiseNoOK(r.readStatus(), r.pipeline.enabled)

proc exec*(r: Redis): RedisList =
  ## Execute all commands issued after MULTI
  r.sendCommand("EXEC")  
  r.pipeline.enabled = false
  # Will reply with +OK for MULTI/EXEC and +QUEUED for every command
  # between, then with the results
  return r.flushPipeline(true)
  

proc multi*(r: Redis) =
  ## Mark the start of a transaction block
  r.startPipelining()
  r.sendCommand("MULTI")
  raiseNoOK(r.readStatus(), r.pipeline.enabled)

proc unwatch*(r: Redis) =
  ## Forget about all watched keys
  r.sendCommand("UNWATCH")
  raiseNoOK(r.readStatus(), r.pipeline.enabled)

proc watch*(r: Redis, key: varargs[string]) =
  ## Watch the given keys to determine execution of the MULTI/EXEC block 
  r.sendCommand("WATCH", key)
  raiseNoOK(r.readStatus(), r.pipeline.enabled)

# Connection

proc auth*(r: Redis, password: string) =
  ## Authenticate to the server
  r.sendCommand("AUTH", password)
  raiseNoOK(r.readStatus(), r.pipeline.enabled)

proc echoServ*(r: Redis, message: string): RedisString =
  ## Echo the given string
  r.sendCommand("ECHO", message)
  return r.readBulkString()

proc ping*(r: Redis): RedisStatus =
  ## Ping the server
  r.sendCommand("PING")
  return r.readStatus()

proc quit*(r: Redis) =
  ## Close the connection
  r.sendCommand("QUIT")
  raiseNoOK(r.readStatus(), r.pipeline.enabled)

proc select*(r: Redis, index: int): RedisStatus =
  ## Change the selected database for the current connection 
  r.sendCommand("SELECT", $index)
  return r.readStatus()

# Server

proc bgrewriteaof*(r: Redis) =
  ## Asynchronously rewrite the append-only file
  r.sendCommand("BGREWRITEAOF")
  raiseNoOK(r.readStatus(), r.pipeline.enabled)

proc bgsave*(r: Redis) =
  ## Asynchronously save the dataset to disk
  r.sendCommand("BGSAVE")
  raiseNoOK(r.readStatus(), r.pipeline.enabled)

proc configGet*(r: Redis, parameter: string): RedisList =
  ## Get the value of a configuration parameter
  r.sendCommand("CONFIG", "GET", parameter)
  return r.readArray()

proc configSet*(r: Redis, parameter: string, value: string) =
  ## Set a configuration parameter to the given value
  r.sendCommand("CONFIG", "SET", parameter, value)
  raiseNoOK(r.readStatus(), r.pipeline.enabled)

proc configResetStat*(r: Redis) =
  ## Reset the stats returned by INFO
  r.sendCommand("CONFIG", "RESETSTAT")
  raiseNoOK(r.readStatus(), r.pipeline.enabled)

proc dbsize*(r: Redis): RedisInteger =
  ## Return the number of keys in the selected database
  r.sendCommand("DBSIZE")
  return r.readInteger()

proc debugObject*(r: Redis, key: string): RedisStatus =
  ## Get debugging information about a key
  r.sendCommand("DEBUG", "OBJECT", key)
  return r.readStatus()

proc debugSegfault*(r: Redis) =
  ## Make the server crash
  r.sendCommand("DEBUG", "SEGFAULT")

proc flushall*(r: Redis): RedisStatus =
  ## Remove all keys from all databases
  r.sendCommand("FLUSHALL")
  raiseNoOK(r.readStatus(), r.pipeline.enabled)

proc flushdb*(r: Redis): RedisStatus =
  ## Remove all keys from the current database
  r.sendCommand("FLUSHDB")
  raiseNoOK(r.readStatus(), r.pipeline.enabled)

proc info*(r: Redis): RedisString =
  ## Get information and statistics about the server
  r.sendCommand("INFO")
  return r.readBulkString()

proc lastsave*(r: Redis): RedisInteger =
  ## Get the UNIX time stamp of the last successful save to disk
  r.sendCommand("LASTSAVE")
  return r.readInteger()

discard """
proc monitor*(r: TRedis) =
  ## Listen for all requests received by the server in real time
  r.socket.send("MONITOR\c\L")
  raiseNoOK(r.readStatus(), r.pipeline.enabled)
"""

proc save*(r: Redis) =
  ## Synchronously save the dataset to disk
  r.sendCommand("SAVE")
  raiseNoOK(r.readStatus(), r.pipeline.enabled)

proc shutdown*(r: Redis) =
  ## Synchronously save the dataset to disk and then shut down the server
  r.sendCommand("SHUTDOWN")
  var s = "".TaintedString
  r.socket.readLine(s)
  if s.string.len != 0: raise newException(RedisError, s.string)

proc slaveof*(r: Redis, host: string, port: string) =
  ## Make the server a slave of another instance, or promote it as master
  r.sendCommand("SLAVEOF", host, port)
  raiseNoOK(r.readStatus(), r.pipeline.enabled)

iterator hPairs*(r: Redis, key: string): tuple[key, value: string] =
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

proc someTests(r: Redis, how: SendMode):seq[string] =
  var list:seq[string] = @[]

  if how == pipelined:
    r.startPipelining()
  elif how ==  multiple: 
    r.multi()
    
  r.setk("nim:test", "Testing something.")
  r.setk("nim:utf8", "こんにちは")
  r.setk("nim:esc", "\\ths ągt\\")
  r.setk("nim:int", "1")
  list.add(r.get("nim:esc"))
  list.add($(r.incr("nim:int")))
  list.add(r.get("nim:int"))
  list.add(r.get("nim:utf8"))
  list.add($(r.hSet("test1", "name", "A Test")))
  var res = r.hGetAll("test1")
  for r in res:
    list.add(r)
  list.add(r.get("invalid_key"))
  list.add($(r.lPush("mylist","itema")))
  list.add($(r.lPush("mylist","itemb")))
  r.lTrim("mylist",0,1)
  var p = r.lRange("mylist", 0, -1)

  for i in items(p):
    if not isNil(i):
      list.add(i) 

  list.add(r.debugObject("mylist"))

  r.configSet("timeout", "299")
  var g = r.configGet("timeout")
  for i in items(g):
    list.add(i)

  list.add(r.echoServ("BLAH"))

  case how
  of normal:
    return list
  of pipelined:
    return r.flushPipeline()
  of multiple:
    return r.exec()

proc assertListsIdentical(listA, listB: seq[string]) =
  assert(listA.len == listB.len)
  var i = 0
  for item in listA:
    assert(item == listB[i])
    i = i + 1
  
when isMainModule:
  when false:
    var r = open()

    # Test with no pipelining
    var listNormal = r.someTests(normal)

    # Test with pipelining enabled
    var listPipelined = r.someTests(pipelined)
    assertListsIdentical(listNormal, listPipelined)

    # Test with multi/exec() (automatic pipelining)
    var listMulti = r.someTests(multiple)
    assertListsIdentical(listNormal, listMulti)
