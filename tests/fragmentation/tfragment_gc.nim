discard """
  output: '''occupied ok: true
total ok: true'''
  disabled: "true"
"""

import strutils, data

proc main =
  var m = 0
  # Since the GC test is slower than the alloc test, we only iterate 100_000 times here:
  for i in 0..100_000:
    let size = sizes[i mod sizes.len]
    let p = newString(size)
 #   c_fprintf(stdout, "iteration: %ld size: %ld\n", i, size)

main()

let occ = getOccupiedMem()
let total = getTotalMem()

# Concrete values on Win64: 58.152MiB / 188.285MiB

let occupiedOk = occ < 82 * 1024 * 1024
if not occupiedOk:
  echo "occupied ", formatSize(occ)
echo "occupied ok: ", occupiedOk
let totalOk = total < 230 * 1024 * 1024
if not totalOk:
  echo "total peak memory ", formatSize(total)
echo "total ok: ", totalOk
