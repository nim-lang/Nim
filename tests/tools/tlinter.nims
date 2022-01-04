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


hint("Processing", off)
  # dots can cause annoyances; instead, a single test can test `hintProcessing`

