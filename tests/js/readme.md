## notes
Prefer moving tests to a non-js directory so that they get tested across all backends automatically.
Ideally, tests/js should be reserved to code that only makes sense in js.

Note also that tests for a js specific module (e.g.: `std/jsbigints`) belong to `tests/stdlib`, (e.g.: `tests/stdlib/tjsbigints.nim`)
