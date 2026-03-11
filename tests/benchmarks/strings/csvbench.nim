import std/[monotimes, os, parsecsv, random, strutils, times]

const
  FirstNames = [
    "amy", "ben", "chris", "dora", "ella", "finn", "gina", "hugo",
    "ivan", "june", "kyle", "lena", "mona", "nina", "owen", "paul"
  ]
  LastNames = [
    "li", "ng", "kim", "ross", "miles", "stone", "young", "ward",
    "reed", "clark", "hall", "price", "woods", "perry", "cohen", "moore"
  ]

type
  StoredRow = object
    id: string
    name: string
    age: string
    score: string
    visits: string
    zip: string
    timestamp: string
    url: string

  Config = object
    rows: int
    rounds: int
    seed: int64

proc defaultConfig(): Config =
  Config(rows: 100_000, rounds: 4, seed: 20260307'i64)

proc usage() =
  echo "CSV parse/materialize benchmark for experimenting with the SSO runtime."
  echo ""
  echo "Usage:"
  echo "  nim r -d:danger csvbench.nim [--rows=N] [--rounds=N] [--seed=N]"

proc parseConfig(): Config =
  result = defaultConfig()
  for arg in commandLineParams():
    if arg == "--help" or arg == "-h":
      usage()
      quit 0
    elif arg.startsWith("--rows="):
      result.rows = parseInt(arg["--rows=".len .. ^1])
    elif arg.startsWith("--rounds="):
      result.rounds = parseInt(arg["--rounds=".len .. ^1])
    elif arg.startsWith("--seed="):
      result.seed = parseInt(arg["--seed=".len .. ^1]).int64
    else:
      quit "unknown argument: " & arg
  if result.rows <= 0:
    quit "--rows must be > 0"
  if result.rounds <= 0:
    quit "--rounds must be > 0"

proc fixed(x: float; digits: range[0..32]): string =
  formatFloat(x, ffDecimal, digits)

proc makeName(rng: var Rand; serial: int): string =
  result = FirstNames[rng.rand(FirstNames.high)] & "_" &
      LastNames[(serial + rng.rand(LastNames.high)) mod LastNames.len]

proc makeUrl(name: string; serial: int; score: int): string =
  "https://data.example/api/u/" & name & "/" & $serial &
      "?score=" & $score & "&src=csv"

proc csvPath(cfg: Config): string =
  getTempDir() / ("nim_csvbench_" & $cfg.rows & "_" & $cfg.seed & ".csv")

proc writeCsv(path: string; cfg: Config) =
  var rng = initRand(cfg.seed)
  var f = open(path, fmWrite)
  defer: close(f)

  f.writeLine("id,name,age,score,visits,zip,timestamp,url")
  for i in 0..<cfg.rows:
    let name = makeName(rng, i)
    let age = 18 + (i mod 63)
    let score = 1000 + rng.rand(0..900_000)
    let visits = rng.rand(0..20_000)
    let zip = 10000 + rng.rand(0..89999)
    let ts = 1700000000'i64 + i.int64 * 17 + rng.rand(0..999).int64
    let url = makeUrl(name, i, score)
    f.write($i)
    f.write(',')
    f.write(name)
    f.write(',')
    f.write($age)
    f.write(',')
    f.write($score)
    f.write(',')
    f.write($visits)
    f.write(',')
    f.write($zip)
    f.write(',')
    f.write($ts)
    f.write(',')
    f.writeLine(url)

proc checksum(row: StoredRow): uint64 =
  let fields = [
    row.id, row.name, row.age, row.score,
    row.visits, row.zip, row.timestamp, row.url
  ]
  for i, field in fields:
    result = result * 0x9E3779B185EBCA87'u64 + uint64(field.len + i)
    if field.len > 0:
      result = result xor (uint64(ord(field[0])) shl (i and 7))
      result = result xor (uint64(ord(field[^1])) shl ((i + 3) and 7))

proc parseAndMaterialize(path: string; rowsExpected: int): tuple[elapsedNs: float, check: uint64] =
  var parser: CsvParser
  parser.open(path)
  defer: parser.close()
  parser.readHeaderRow()

  var rows = newSeqOfCap[StoredRow](rowsExpected)
  let started = getMonoTime()
  while parser.readRow():
    var row: StoredRow
    row.id = parser.row[0]
    row.name = parser.row[1]
    row.age = parser.row[2]
    row.score = parser.row[3]
    row.visits = parser.row[4]
    row.zip = parser.row[5]
    row.timestamp = parser.row[6]
    row.url = parser.row[7]
    result.check = result.check * 0x9E3779B185EBCA87'u64 + checksum(row)
    rows.add row
  result.elapsedNs = float((getMonoTime() - started).inNanoseconds)
  doAssert rows.len == rowsExpected

proc main() =
  let cfg = parseConfig()
  let path = csvPath(cfg)
  writeCsv(path, cfg)
  defer:
    if fileExists(path):
      removeFile(path)

  let fileSize = getFileSize(path)
  var warm = parseAndMaterialize(path, cfg.rows)
  discard warm

  var totalNs = 0.0
  var bestNs = Inf
  var worstNs = 0.0
  var combined = uint64(fileSize) + uint64(cfg.rows)

  for round in 0..<cfg.rounds:
    let run = parseAndMaterialize(path, cfg.rows)
    totalNs += run.elapsedNs
    bestNs = min(bestNs, run.elapsedNs)
    worstNs = max(worstNs, run.elapsedNs)
    combined = combined * 0x9E3779B185EBCA87'u64 + run.check + uint64(round + 1)

  let avgNs = totalNs / cfg.rounds.float
  let nsPerRow = avgNs / cfg.rows.float
  echo "rows=", cfg.rows, "  rounds=", cfg.rounds, "  seed=", cfg.seed,
      "  file=", formatSize(fileSize)
  echo "avg=", fixed(avgNs / 1e6, 3), " ms",
      "  best=", fixed(bestNs / 1e6, 3), " ms",
      "  worst=", fixed(worstNs / 1e6, 3), " ms",
      "  ns/row=", fixed(nsPerRow, 1),
      "  check=0x", toHex(combined, 16)
  echo "MAXMEM=", formatSize getMaxMem()

when isMainModule:
  main()
