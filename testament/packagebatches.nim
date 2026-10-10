## Balance package CI batches by estimated running time rather than package count.
## Estimates include cloning, dependency installation and the package's test command.
## Update the slow-package estimates from successful Packages CI logs when needed.
## Initial measurements: https://github.com/nim-lang/Nim/actions/runs/37336005489

import std/algorithm

const packageDurations = [
  (name: "arraymancer", linux: 75, macos: 89),
  (name: "bigints", linux: 29, macos: 37),
  (name: "bncurve", linux: 36, macos: 34),
  (name: "chronos", linux: 226, macos: 172),
  (name: "confutils", linux: 219, macos: 292),
  (name: "constantine", linux: 136, macos: 309),
  (name: "datamancer", linux: 148, macos: 172),
  (name: "docopt", linux: 39, macos: 23),
  (name: "eth", linux: 50, macos: 73),
  (name: "faststreams", linux: 137, macos: 73),
  (name: "ggplotnim", linux: 67, macos: 80),
  (name: "httputils", linux: 40, macos: 56),
  (name: "json_rpc", linux: 330, macos: 318),
  (name: "json_serialization", linux: 150, macos: 96),
  (name: "lockfreequeues", linux: 247, macos: 862),
  (name: "metrics", linux: 159, macos: 208),
  (name: "netty", linux: 13, macos: 33),
  (name: "nimPNG", linux: 25, macos: 38),
  (name: "nimcrypto", linux: 131, macos: 217),
  (name: "nimib", linux: 45, macos: 70),
  (name: "nimlsp", linux: 116, macos: 69),
  (name: "nimterop", linux: 159, macos: 10),
  (name: "nitter", linux: 57, macos: 65),
  (name: "noise", linux: 43, macos: 22),
  (name: "norm", linux: 15, macos: 42),
  (name: "normalize", linux: 21, macos: 50),
  (name: "numericalnim", linux: 21, macos: 48),
  (name: "pixie", linux: 256, macos: 10),
  (name: "presto", linux: 64, macos: 64),
  (name: "prologue", linux: 26, macos: 36),
  (name: "serialization", linux: 53, macos: 39),
  (name: "ssz_serialization", linux: 207, macos: 195),
  (name: "stew", linux: 60, macos: 51),
  (name: "taskpools", linux: 539, macos: 228),
  (name: "testutils", linux: 106, macos: 108),
  (name: "toml_serialization", linux: 132, macos: 62),
  (name: "unittest2", linux: 119, macos: 162),
  (name: "weave", linux: 163, macos: 10),
  (name: "web3", linux: 48, macos: 59),
  (name: "websock", linux: 92, macos: 80)
]

func estimatedDuration(name, platform: string): int =
  for duration in packageDurations:
    if duration.name == name:
      return if platform == "macosx": duration.macos else: duration.linux
  result = 10 # Most small packages take less than ten seconds, including setup.

proc weightedBatchAssignments(names: openArray[string], durations: openArray[int],
    batchCount: int): seq[int] =
  doAssert batchCount > 0
  doAssert names.len == durations.len
  type WeightedPackage = tuple[index: int, name: string, seconds: int]
  var ordered: seq[WeightedPackage]
  for index, name in names:
    ordered.add (index, name, durations[index])
  ordered.sort(proc(a, b: WeightedPackage): int =
    result = cmp(b.seconds, a.seconds)
    if result == 0:
      result = cmp(a.name, b.name)
  )

  result = newSeq[int](names.len)
  var loads = newSeq[int](batchCount)
  for package in ordered:
    var batch = 0
    for candidate in 1..<batchCount:
      if loads[candidate] < loads[batch]:
        batch = candidate
    result[package.index] = batch
    loads[batch] += package.seconds

proc packageBatchAssignments*(names: openArray[string], batchCount: int,
    platform = hostOS): seq[int] =
  ## Return one batch index per package. Schedule the longest packages first,
  ## each into the batch with the lowest estimated load. Ties use package names
  ## and then batch indices, so all runners compute the same partition.
  var durations: seq[int]
  for name in names:
    durations.add estimatedDuration(name, platform)
  result = weightedBatchAssignments(names, durations, batchCount)
