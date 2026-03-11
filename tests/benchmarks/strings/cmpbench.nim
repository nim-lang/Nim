import std/[monotimes, os, random, strutils, times]

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

  Pair = tuple[a, b: string]

  Config = object
    count: int
    rounds: int
    seed: int64
    scenarios: seq[Scenario]

proc defaultConfig(): Config =
  Config(
    count: 400_000,
    rounds: 8,
    seed: 20260307'i64,
    scenarios: @[scShort, scInline, scBoundary, scLong, scMixed]
  )

proc usage() =
  echo "String comparison benchmark for experimenting with the SSO runtime."
  echo ""
  echo "Usage:"
  echo "  nim r -d:danger cmpbench.nim [--count=N] [--rounds=N] [--seed=N]"
  echo "                                [--scenarios=list]"
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
  if kind == scPrefix and result.len > 0:
    # Keep the shared-prefix workload adversarial on purpose.
    result[^1] = char(ord('0') + (serial mod 10))

proc generateDataset(kind: Scenario; count: int; seed: int64): seq[string] =
  var rng = initRand(seed + kind.ord.int64 * 10_000_019'i64)
  result = newSeq[string](count)
  for i in 0..<count:
    result[i] = makeScenarioString(rng, kind, i)

proc tweakTail(s: string; salt: int): string =
  result = s
  if result.len == 0:
    result = "x"
  elif result.len == 1:
    result[0] = char(ord('a') + (salt mod 26))
  else:
    result[^1] = char(ord('a') + (salt mod 26))

proc buildPairs(kind: Scenario; data: openArray[string]): seq[Pair] =
  result = newSeq[Pair](data.len)
  let n = max(1, data.len)
  for i in 0..<data.len:
    let a = data[i]
    let j = (i * 48271 + 17) mod n
    let k = (i * 69621 + 91) mod n
    if kind == scPrefix:
      case i mod 4
      of 0:
        result[i] = (a, data[j])
      of 1:
        result[i] = (a, a)
      of 2:
        result[i] = (a, tweakTail(a, i))
      else:
        result[i] = (a, data[(i + 1) mod n])
    else:
      # Default workload: mostly unrelated words, with a small minority of harder cases.
      case i mod 10
      of 0:
        result[i] = (a, a)
      of 1:
        result[i] = (a, tweakTail(a, i))
      of 2:
        result[i] = (a, data[(i + 1) mod n])
      else:
        result[i] = (a, data[if j == i: k else: j])

proc averageLen(data: openArray[string]): float =
  var total = 0
  for s in data:
    total += s.len
  result = total.float / max(1, data.len).float

proc pairChecksum(pairs: openArray[Pair]): uint64 =
  for i, pair in pairs:
    result = result * 0x9E3779B185EBCA87'u64 + uint64(pair.a.len + pair.b.len)
    if pair.a.len > 0:
      result = result xor (uint64(ord(pair.a[0])) shl (i and 7))
    if pair.b.len > 0:
      result = result xor (uint64(ord(pair.b[^1])) shl ((i + 3) and 7))

proc bench(kind: Scenario; cfg: Config) =
  let data = generateDataset(kind, cfg.count, cfg.seed)
  let pairs = buildPairs(kind, data)
  let avgLen = averageLen(data)

  var warm = 0
  for pair in pairs:
    warm += system.cmp(pair.a, pair.b)

  var totalNs = 0.0
  var bestNs = Inf
  var worstNs = 0.0
  var combined = uint64(cast[uint](warm)) xor pairChecksum(pairs)

  for round in 0..<cfg.rounds:
    var acc = 0
    let started = getMonoTime()
    for pair in pairs:
      acc += system.cmp(pair.a, pair.b)
    let elapsedNs = float((getMonoTime() - started).inNanoseconds)
    totalNs += elapsedNs
    bestNs = min(bestNs, elapsedNs)
    worstNs = max(worstNs, elapsedNs)
    combined = combined * 0x9E3779B185EBCA87'u64 + uint64(cast[uint](acc)) + uint64(round + 1)

  let avgNs = totalNs / cfg.rounds.float
  let nsPerCmp = avgNs / pairs.len.float
  echo align(scenarioName(kind), 8), "  n=", align($pairs.len, 8),
      "  avgLen=", align(fixed(avgLen, 1), 6),
      "  avg=", align(fixed(avgNs / 1e6, 3), 9), " ms",
      "  best=", align(fixed(bestNs / 1e6, 3), 9), " ms",
      "  worst=", align(fixed(worstNs / 1e6, 3), 9), " ms",
      "  ns/cmp=", align(fixed(nsPerCmp, 1), 8),
      "  check=0x", toHex(combined, 16)

proc main() =
  let cfg = parseConfig()
  echo "inline limit=", InlineMax, " bytes  count=", cfg.count,
      "  rounds=", cfg.rounds, "  seed=", cfg.seed
  echo "scenarios=", scenarioList(cfg.scenarios)
  for scenario in cfg.scenarios:
    bench(scenario, cfg)
  echo "MAXMEM=", formatSize getMaxMem()

when isMainModule:
  main()
