discard """
  matrix: "--verbosity:0 --os:standalone --mm:none; --verbosity:0 --os:standalone --mm:arc --threads:off -d:sizeOverflow; --verbosity:0 --os:standalone --mm:arc --threads:off -d:outOfMem"
  outputsub: "PANIC: "
"""

# The fatal paths of the runtime end in the `panic` of the `panicoverride`
# (which prints `PANIC: `) with `--os:standalone`, not in libc. A fatal error
# ends the process, so each one is an item of the matrix.

when defined(sizeOverflow):
  # the payload size computations are checked
  var s = newStringOfCap(high(int))
  discard s
elif defined(outOfMem) and sizeof(int) == 8:
  var s = newStringOfCap(high(int) div 2)
  discard s
else:
  # bug #21195
  var n = 11
  assert(n == 12)
