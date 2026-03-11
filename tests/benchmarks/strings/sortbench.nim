import std/[algorithm, monotimes, os, random, strutils, times]

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
    scenarios: @[scShort, scInline, scBoundary, scLong, scMixed]
  )

proc usage() =
  echo "String sorting benchmark for experimenting with the SSO runtime."
  echo ""
  echo "Usage:"
  echo "  nim r -d:danger sortbench.nim [--count=N] [--rounds=N] [--seed=N]"
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

proc randomChar(rng: var Rand): char =
  Alphabet[rng.rand(Alphabet.high)]

proc makeRandomString(rng: var Rand; len: int): string =
  result = newString(len)
  var i = 0
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
    result = makeRandomString(rng, rng.rand(1 .. InlineMax))
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
  of scMixed:
    result = makeRandomString(rng, pickMixedLength(rng))

  # Inject a little deterministic structure so equal prefixes are common but not identical.
  if result.len > 0:
    result[0] = char(ord('a') + (serial mod 26))
    result[^1] = char(ord('0') + (serial mod 10))

proc generateDataset(kind: Scenario; count: int; seed: int64): seq[string] =
  var rng = initRand(seed + kind.ord.int64 * 10_000_019'i64)
  result = newSeq[string](count)
  for i in 0..<count:
    result[i] = makeScenarioString(rng, kind, i)

proc cloneStrings(src: seq[string]): seq[string] =
  result = newSeq[string](src.len)
  for i, s in src:
    result[i] = s

proc isSorted(a: openArray[string]): bool =
  for i in 1..<a.len:
    if cmp(a[i - 1], a[i]) > 0:
      return false
  result = true

proc checksum(a: openArray[string]): uint64 =
  for i, s in a:
    result = result * 0x9E3779B185EBCA87'u64 + uint64(s.len)
    if s.len > 0:
      result = result xor (uint64(ord(s[0])) shl (i and 7))
      result = result xor (uint64(ord(s[^1])) shl ((i + 3) and 7))

proc averageLen(data: openArray[string]): float =
  var total = 0
  for s in data:
    total += s.len
  result = total.float / max(1, data.len).float

proc scenarioList(scenarios: openArray[Scenario]): string =
  for i, scenario in scenarios:
    if i > 0:
      result.add ','
    result.add scenarioName(scenario)

proc fixed(x: float; digits: range[0..32]): string =
  formatFloat(x, ffDecimal, digits)

proc bench(kind: Scenario; cfg: Config) =
  let data = generateDataset(kind, cfg.count, cfg.seed)
  let avgLen = averageLen(data)

  var warmup = cloneStrings(data)
  warmup.sort(system.cmp)
  doAssert isSorted(warmup)

  var totalNs = 0.0
  var bestNs = Inf
  var worstNs = 0.0
  var combinedChecksum = 0'u64

  for round in 0..<cfg.rounds:
    var working = cloneStrings(data)
    let started = getMonoTime()
    working.sort(system.cmp)
    let elapsedNs = float((getMonoTime() - started).inNanoseconds)
    doAssert isSorted(working)
    totalNs += elapsedNs
    bestNs = min(bestNs, elapsedNs)
    worstNs = max(worstNs, elapsedNs)
    combinedChecksum = combinedChecksum * 0x9E3779B185EBCA87'u64 +
        checksum(working) + uint64(round + 1)

  let avgNs = totalNs / cfg.rounds.float
  let nsPerItem = avgNs / cfg.count.float
  echo align(scenarioName(kind), 8), "  n=", align($cfg.count, 8),
      "  avgLen=", align(fixed(avgLen, 1), 6),
      "  avg=", align(fixed(avgNs / 1e6, 3), 9), " ms",
      "  best=", align(fixed(bestNs / 1e6, 3), 9), " ms",
      "  worst=", align(fixed(worstNs / 1e6, 3), 9), " ms",
      "  ns/item=", align(fixed(nsPerItem, 1), 8),
      "  check=0x", toHex(combinedChecksum, 16)

proc main() =
  let cfg = parseConfig()
  echo "inline limit=", InlineMax, " bytes  count=", cfg.count,
      "  rounds=", cfg.rounds, "  seed=", cfg.seed
  echo "scenarios=" & scenarioList(cfg.scenarios)
  for scenario in cfg.scenarios:
    bench(scenario, cfg)

  echo "MAXMEM=", formatSize getMaxMem()

when isMainModule:
  main()
