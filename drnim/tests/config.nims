switch("path", "$nim/testament/lib") # so we can `import stdtest/foo` in this dir

## prevent common user config settings to interfere with testament expectations
## Indifidual tests can override this if needed to test for these options.
switch("colors", "off")
switch("filenames", "canonical")
switch("excessiveStackTrace", "off")

# we only want to check the marked parts in the tests:
switch("staticBoundChecks", "off")
