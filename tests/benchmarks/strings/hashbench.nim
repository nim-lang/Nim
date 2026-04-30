import std/[monotimes, os, random, strutils, tables, times]

const
  AlwaysAvail = 7
  InlineMax = AlwaysAvail + sizeof(pointer) - 1
  Alphabet = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_-"
  SharedPrefixes = [
    "module/submodule/symbol/",
    "compiler/semantic/checker/",
    "core/runtime/string-table/",
    "aaaaaaaaaaaaaa/shared/prefix/",
    "zzzzzzzzzzzzzz/shared/prefix/"
  ]
  ScenarioNames = ["short", "inline", "boundary", "long", "prefix", "mixed"]

type
  Scenario = enum
    scShort
    scInline
    scBoundary
    scLong
    scPrefix
    scMixed

  Config = object
    count: int
    rounds: int
    seed: int64
    scenarios: seq[Scenario]

proc defaultConfig(): Config =
  Config(
    count: 200_000,
    rounds: 5,
    seed: 20260307'i64,
    scenarios: @[scShort, scInline, scBoundary, scLong, scPrefix, scMixed]
  )

proc usage() =
  echo "String hash-table benchmark for experimenting with the SSO runtime."
  echo ""
  echo "Usage:"
  echo "  nim r -d:danger hashbench.nim [--count=N] [--rounds=N] [--seed=N]"
  echo "                                 [--scenarios=list]"
  echo ""
  echo "Scenarios:"
  echo "  short, inline, boundary, long, prefix, mixed"
  echo ""
  echo "Current inline limit on this target: ", InlineMax, " bytes"

proc parseScenario(name: string): Scenario =
  case name.normalize
  of "short":
    scShort
  of "inline":
    scInline
  of "boundary":
    scBoundary
  of "long":
    scLong
  of "prefix":
    scPrefix
  of "mixed":
    scMixed
  else:
    quit "unknown scenario: " & name

proc parseConfig(): Config =
  result = defaultConfig()
  for arg in commandLineParams():
    if arg == "--help" or arg == "-h":
      usage()
      quit 0
    elif arg.startsWith("--count="):
      result.count = parseInt(arg["--count=".len .. ^1])
    elif arg.startsWith("--rounds="):
      result.rounds = parseInt(arg["--rounds=".len .. ^1])
    elif arg.startsWith("--seed="):
      result.seed = parseInt(arg["--seed=".len .. ^1]).int64
    elif arg.startsWith("--scenarios="):
      result.scenarios.setLen(0)
      for item in arg["--scenarios=".len .. ^1].split(','):
        if item.len > 0:
          result.scenarios.add parseScenario(item)
    else:
      quit "unknown argument: " & arg

  if result.count <= 0:
    quit "--count must be > 0"
  if result.rounds <= 0:
    quit "--rounds must be > 0"
  if result.scenarios.len == 0:
    quit "at least one scenario is required"

proc scenarioName(s: Scenario): string =
  ScenarioNames[s.ord]

proc scenarioList(scenarios: openArray[Scenario]): string =
  for i, scenario in scenarios:
    if i > 0:
      result.add ','
    result.add scenarioName(scenario)

proc fixed(x: float; digits: range[0..32]): string =
  formatFloat(x, ffDecimal, digits)

proc randomChar(rng: var Rand): char =
  Alphabet[rng.rand(Alphabet.high)]

proc makeRandomString(rng: var Rand; len: int; prefix = ""): string =
  result = newString(len)
  var i = 0
  while i < len and i < prefix.len:
    result[i] = prefix[i]
    inc i
  while i < len:
    result[i] = randomChar(rng)
    inc i

proc pickMixedLength(rng: var Rand): int =
  let bucket = rng.rand(0..99)
  if bucket < 35:
    result = rng.rand(1..AlwaysAvail)
  elif bucket < 70:
    result = rng.rand(AlwaysAvail + 1 .. InlineMax)
  else:
    result = rng.rand(InlineMax + 1 .. InlineMax + 48)

proc makeScenarioString(rng: var Rand; kind: Scenario; serial: int): string =
  case kind
  of scShort:
    result = makeRandomString(rng, rng.rand(1..AlwaysAvail))
  of scInline:
    result = makeRandomString(rng, rng.rand(AlwaysAvail + 1 .. InlineMax))
  of scBoundary:
    let choices = [
      max(1, InlineMax - 2),
      max(1, InlineMax - 1),
      InlineMax,
      InlineMax + 1,
      InlineMax + 2
    ]
    result = makeRandomString(rng, choices[rng.rand(choices.high)])
  of scLong:
    result = makeRandomString(rng, rng.rand(InlineMax + 1 .. InlineMax + 64))
  of scPrefix:
    let prefix = SharedPrefixes[rng.rand(SharedPrefixes.high)]
    let suffixLen = rng.rand(4..24)
    result = makeRandomString(rng, prefix.len + suffixLen, prefix)
  of scMixed:
    result = makeRandomString(rng, pickMixedLength(rng))

  if result.len > 0:
    result[0] = char(ord('a') + (serial mod 26))
    result[^1] = char(ord('0') + (serial mod 10))

proc generateDataset(kind: Scenario; count: int; seed: int64): seq[string] =
  var rng = initRand(seed + kind.ord.int64 * 10_000_019'i64)
  result = newSeq[string](count)
  for i in 0..<count:
    result[i] = makeScenarioString(rng, kind, i)

proc averageLen(data: openArray[string]): float =
  var total = 0
  for s in data:
    total += s.len
  result = total.float / max(1, data.len).float

proc checksum(data: openArray[string]): uint64 =
  for i, s in data:
    result = result * 0x9E3779B185EBCA87'u64 + uint64(s.len)
    if s.len > 0:
      result = result xor (uint64(ord(s[0])) shl (i and 7))
      result = result xor (uint64(ord(s[^1])) shl ((i + 3) and 7))

proc makeMissQueries(kind: Scenario; count: int; seed: int64): seq[string] =
  result = generateDataset(kind, count, seed + 0x6A09E667'i64)
  for i in 0..<result.len:
    if result[i].len == 0:
      result[i] = "!"
    else:
      result[i][^1] = char(ord('Q') + (i mod 7))

proc bench(kind: Scenario; cfg: Config) =
  let keys = generateDataset(kind, cfg.count, cfg.seed)
  let hitQueries = keys
  let missQueries = makeMissQueries(kind, cfg.count, cfg.seed)
  let avgLen = averageLen(keys)
  let keyCheck = checksum(keys) xor checksum(missQueries)

  var warm = initTable[string, int](cfg.count * 2)
  for i, key in keys:
    warm[key] = i
  var warmHits = 0
  for key in hitQueries:
    warmHits += warm[key]
  var warmMisses = 0
  for key in missQueries:
    if warm.hasKey(key):
      inc warmMisses
  doAssert warmHits >= 0
  doAssert warmMisses == 0

  var insertTotalNs = 0.0
  var hitTotalNs = 0.0
  var missTotalNs = 0.0
  var insertBestNs = Inf
  var hitBestNs = Inf
  var missBestNs = Inf
  var insertWorstNs = 0.0
  var hitWorstNs = 0.0
  var missWorstNs = 0.0
  var combined = keyCheck + uint64(cfg.count)

  for round in 0..<cfg.rounds:
    var table = initTable[string, int](cfg.count * 2)

    let insertStarted = getMonoTime()
    for i, key in keys:
      table[key] = i
    let insertNs = float((getMonoTime() - insertStarted).inNanoseconds)

    var hitSum = 0
    let hitStarted = getMonoTime()
    for key in hitQueries:
      hitSum += table[key]
    let hitNs = float((getMonoTime() - hitStarted).inNanoseconds)

    var missSum = 0
    let missStarted = getMonoTime()
    for key in missQueries:
      if table.hasKey(key):
        inc missSum
    let missNs = float((getMonoTime() - missStarted).inNanoseconds)

    doAssert hitSum >= 0
    doAssert missSum == 0

    insertTotalNs += insertNs
    hitTotalNs += hitNs
    missTotalNs += missNs
    insertBestNs = min(insertBestNs, insertNs)
    hitBestNs = min(hitBestNs, hitNs)
    missBestNs = min(missBestNs, missNs)
    insertWorstNs = max(insertWorstNs, insertNs)
    hitWorstNs = max(hitWorstNs, hitNs)
    missWorstNs = max(missWorstNs, missNs)
    combined = combined * 0x9E3779B185EBCA87'u64 +
        uint64(cast[uint](hitSum xor missSum xor round))
  let insertAvgNs = insertTotalNs / cfg.rounds.float
  let hitAvgNs = hitTotalNs / cfg.rounds.float
  let missAvgNs = missTotalNs / cfg.rounds.float
  echo align(scenarioName(kind), 8), "  n=", align($cfg.count, 8),
      "  avgLen=", align(fixed(avgLen, 1), 6),
      "  ins=", align(fixed(insertAvgNs / 1e6, 3), 9), " ms",
      "  hit=", align(fixed(hitAvgNs / 1e6, 3), 9), " ms",
      "  miss=", align(fixed(missAvgNs / 1e6, 3), 9), " ms",
      "  ns/op=", align(fixed((insertAvgNs + hitAvgNs + missAvgNs) / (3.0 * cfg.count.float), 1), 8),
      "  check=0x", toHex(combined, 16)
  discard insertBestNs
  discard hitBestNs
  discard missBestNs
  discard insertWorstNs
  discard hitWorstNs
  discard missWorstNs

proc main() =
  let cfg = parseConfig()
  echo "inline limit=", InlineMax, " bytes  count=", cfg.count,
      "  rounds=", cfg.rounds, "  seed=", cfg.seed
  echo "scenarios=", scenarioList(cfg.scenarios)
  for scenario in cfg.scenarios:
    bench(scenario, cfg)
  when not defined(useMalloc): echo "MAXMEM=", formatSize getMaxMem()

when isMainModule:
  main()
