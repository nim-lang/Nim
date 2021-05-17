# Collection of benchmarks

In future work, benchmarks can be added to CI, but for now we provide benchmarks that can be run locally.

See RFC: https://github.com/timotheecour/Nim/issues/425

## guidelines
* tests should run in CI (so the test keeps working) but should complete fast (so it doesn't slow down CI).
  they should provide a knob (e.g. via `const numIter {.intdefine.} = 10`), so that users can re-run
  the benchmark manually with more meaningful parameters (e.g. `-d:numIter:100_000`).
