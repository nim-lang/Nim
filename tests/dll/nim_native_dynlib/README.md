# Native Nim dynamic-library test

This is the minimal compiler regression test for `{.exportabi.}`. It builds a
shared library, loads its signature-aware linker symbol through Nim's ordinary
`dynlib` pragma, initializes the producer runtime, and calls the export.

The BIF reader, binding generator, and complete ownership-hook example live in
Binny's `examples/nim_native_dynlib` directory.
