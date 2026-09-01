discard """
  matrix: "--mm:refc; --mm:orc; --mm:arc"
  targets: "c cpp"
  output: "ok"
"""

# Test that heap-allocated objects with .align use small chunks,
# not a big chunk per object (regression test for #25577).
type U = object
  d {.align: 32.}: int8

var e: seq[ref U]
for _ in 0 ..< 10000: e.add(new U)

# Without small-chunk alignment, each object gets its own page (~46 MB).
# With the fix, 10000 objects fit in ~1-3 MB depending on the GC.
doAssert getTotalMem() < 8 * 1024 * 1024, "align:32 heap objects use too much memory"

# Verify alignment is actually correct
for i in 0 ..< e.len:
  doAssert (cast[int](addr e[i].d) and 31) == 0, "field not 32-byte aligned"

echo "ok"
