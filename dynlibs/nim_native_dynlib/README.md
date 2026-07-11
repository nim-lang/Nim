# Nim native dynlib simple4

This experiment keeps native binding generation outside the compiler. The
compiler owns only facts that require backend authority:

- `{.exportabi.}` and its final Itanium-style symbol;
- collection of concrete exported instances;
- a compact `<project>.abi.json` mapping semantic NIF symbols to backend symbols, with compiler, target, memory-manager, and allocator facts.

`exportabi` reuses Nim's ordinary external-export and shared-library visibility
machinery. It differs from `exportc` only in who chooses the external name:
the backend fills it with a signature-aware Nim name instead of accepting a
fixed C name from the source pragma.

The third-party generator reads that manifest together with the root module's
stable semantic BIF and emits `producer_abi.nim`. That generated module contains
real Nim `object` and `ref object` declarations, native `nimcall` dynlib imports,
and public wrappers that initialize the library before use.

The first slice supports non-generic procedures and auto-managed object graphs.
The example crosses `string`, a by-value object, and nested `ref object` values,
then performs ordinary public field reads and writes in the consumer. Producer
and consumer are deliberately compiled with the same compiler, ORC, and
allocator mode.

Custom ownership hooks, inheritance, variants, open generics, exceptions, and
runtime ABI mismatch rejection are not supported yet.

Build a compiler from this branch and run:

```sh
NIM_NATIVE_DYNLIB_COMPILER=/path/to/nim ./build_e2e.sh
```

The shared library and its stable semantic BIF are produced together by an
ordinary `nim c --emitAbiBif:on --app:lib` build. This reuses the IC artifact
format without requiring the target library to build through `nim ic`.
C-header generation is not part of this first native proof.
