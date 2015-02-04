import irc, sockets, asyncio, json, os, strutils, times, redis

type
  TDb* = object
    r*: Redis
    lastPing: float

  TBuildResult* = enum
    bUnknown, bFail, bSuccess

  TTestResult* = enum
    tUnknown, tFail, tSuccess

  TEntry* = tuple[c: TCommit, p: seq[TPlatform]]
  
  TCommit* = object
    commitMsg*, username*, hash*: string
    date*: Time

  TPlatform* = object
    buildResult*: TBuildResult
    testResult*: TTestResult
    failReason*, platform*: string
    total*, passed*, skipped*, failed*: BiggestInt
    csources*: bool

const
  listName = "commits"
  failOnExisting = false

proc open*(host = "localhost", port: Port): TDb =
  result.r = redis.open(host, port)
  result.lastPing = epochTime()

discard """proc customHSet(database: TDb, name, field, value: string) =
  if database.r.hSet(name, field, value).int == 0:
    if failOnExisting:
      assert(false)
    else:
      echo("[Warning:REDIS] ", field, " already exists in ", name)"""

proc updateProperty*(database: TDb, commitHash, platform, property,
                    value: string) =
  var name = platform & ":" & commitHash
  if database.r.hSet(name, property, value).int == 0:
    echo("[INFO:REDIS] '$1' field updated in hash" % [property])
  else:
    echo("[INFO:REDIS] '$1' new field added to hash" % [property])

proc globalProperty*(database: TDb, commitHash, property, value: string) =
  if database.r.hSet(commitHash, property, value).int == 0:
    echo("[INFO:REDIS] '$1' field updated in hash" % [property])
  else:
    echo("[INFO:REDIS] '$1' new field added to hash" % [property])

proc addCommit*(database: TDb, commitHash, commitMsg, user: string) =
  # Add the commit hash to the `commits` list.
  discard database.r.lPush(listName, commitHash)
  # Add the commit message, current date and username as a property
  globalProperty(database, commitHash, "commitMsg", commitMsg)
  globalProperty(database, commitHash, "date", $int(getTime()))
  globalProperty(database, commitHash, "username", user)

proc keepAlive*(database: var TDb) =
  ## Keep the connection alive. Ping redis in this case. This functions does
  ## not guarantee that redis will be pinged.
  var t = epochTime()
  if t - database.lastPing >= 60.0:
    echo("PING -> redis")
    assert(database.r.ping() == "PONG")
    database.lastPing = t
    
proc getCommits*(database: TDb,
                 plStr: var seq[string]): seq[TEntry] =
  result = @[]
  var commitsRaw = database.r.lrange("commits", 0, -1)
  for c in items(commitsRaw):
    var commit: TCommit
    commit.hash = c
    for key, value in database.r.hPairs(c):
      case normalize(key)
      of "commitmsg": commit.commitMsg = value
      of "date": commit.date = Time(parseInt(value))
      of "username": commit.username = value
      else:
        echo(key)
        assert(false)

    var platformsRaw = database.r.lrange(c & ":platforms", 0, -1)
    var platforms: seq[TPlatform] = @[]
    for p in items(platformsRaw):
      var platform: TPlatform
      for key, value in database.r.hPairs(p & ":" & c):
        case normalize(key)
        of "buildresult":
          platform.buildResult = parseInt(value).TBuildResult
        of "testresult":
          platform.testResult = parseInt(value).TTestResult
        of "failreason":
          platform.failReason = value
        of "total":
          platform.total = parseBiggestInt(value)
        of "passed":
          platform.passed = parseBiggestInt(value)
        of "skipped":
          platform.skipped = parseBiggestInt(value)
        of "failed":
          platform.failed = parseBiggestInt(value)
        of "csources":
          platform.csources = if value == "t": true else: false
        else:
          echo(normalize(key))
          assert(false)
      
      platform.platform = p
      
      platforms.add(platform)
      if p notin plStr:
        plStr.add(p)
    result.add((commit, platforms))

proc commitExists*(database: TDb, commit: string, starts = false): bool =
  # TODO: Consider making the 'commits' list a set.
  for c in items(database.r.lrange("commits", 0, -1)):
    if starts:
      if c.startsWith(commit): return true
    else:
      if c == commit: return true
  return false

proc platformExists*(database: TDb, commit: string, platform: string): bool =
  for p in items(database.r.lrange(commit & ":" & "platforms", 0, -1)):
    if p == platform: return true

proc expandHash*(database: TDb, commit: string): string =
  for c in items(database.r.lrange("commits", 0, -1)):
    if c.startsWith(commit): return c
  assert false

proc isNewest*(database: TDb, commit: string): bool =
  return database.r.lIndex("commits", 0) == commit

proc getNewest*(database: TDb): string =
  return database.r.lIndex("commits", 0)

proc addPlatform*(database: TDb, commit: string, platform: string) =
  assert database.commitExists(commit)
  assert (not database.platformExists(commit, platform))
  var name = platform & ":" & commit
  if database.r.exists(name):
    if failOnExisting: quit("[FAIL] " & name & " already exists!", 1)
    else: echo("[Warning] " & name & " already exists!")

  discard database.r.lPush(commit & ":" & "platforms", platform)

proc `[]`*(p: seq[TPlatform], name: string): TPlatform =
  for platform in items(p):
    if platform.platform == name:
      return platform
  raise newException(ValueError, name & " platforms not found in commits.")
  
proc contains*(p: seq[TPlatform], s: string): bool =
  for i in items(p):
    if i.platform == s:
      return true
    

type
  PState = ref TState
  TState = object of RootObj
    dispatcher: Dispatcher
    sock: AsyncSocket
    ircClient: PAsyncIRC
    hubPort: Port
    database: TDb
    dbConnected: bool

  TSeenType = enum
    PSeenJoin, PSeenPart, PSeenMsg, PSeenNick, PSeenQuit
  
  TSeen = object
    nick: string
    channel: string
    timestamp: Time
    case kind*: TSeenType
    of PSeenJoin: nil
    of PSeenPart, PSeenQuit, PSeenMsg:
      msg: string
    of PSeenNick:
      newNick: string

const
  ircServer = "irc.freenode.net"
  joinChans = @["#nim"]
  botNickname = "NimBot"

proc setSeen(d: TDb, s: TSeen) =
  discard d.r.del("seen:" & s.nick)

  var hashToSet = @[("type", $s.kind.int), ("channel", s.channel),
                    ("timestamp", $s.timestamp.int)]
  case s.kind
  of PSeenJoin: discard
  of PSeenPart, PSeenMsg, PSeenQuit:
    hashToSet.add(("msg", s.msg))
  of PSeenNick:
    hashToSet.add(("newnick", s.newNick))
  
  d.r.hMSet("seen:" & s.nick, hashToSet)

proc getSeen(d: TDb, nick: string, s: var TSeen): bool =
  if d.r.exists("seen:" & nick):
    result = true
    s.nick = nick
    # Get the type first
    s.kind = d.r.hGet("seen:" & nick, "type").parseInt.TSeenType
    
    for key, value in d.r.hPairs("seen:" & nick):
      case normalize(key)
      of "type":
        discard
        #s.kind = value.parseInt.TSeenType
      of "channel":
        s.channel = value
      of "timestamp":
        s.timestamp = Time(value.parseInt)
      of "msg":
        s.msg = value
      of "newnick":
        s.newNick = value

template createSeen(typ: TSeenType, n, c: string): stmt {.immediate, dirty.} =
  var seenNick: TSeen
  seenNick.kind = typ
  seenNick.nick = n
  seenNick.channel = c
  seenNick.timestamp = getTime()

proc parseReply(line: string, expect: string): bool =
  var jsonDoc = parseJson(line)
  return jsonDoc["reply"].str == expect

proc limitCommitMsg(m: string): string =
  ## Limits the message to 300 chars and adds ellipsis.
  var m1 = m
  if NewLines in m1:
    m1 = m1.splitLines()[0]
  
  if m1.len >= 300:
    m1 = m1[0..300]

  if m1.len >= 300 or NewLines in m: m1.add("... ")

  if NewLines in m: m1.add($m.splitLines().len & " more lines")

  return m1

proc handleWebMessage(state: PState, line: string) =
  echo("Got message from hub: " & line)
  var json = parseJson(line)
  if json.hasKey("payload"):
    for i in 0..min(4, json["payload"]["commits"].len-1):
      var commit = json["payload"]["commits"][i]
      # Create the message
      var message = ""
      message.add(json["payload"]["repository"]["owner"]["name"].str & "/" &
                  json["payload"]["repository"]["name"].str & " ")
      message.add(commit["id"].str[0..6] & " ")
      message.add(commit["author"]["name"].str & " ")
      message.add("[+" & $commit["added"].len & " ")
      message.add("±" & $commit["modified"].len & " ")
      message.add("-" & $commit["removed"].len & "]: ")
      message.add(limitCommitMsg(commit["message"].str))

      # Send message to #nim.
      discard state.ircClient.privmsg(joinChans[0], message)
  elif json.hasKey("redisinfo"):
    assert json["redisinfo"].hasKey("port")
    #let redisPort = json["redisinfo"]["port"].num
    state.dbConnected = true

proc hubConnect(state: PState)
proc handleConnect(s: AsyncSocket, state: PState) =
  try:
    # Send greeting
    var obj = newJObject()
    obj["name"] = newJString("irc")
    obj["platform"] = newJString("?")
    state.sock.send($obj & "\c\L")

    # Wait for reply.
    var line = ""
    sleep(1500)
    if state.sock.recvLine(line):
      assert(line != "")
      doAssert parseReply(line, "OK")
      echo("The hub accepted me!")
    else:
      raise newException(ValueError,
                         "Hub didn't accept me. Waited 1.5 seconds.")
    
    # ask for the redis info
    var riobj = newJObject()
    riobj["do"] = newJString("redisinfo")
    state.sock.send($riobj & "\c\L")
    
  except OsError:
    echo(getCurrentExceptionMsg())
    s.close()
    echo("Waiting 5 seconds...")
    sleep(5000)
    state.hubConnect()

proc handleRead(s: AsyncSocket, state: PState) =
  var line = ""
  if state.sock.recvLine(line):
    if line != "":
      # Handle the message
      state.handleWebMessage(line)
    else:
      echo("Disconnected from hub: ", osErrorMsg())
      s.close()
      echo("Reconnecting...")
      state.hubConnect()
  else:
    echo(osErrorMsg())

proc hubConnect(state: PState) =
  state.sock = asyncSocket()
  state.sock.connect("127.0.0.1", state.hubPort)
  state.sock.handleConnect =
    proc (s: AsyncSocket) =
      handleConnect(s, state)
  state.sock.handleRead =
    proc (s: AsyncSocket) =
      handleRead(s, state)

  state.dispatcher.register(state.sock)

proc handleIrc(irc: PAsyncIRC, event: TIRCEvent, state: PState) =
  case event.typ
  of EvConnected: discard
  of EvDisconnected:
    while not state.ircClient.isConnected:
      try:
        state.ircClient.connect()
      except:
        echo("Error reconnecting: ", getCurrentExceptionMsg())
      
      echo("Waiting 5 seconds...")
      sleep(5000)
    echo("Reconnected successfully!")
  of EvMsg:
    echo("< ", event.raw)
    case event.cmd
    of MPrivMsg:
      let msg = event.params[event.params.len-1]
      let words = msg.split(' ')
      template pm(msg: string): stmt =
        state.ircClient.privmsg(event.origin, msg)
      case words[0]
      of "!ping": pm("pong")
      of "!lag":
        if state.ircClient.getLag != -1.0:
          var lag = state.ircClient.getLag
          lag = lag * 1000.0
          pm($int(lag) & "ms between me and the server.")
        else:
          pm("Unknown.")
      of "!seen":
        if words.len > 1:
          let nick = words[1]
          if nick == botNickname:
            pm("Yes, I see myself.")
          echo(nick)
          var seenInfo: TSeen
          if state.database.getSeen(nick, seenInfo):
            #var mSend = ""
            case seenInfo.kind
            of PSeenMsg:
              pm("$1 was last seen on $2 in $3 saying: $4" %
                    [seenInfo.nick, $seenInfo.timestamp,
                     seenInfo.channel, seenInfo.msg])
            of PSeenJoin:
              pm("$1 was last seen on $2 joining $3" %
                        [seenInfo.nick, $seenInfo.timestamp, seenInfo.channel])
            of PSeenPart:
              pm("$1 was last seen on $2 leaving $3 with message: $4" %
                        [seenInfo.nick, $seenInfo.timestamp, seenInfo.channel,
                         seenInfo.msg])
            of PSeenQuit:
              pm("$1 was last seen on $2 quitting with message: $3" %
                        [seenInfo.nick, $seenInfo.timestamp, seenInfo.msg])
            of PSeenNick:
              pm("$1 was last seen on $2 changing nick to $3" %
                        [seenInfo.nick, $seenInfo.timestamp, seenInfo.newNick])
            
          else:
            pm("I have not seen " & nick)
        else:
          pm("Syntax: !seen <nick>")

      # TODO: ... commands

      # -- Seen
      # Log this as activity.
      createSeen(PSeenMsg, event.nick, event.origin)
      seenNick.msg = msg
      state.database.setSeen(seenNick)
    of MJoin:
      createSeen(PSeenJoin, event.nick, event.origin)
      state.database.setSeen(seenNick)
    of MPart:
      createSeen(PSeenPart, event.nick, event.origin)
      let msg = event.params[event.params.high]
      seenNick.msg = msg
      state.database.setSeen(seenNick)
    of MQuit:
      createSeen(PSeenQuit, event.nick, event.origin)
      let msg = event.params[event.params.high]
      seenNick.msg = msg
      state.database.setSeen(seenNick)
    of MNick:
      createSeen(PSeenNick, event.nick, "#nim")
      seenNick.newNick = event.params[0]
      state.database.setSeen(seenNick)
    else:
      discard # TODO: ?

proc open(port: Port = Port(5123)): PState =
  var res: PState
  new(res)
  res.dispatcher = newDispatcher()
  
  res.hubPort = port
  res.hubConnect()
  let hirc =
    proc (a: PAsyncIRC, ev: TIRCEvent) =
      handleIrc(a, ev, res)
  # Connect to the irc server.
  res.ircClient = AsyncIrc(ircServer, nick = botNickname, user = botNickname,
                 joinChans = joinChans, ircEvent = hirc)
  res.ircClient.connect()
  res.dispatcher.register(res.ircClient)

  res.dbConnected = false
  result = res

var state = tircbot.open() # Connect to the website and the IRC server.

while state.dispatcher.poll():
  if state.dbConnected:
    state.database.keepAlive()
