# Native Nim dynamic-library fixture

This experiment keeps native binding generation outside the compiler. The
compiler owns only facts that require backend authority:

- `{.exportabi.}` and its final Itanium-style symbol;
- collection of concrete exported instances;
- a compact `<library>.abi.nif` mapping semantic NIF symbols to backend symbols,
  with compiler, target, memory-manager, and allocator facts.

`exportabi` reuses Nim's ordinary external-export and shared-library visibility
machinery. It differs from `exportc` only in who chooses the external name:
the backend fills it with a signature-aware Nim name instead of accepting a
fixed C name from the source pragma. The pragma requires the experimental
`abi` feature while this native ABI contract is still evolving; `--emitBif`
itself remains available independently of that language feature.

To support ABI exports whose signatures use public types from imported modules,
the experimental feature also gives externally linkable names to compatible
custom hooks attached to public types. The manifest exposes only the hooks that
are reachable from the library's exported ABI surface.

The third-party generator reads that manifest together with the root module's
stable semantic BIF and emits `producer_abi.nim`. That generated module contains
real Nim `object` and `ref object` declarations, native `nimcall` dynlib imports,
and public wrappers that initialize the library before use.

The first slice supports non-generic procedures and auto-managed object graphs.
The example crosses `string`, a by-value object, and nested `ref object` values,
then performs ordinary public field reads and writes in the consumer. Producer
and consumer are deliberately compiled with the same compiler, ORC, and
allocator mode.

Custom attached ownership hooks reachable from exported signatures are emitted
as native ABI exports and recreated as forwarding hooks in the generated
binding. Compiler-generated structural hooks remain local and are lifted again
by the consumer compiler. The fixture verifies custom `=copy` and `=destroy`
calls against producer-side counters.

The consumer prints the native library initialization and calls the exported
`message` proc. Edit the string returned by `message` in `producer.nim`, run
`build_producer.sh` followed by `build_consumer.sh`, and check that the consumer
prints the updated value. This gives a visible sanity check that the generated
binding called into the rebuilt dynamic library.

Inheritance, variants, open generics, exceptions, and runtime ABI mismatch
rejection are not supported yet.

Build a compiler from this branch and run:

```sh
NIM_NATIVE_DYNLIB_COMPILER=/path/to/nim ./build_e2e.sh
```

To rebuild each side separately, run:

```sh
NIM_NATIVE_DYNLIB_COMPILER=/path/to/nim ./build_producer.sh
NIM_NATIVE_DYNLIB_COMPILER=/path/to/nim ./build_consumer.sh
```

`build_producer.sh` produces the shared library and ABI artifacts.
`build_consumer.sh` regenerates the Nim bindings, then builds and runs the
consumer against the existing producer library.

The compiler stages the manifest in `nimcache`, then publishes one manifest
beside the successfully linked dynamic library. The public manifest covers the
complete library export surface; its module table identifies every source
module that contributed an exported procedure.

The shared library and its stable semantic BIF are produced together by an
ordinary `nim c --experimental:abi --emitBif:on --app:lib` build. This reuses
the IC artifact format without requiring the target library to build through
`nim ic`. C-header generation is not part of this first native proof.
