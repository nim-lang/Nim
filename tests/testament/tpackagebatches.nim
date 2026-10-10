import std/[assertions, sequtils]
import ../../testament/important_packages
# Include the implementation to exercise synthetic weights without exporting
# test-only configuration or tying assignments to the measured duration table.
include ../../testament/packagebatches

block partitions:
  let names = packages.mapIt(it.name)
  for platform in ["linux", "macosx"]:
    for count in [1, 2, 3, 7, names.len + 1]:
      let assignments = packageBatchAssignments(names, count, platform)
      doAssert assignments.len == names.len
      var seen = newSeq[int](names.len)
      for batch in 0..<count:
        for index, assigned in assignments:
          doAssert assigned >= 0 and assigned < count
          if assigned == batch:
            inc seen[index]
      doAssert seen.allIt(it == 1), "Every package must run in exactly one batch"
      if count == 1:
        doAssert assignments.allIt(it == 0)

block stableAssignment:
  let names = packages.mapIt(it.name)
  var reversed = names
  reversed.reverse()
  for platform in ["linux", "macosx"]:
    let forwardBatches = packageBatchAssignments(names, 3, platform)
    let reverseBatches = packageBatchAssignments(reversed, 3, platform)
    for index in 0..<names.len:
      doAssert forwardBatches[index] == reverseBatches[names.high - index],
        "A package's position in the registry must not change its batch"

block syntheticCosts:
  let names = ["a", "b", "c", "d"]
  doAssert weightedBatchAssignments(names, [9, 8, 7, 6], 2) == @[0, 1, 1, 0]
  doAssert weightedBatchAssignments(names, [9, 2, 2, 2], 2) == @[0, 1, 1, 1]
  doAssert weightedBatchAssignments(names, [2, 9, 2, 2], 2) == @[1, 0, 1, 1]

block platformCosts:
  let names = packages.mapIt(it.name)
  for platform in ["linux", "macosx"]:
    let durations = names.mapIt(estimatedDuration(it, platform))
    doAssert packageBatchAssignments(names, 3, platform) ==
      weightedBatchAssignments(names, durations, 3)

block invalidBatchCount:
  doAssertRaises AssertionDefect:
    discard packageBatchAssignments(["chronos"], 0)

block empty:
  doAssert packageBatchAssignments(newSeq[string](), 3).len == 0
