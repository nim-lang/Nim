switch("path", "$lib/../testament/lib")
  # so we can `import stdtest/foo` inside tests
  # Using $lib/../ instead of $nim/ so you can use a different nim to run tests
  # during local testing, e.g. nim --lib:lib.

## prevent common user config settings to interfere with testament expectations
## Indifidual tests can override this if needed to test for these options.
switch("colors", "off")

switch("excessiveStackTrace", "off")

when (NimMajor, NimMinor, NimPatch) >= (1,5,1):
  # to make it easier to test against older nim versions, (best effort only)
  switch("filenames", "legacyRelProj")
  switch("spellSuggest", "0")

# for std/unittest
switch("define", "nimUnittestOutputLevel:PRINT_FAILURES")
switch("define", "nimUnittestColor:off")

switch("define", "nimLegacyTypeMismatch")

hint("Processing", off)
  # dots can cause annoyances; instead, a single test can test `hintProcessing`

# uncomment to enable all flaky tests disabled by this flag
# (works through process calls, e.g. tests that invoke nim).
# switch("define", "nimTestsEnableFlaky")

# switch("hint", "ConvFromXtoItselfNotNeeded")

# experimental API's are enabled in testament, refs https://github.com/timotheecour/Nim/issues/575
# sync with `kochdocs.docDefines` or refactor.
switch("define", "nimExperimentalAsyncjsThen")
switch("define", "nimExperimentalJsfetch")
switch("define", "nimExperimentalLinenoiseExtra")

switch("define", "nimFpRoundtrips")
