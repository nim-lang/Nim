# IC dynlib spike

This directory demonstrates that a dynamic-library package can live outside
the compiler and use incremental compilation's semantic BIF files as its typed
input. It generates and exercises both a Nim wrapper and a C header.

It is a feasibility spike, not yet a versioned production ABI.

## What works

`dynexport` is a typed annotation macro. It rewrites a concrete routine to
`exportc, dynlib` and derives its external name from `signatureHash`:

```nim
import icdynlib

proc answer(x: cint): cint {.dynexport.} =
  x + 1
```

The signature hash gives overloads distinct external names without adding a
new compiler pragma. The typed macro validates the ABI and embeds versioned
signature metadata in the module's content-stable `<suffix>.s.bif` artifact.

`bifexports.readDynlibExports` reads that artifact through Nimony's stable BIF
reader and discovers the marked declarations. `generate.nim` locates the root
module's semantic BIF by its `modulesrc` record and emits:

- `<api>.h`, with exact hashed entry points and stable friendly aliases;
- `<api>_dynlib.nim`, with typed imports, automatic one-time `NimMain`
  initialization, and overloaded public wrappers.

`inspect.nim` is a small command-line demonstration of export discovery:

```text
answer  nimdyn___YzogPqt68Fe9a3BCKOltESQ
answer  nimdyn___ExD4OroraObaZ6beL8G9c4g
```

Run the end-to-end example with a compiler built from this branch:

```sh
NIM_ICDYNLIB_COMPILER=/path/to/nim ./build_e2e.sh
```

It builds the producer with `nim ic --app:lib`, generates both artifacts,
calls every export from Nim and C, and verifies that managed and generic ABI
declarations are rejected at compile time.

## Proposed package boundary

The third-party package should own:

- the `dynexport` annotation and ABI validation;
- reading semantic BIF and resolving exported signatures;
- generation of a Nim import module and ABI manifest;
- explicit library initialization and version/fingerprint checks;
- content-stable writes, driven by the producer module's interface cookie.

The compiler should only provide general IC capabilities. Two small upstream
changes are sufficient for this spike:

- forward the selected application kind, including `--app:lib`, to IC child
  processes;
- run the existing compiler header generator from the main IC codegen process
  when `--header` is requested.

The second change reuses the authoritative backend C-header generator for the
library root module without inventing a dynlib-specific compiler API. The
third-party package does not need that header for its initial scalar and
pointer ABI, but can consume it later for compiler-laid-out POD values. Making
`--header` collect otherwise-unused `exportc` declarations from imported
modules would be a separate whole-project extension; the spike deliberately
keeps its public ABI declarations in the root module.

## Initial ABI scope

The implemented boundary is deliberately C-shaped:

- C integer and floating types, `csize_t`, and raw pointers;
- opaque handles represented as pointers, with explicit lifetime procedures;
- no exceptions crossing the boundary;
- no `string`, `seq`, closure, `ref object`, or allocator-owned value crossing
  the boundary;
- concrete procedures only; generic APIs use explicit concrete wrappers.

This avoids coupling the first release to Nim object layout, ARC/ORC hooks,
runtime type information, or allocator identity. The compiler-generated header
can describe plain object layout and exposes `ref object` as an opaque pointer.
A transparent same-build Nim ABI like `nim-native-dynlib-simple2` remains a
later mode because managed values still need an ownership-hook and runtime
compatibility contract.

## Next implementation slices

1. Add a manifest containing compiler, target, MM, application, and API
   fingerprints, then reject incompatible libraries before initialization.
2. Integrate generation into a package command that wraps `nim ic --app:lib`
   and writes outputs only when their content changes.
3. Decide whether POD object support should consume the compiler header or a
   smaller machine-readable layout artifact.
4. Design an explicit opt-in managed ABI only after ownership hooks and runtime
   compatibility can be checked reliably.
