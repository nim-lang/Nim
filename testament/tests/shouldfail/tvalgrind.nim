discard """
  valgrind: true
  cmd: "nim $target --gc:arc -d:useMalloc $options $file"
"""

# this is the same check used by testament/specs.nim whether or not valgrind
# tests are supported
when defined(linux) and sizeof(int) == 8:
  # discarding this allocation will cause valgrind to fail (which is what we
  # want), but valgrind only runs on 64-bit Linux machines...
  discard alloc(1)
else:
  # ...so on all other OS/architectures, simulate any non-zero exit code to
  # mimic how valgrind would have failed on this test. We cannot use things like
  # `disabled: "freebsd"` in the Testament configs above or else the tests will
  # be SKIP-ed rather than FAIL-ed
  quit(1) # choose 1 to match valgrind's `--error-exit=1`, but could be anything
