discard """
  action: compile
"""

## Dynamic object-dispatch benchmark with multiple chain shapes.
##
## Intended usage:
##   nim r -d:danger tests/benchmarks/typedispatch_shapes.nim
##   nim r -d:danger tests/benchmarks/typedispatch_shapes.nim --count=8000000 --rounds=12
##   nim r -d:danger tests/benchmarks/typedispatch_shapes.nim --workloads=uniform,hot
##
## The benchmark keeps allocation outside the timed region and compares:
##   1. exact leaf dispatch from the root type
##   2. family dispatch from the root type
##   3. mixed-generation dispatch from the root type
##   4. exact sibling dispatch from a narrowed static type
##   5. kind-field baselines matching each shape

import std/[monotimes, os, strutils, times]

const
  DefaultCount = 4_000_000
  DefaultRounds = 8
  DefaultWarmup = 2
  DefaultSeed = 0x9E37_79B9_7F4A_7C15'u64
  BranchCount = 4
  LeavesPerBranch = 4
  LeafCount = BranchCount * LeavesPerBranch

type
  Workload = enum
    wkUniform
    wkHot
    wkClustered

  Config = object
    count: int
    rounds: int
    warmup: int
    seed: uint64
    workloads: seq[Workload]

  LeafKind = enum
    kT00, kT01, kT02, kT03,
    kT10, kT11, kT12, kT13,
    kT20, kT21, kT22, kT23,
    kT30, kT31, kT32, kT33

  BaseTypeId {.inheritable.} = ref object
  B0 {.inheritable.} = ref object of BaseTypeId
  B1 {.inheritable.} = ref object of BaseTypeId
  B2 {.inheritable.} = ref object of BaseTypeId
  B3 {.inheritable.} = ref object of BaseTypeId
  T00 = ref object of B0
  T01 = ref object of B0
  T02 = ref object of B0
  T03 = ref object of B0
  T10 = ref object of B1
  T11 = ref object of B1
  T12 = ref object of B1
  T13 = ref object of B1
  T20 = ref object of B2
  T21 = ref object of B2
  T22 = ref object of B2
  T23 = ref object of B2
  T30 = ref object of B3
  T31 = ref object of B3
  T32 = ref object of B3
  T33 = ref object of B3

  BaseTagged {.inheritable.} = ref object
    kind: LeafKind
  KB0 {.inheritable.} = ref object of BaseTagged
  KB1 {.inheritable.} = ref object of BaseTagged
  KB2 {.inheritable.} = ref object of BaseTagged
  KB3 {.inheritable.} = ref object of BaseTagged
  KT00 = ref object of KB0
  KT01 = ref object of KB0
  KT02 = ref object of KB0
  KT03 = ref object of KB0
  KT10 = ref object of KB1
  KT11 = ref object of KB1
  KT12 = ref object of KB1
  KT13 = ref object of KB1
  KT20 = ref object of KB2
  KT21 = ref object of KB2
  KT22 = ref object of KB2
  KT23 = ref object of KB2
  KT30 = ref object of KB3
  KT31 = ref object of KB3
  KT32 = ref object of KB3
  KT33 = ref object of KB3

proc defaultConfig(): Config =
  Config(
    count: DefaultCount,
    rounds: DefaultRounds,
    warmup: DefaultWarmup,
    seed: DefaultSeed,
    workloads: @[wkUniform, wkHot, wkClustered]
  )

proc usage() =
  echo "Dynamic object-dispatch shape benchmark."
  echo ""
  echo "Usage:"
  echo "  nim r -d:danger tests/benchmarks/typedispatch_shapes.nim [--count=N] [--rounds=N]"
  echo "      [--warmup=N] [--seed=N] [--workloads=list]"
  echo ""
  echo "Workloads:"
  echo "  uniform   even spread over all leaf types"
  echo "  hot       one hot exact type plus rare outliers"
  echo "  clustered branch-locality friendly blocks"

proc parseWorkload(name: string): Workload =
  case name.normalize
  of "uniform":
    wkUniform
  of "hot":
    wkHot
  of "clustered":
    wkClustered
  else:
    quit "unknown workload: " & name

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
    elif arg.startsWith("--warmup="):
      result.warmup = parseInt(arg["--warmup=".len .. ^1])
    elif arg.startsWith("--seed="):
      result.seed = cast[uint64](parseBiggestUInt(arg["--seed=".len .. ^1]))
    elif arg.startsWith("--workloads="):
      result.workloads.setLen(0)
      for item in arg["--workloads=".len .. ^1].split(','):
        if item.len > 0:
          result.workloads.add parseWorkload(item)
    else:
      quit "unknown argument: " & arg

  if result.count <= 0:
    quit "--count must be > 0"
  if result.rounds <= 0:
    quit "--rounds must be > 0"
  if result.warmup < 0:
    quit "--warmup must be >= 0"
  if result.workloads.len == 0:
    quit "at least one workload is required"

proc workloadName(w: Workload): string =
  case w
  of wkUniform:
    "uniform"
  of wkHot:
    "hot"
  of wkClustered:
    "clustered"

proc workloadList(xs: openArray[Workload]): string =
  for i, x in xs:
    if i > 0:
      result.add ','
    result.add workloadName(x)

proc fixed(x: float; digits: range[0..32]): string =
  formatFloat(x, ffDecimal, digits)

proc nextRand(state: var uint64): uint64 =
  state = state xor (state shl 7)
  state = state xor (state shr 9)
  state = state xor (state shl 8)
  result = state

proc pickLeaf(workload: Workload; state: var uint64; index: int): LeafKind =
  case workload
  of wkUniform:
    result = LeafKind(nextRand(state) mod LeafCount.uint64)
  of wkHot:
    let r = nextRand(state)
    if (r mod 100) < 88:
      result = kT00
    else:
      result = LeafKind(1 + (r mod (LeafCount - 1).uint64).int)
  of wkClustered:
    let bucket = (index div 64) mod LeafCount
    result = LeafKind(bucket)

proc pickBranch0Leaf(workload: Workload; state: var uint64; index: int): LeafKind =
  case workload
  of wkUniform:
    result = LeafKind(nextRand(state) mod LeavesPerBranch.uint64)
  of wkHot:
    let r = nextRand(state)
    if (r mod 100) < 88:
      result = kT00
    else:
      result = LeafKind(1 + (r mod (LeavesPerBranch - 1).uint64).int)
  of wkClustered:
    let bucket = (index div 64) mod LeavesPerBranch
    result = LeafKind(bucket)

proc buildKinds(cfg: Config; workload: Workload): seq[LeafKind] =
  result = newSeq[LeafKind](cfg.count)
  var state = cfg.seed xor uint64(workload.ord + 1) * 0xD1342543DE82EF95'u64
  for i in 0..<cfg.count:
    result[i] = pickLeaf(workload, state, i)

proc buildBranch0Kinds(cfg: Config; workload: Workload): seq[LeafKind] =
  result = newSeq[LeafKind](cfg.count)
  var state = cfg.seed xor uint64(workload.ord + 9) * 0xA0761D6478BD642F'u64
  for i in 0..<cfg.count:
    result[i] = pickBranch0Leaf(workload, state, i)

proc newTypeIdObj(kind: LeafKind): BaseTypeId =
  case kind
  of kT00: T00()
  of kT01: T01()
  of kT02: T02()
  of kT03: T03()
  of kT10: T10()
  of kT11: T11()
  of kT12: T12()
  of kT13: T13()
  of kT20: T20()
  of kT21: T21()
  of kT22: T22()
  of kT23: T23()
  of kT30: T30()
  of kT31: T31()
  of kT32: T32()
  of kT33: T33()

proc newBranch0Obj(kind: LeafKind): B0 =
  case kind
  of kT00: T00()
  of kT01: T01()
  of kT02: T02()
  of kT03: T03()
  else:
    quit "branch0 benchmark received non-B0 leaf"

proc newTaggedObj(kind: LeafKind): BaseTagged =
  case kind
  of kT00: KT00(kind: kT00)
  of kT01: KT01(kind: kT01)
  of kT02: KT02(kind: kT02)
  of kT03: KT03(kind: kT03)
  of kT10: KT10(kind: kT10)
  of kT11: KT11(kind: kT11)
  of kT12: KT12(kind: kT12)
  of kT13: KT13(kind: kT13)
  of kT20: KT20(kind: kT20)
  of kT21: KT21(kind: kT21)
  of kT22: KT22(kind: kT22)
  of kT23: KT23(kind: kT23)
  of kT30: KT30(kind: kT30)
  of kT31: KT31(kind: kT31)
  of kT32: KT32(kind: kT32)
  of kT33: KT33(kind: kT33)

proc buildTypeIdData(kinds: openArray[LeafKind]): seq[BaseTypeId] =
  result = newSeq[BaseTypeId](kinds.len)
  for i, kind in kinds:
    result[i] = newTypeIdObj(kind)

proc buildBranch0TypeIdData(kinds: openArray[LeafKind]): seq[B0] =
  result = newSeq[B0](kinds.len)
  for i, kind in kinds:
    result[i] = newBranch0Obj(kind)

proc buildTaggedData(kinds: openArray[LeafKind]): seq[BaseTagged] =
  result = newSeq[BaseTagged](kinds.len)
  for i, kind in kinds:
    result[i] = newTaggedObj(kind)

proc exactRootScore(x: BaseTypeId): int {.inline.} =
  if x of T00: 1
  elif x of T01: 2
  elif x of T02: 3
  elif x of T03: 4
  elif x of T10: 5
  elif x of T11: 6
  elif x of T12: 7
  elif x of T13: 8
  elif x of T20: 9
  elif x of T21: 10
  elif x of T22: 11
  elif x of T23: 12
  elif x of T30: 13
  elif x of T31: 14
  elif x of T32: 15
  elif x of T33: 16
  else: 0

proc familyRootScore(x: BaseTypeId): int {.inline.} =
  if x of B0: 1
  elif x of B1: 2
  elif x of B2: 3
  elif x of B3: 4
  else: 0

proc mixedRootScore(x: BaseTypeId): int {.inline.} =
  if x of B0: 1
  elif x of T10: 2
  elif x of T11: 3
  elif x of B2: 4
  elif x of T30: 5
  elif x of T31: 6
  else: 0

proc exactSiblingScore(x: B0): int {.inline.} =
  if x of T00: 1
  elif x of T01: 2
  elif x of T02: 3
  elif x of T03: 4
  else: 0

proc kindLeafScore(x: BaseTagged): int {.inline.} =
  case x.kind
  of kT00: 1
  of kT01: 2
  of kT02: 3
  of kT03: 4
  of kT10: 5
  of kT11: 6
  of kT12: 7
  of kT13: 8
  of kT20: 9
  of kT21: 10
  of kT22: 11
  of kT23: 12
  of kT30: 13
  of kT31: 14
  of kT32: 15
  of kT33: 16

proc kindFamilyScore(x: BaseTagged): int {.inline.} =
  case x.kind
  of kT00, kT01, kT02, kT03: 1
  of kT10, kT11, kT12, kT13: 2
  of kT20, kT21, kT22, kT23: 3
  of kT30, kT31, kT32, kT33: 4

proc kindMixedScore(x: BaseTagged): int {.inline.} =
  case x.kind
  of kT00, kT01, kT02, kT03: 1
  of kT10: 2
  of kT11: 3
  of kT20, kT21, kT22, kT23: 4
  of kT30: 5
  of kT31: 6
  else: 0

proc kindSiblingScore(x: BaseTagged): int {.inline.} =
  case x.kind
  of kT00: 1
  of kT01: 2
  of kT02: 3
  of kT03: 4
  else: 0

proc runExactRoot(xs: openArray[BaseTypeId]): uint64 =
  var acc = 0'u64
  for x in xs:
    acc = acc * 131'u64 + uint64(exactRootScore(x))
  result = acc

proc runFamilyRoot(xs: openArray[BaseTypeId]): uint64 =
  var acc = 0'u64
  for x in xs:
    acc = acc * 131'u64 + uint64(familyRootScore(x))
  result = acc

proc runMixedRoot(xs: openArray[BaseTypeId]): uint64 =
  var acc = 0'u64
  for x in xs:
    acc = acc * 131'u64 + uint64(mixedRootScore(x))
  result = acc

proc runExactSibling(xs: openArray[B0]): uint64 =
  var acc = 0'u64
  for x in xs:
    acc = acc * 131'u64 + uint64(exactSiblingScore(x))
  result = acc

proc runKindLeaf(xs: openArray[BaseTagged]): uint64 =
  var acc = 0'u64
  for x in xs:
    acc = acc * 131'u64 + uint64(kindLeafScore(x))
  result = acc

proc runKindFamily(xs: openArray[BaseTagged]): uint64 =
  var acc = 0'u64
  for x in xs:
    acc = acc * 131'u64 + uint64(kindFamilyScore(x))
  result = acc

proc runKindMixed(xs: openArray[BaseTagged]): uint64 =
  var acc = 0'u64
  for x in xs:
    acc = acc * 131'u64 + uint64(kindMixedScore(x))
  result = acc

proc runKindSibling(xs: openArray[BaseTagged]): uint64 =
  var acc = 0'u64
  for x in xs:
    acc = acc * 131'u64 + uint64(kindSiblingScore(x))
  result = acc

proc measure(name: string; ops, rounds, warmup: int; run: proc(): uint64 {.closure.}) =
  var checksum = 0'u64
  for _ in 0..<warmup:
    checksum = checksum xor run()

  var totalNs = 0.0
  var bestNs = Inf
  var worstNs = 0.0
  for round in 0..<rounds:
    let started = getMonoTime()
    let value = run()
    let elapsedNs = float((getMonoTime() - started).inNanoseconds)
    totalNs += elapsedNs
    bestNs = min(bestNs, elapsedNs)
    worstNs = max(worstNs, elapsedNs)
    checksum = checksum * 0x9E3779B185EBCA87'u64 + value + uint64(round + 1)

  let avgNs = totalNs / rounds.float
  let nsPerOp = avgNs / ops.float
  echo alignLeft(name, 18),
       " avg=", align(fixed(avgNs / 1_000_000.0, 3), 8), " ms",
       " best=", align(fixed(bestNs / 1_000_000.0, 3), 8), " ms",
       " worst=", align(fixed(worstNs / 1_000_000.0, 3), 8), " ms",
       " ns/op=", align(fixed(nsPerOp, 3), 8),
       " checksum=0x", toHex(checksum)

proc main() =
  let cfg = parseConfig()
  echo "Dynamic object dispatch shape benchmark"
  echo "count=", cfg.count,
       " rounds=", cfg.rounds,
       " warmup=", cfg.warmup,
       " workloads=", workloadList(cfg.workloads)
  echo ""

  for workload in cfg.workloads:
    echo "[root ", workloadName(workload), "]"
    let kinds = buildKinds(cfg, workload)
    let typeIds = buildTypeIdData(kinds)
    let tagged = buildTaggedData(kinds)

    measure("exact root of", cfg.count, cfg.rounds, cfg.warmup,
      proc(): uint64 = runExactRoot(typeIds))
    measure("kind leaf", cfg.count, cfg.rounds, cfg.warmup,
      proc(): uint64 = runKindLeaf(tagged))
    measure("family root of", cfg.count, cfg.rounds, cfg.warmup,
      proc(): uint64 = runFamilyRoot(typeIds))
    measure("kind family", cfg.count, cfg.rounds, cfg.warmup,
      proc(): uint64 = runKindFamily(tagged))
    measure("mixed root of", cfg.count, cfg.rounds, cfg.warmup,
      proc(): uint64 = runMixedRoot(typeIds))
    measure("kind mixed", cfg.count, cfg.rounds, cfg.warmup,
      proc(): uint64 = runKindMixed(tagged))
    echo ""

    echo "[siblings ", workloadName(workload), "]"
    let branch0Kinds = buildBranch0Kinds(cfg, workload)
    let branch0TypeIds = buildBranch0TypeIdData(branch0Kinds)
    let branch0Tagged = buildTaggedData(branch0Kinds)

    measure("exact sibling of", cfg.count, cfg.rounds, cfg.warmup,
      proc(): uint64 = runExactSibling(branch0TypeIds))
    measure("kind sibling", cfg.count, cfg.rounds, cfg.warmup,
      proc(): uint64 = runKindSibling(branch0Tagged))
    echo ""

when isMainModule:
  main()
