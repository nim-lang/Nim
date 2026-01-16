======================================
  Incremental Compilation (IC)
======================================

The ``nim ic`` command provides incremental compilation support for Nim projects,
allowing faster rebuilds by reusing previously compiled intermediate representations
of modules that haven't changed.

Overview
========

Incremental compilation works by decomposing the compilation process into several stages:

1. **Parsing** - Source files are parsed into an abstract syntax tree (AST)
2. **Semantic Analysis** - Symbols are resolved and type checking is performed
3. **Code Generation** - Platform-specific code is generated from the analyzed AST
4. **Linking** - The generated code is linked into an executable

The IC mechanism caches the results of earlier stages in NIF files
(Nim intermediate format): ``.p.nif`` (parsed), ``.deps.nif`` (dependencies),
and ``.nif`` (semantically analyzed). When recompiling, only modules that have
changed need to be reprocessed through the semantic analysis and code generation
stages, significantly reducing compilation time for large projects.

NIF File Format
===============

NIF (Nim Intermediate Format) files are text-based files that use a Lisp-like
syntax. They employ a hybrid format where byte offsets into the text are used for
efficient access, making them simultaneously human-readable and machine-efficient.
The text representation is particularly valuable for debugging and introspection.

Each ``.nim`` module produces its own ``.nif`` file during compilation.
The NIF format contains:

- **Header** - Version information (e.g., `(.nif26)`)
- **Dependencies** - List of source files and dependencies
- **Interface** - Exported symbols and their indices
- **Body** - The intermediate representation of the module's code in Lisp-like syntax

The NIF format is designed specifically for Nim and allows efficient serialization
and deserialization of the compiler's intermediate representation while remaining
readable and debuggable by tools and developers.

The ``nim ic`` Switch
=====================

The ``nim ic`` command initiates incremental compilation for a project.
It automatically manages the build process by:

1. Parsing all source files into ``.nif`` format (using the ``nifler`` tool)
2. Performing semantic analysis on modified modules
3. Generating code only for modules with changes or dependencies on changed modules
4. Generating a build file (in NIFMake format) that orchestrates the compilation
5. Executing the build file through ``nifmake``

Prerequisites
-------------

- **nifler** - Tool for parsing Nim source files into NIF format. The ``nim ic`` command uses ``nifler parse --deps`` to generate both parsed files (``.p.nif``) and dependency files (``.deps.nif``).
- **nifmake** - Build orchestration tool that follows dependencies and executes the build rules defined in ``.build.nif`` files.

If these tools are not available, ``nim ic`` will display instructions on how to
obtain them.

Key Modules for IC Logic
=========================

The primary modules in the compiler that handle incremental compilation logic are:

- **deps.nim** - Dependency analysis and build file generation. Contains the
  ``commandIc`` procedure which is the main entry point for the ``nim ic`` command.
  This module orchestrates the incremental compilation process, handling dependency
  traversal (via ``nifler deps``), build rule generation, and build file creation.
  The build file is written to ``nifcache/`` directory. This module also explicitly
  models ``system.nim`` as a dependency of all modules.

- **ast2nif.nim** - Core mapping between AST and NIF.


**Code, Logic & Debugging**
===========================

This section focuses on the compiler-side code paths, the logic you will
inspect while debugging IC, and a pragmatic manual workflow for bug hunting
using local invocations such as ``nim m --nimcache:nifcache``.

Core places to inspect
- **`compiler/deps.nim`**: generates the NIF-based build file and implements
  ``commandIc`` (entry point for ``nim ic``). Look for how build rules are
  emitted (calls to the NIF builder) and how inputs/outputs are wired.
- **`compiler/modulegraphs.nim`** and **`compiler/pipelines.nim`**:
  dependency graph and compilation pipeline integration — useful when a module
  is rebuilt unexpectedly.

Understanding the NIF text
- NIF files are human-readable; open the per-module ``.nif`` files in
  ``nifcache/`` to inspect parsed ASTs, dependency lists and interface tables.
- Because NIF uses textual nodes and byte offsets, tools can quickly seek to
  positions in the file — but for debugging you usually only need to read the
  file top-to-bottom.

Manual bug-hunting workflow
- Prepare a clean nimcache directory (relative to your project):

  ```bash
  mkdir -p nifcache
  ```

- Parse/semantic-check a single module and write NIF/sem artifacts:

  ```bash
  nim m --nimcache:nifcache path/to/module.nim
  ```

  - ``nim m`` runs the compiler up to the semantic checking stage for the
    specified module and emits intermediate cache files into ``nifcache/``.
  - Use this to reproduce and isolate failures in the semantic stage.

- Inspect the generated files for that module under ``nifcache/`` (look for
  ``.nif``, sem/parsed artifacts). Because NIF is text-based you can open and
  grep it directly:

  ```bash
  sed -n '1,200p' nifcache/ModuleName.nif
  grep -n "someSymbol" -n nifcache/ModuleName.nif
  ```

- To reproduce a full incremental compilation of the project, generate the
  build file and run it (``nim ic`` automates this). The build file is generated
  in ``nifcache/`` directory. To debug an individual build step, run the command
  that the build file would execute manually:
  - Parsing step: ``nifler parse --deps input.nim`` (produces ``.p.nif`` and ``.deps.nif``)
  - Semantic step: ``nim m --nimcache:nifcache input.nim`` (produces ``.nif``)
  - Code generation: ``nim nifc --nimcache:nifcache input.nim`` (produces executable)

- Force a cache invalidation for a single module by removing its NIF/sem
  artifact and re-running the semantic step:

  ```bash
  rm nifcache/ModuleName.nif
  nim m --nimcache:nifcache path/to/ModuleName.nim
  ```

- When investigating incorrect replayed state (pragmas, `{.compile: ...}`):
  inspect the replay actions in ``compiler/ic/replayer.nim`` and open the
  module's NIF to find the ``toReplay``/action entries that will be executed
  during reload.

Tips for efficient debugging
- Use ``--path:...`` flags when invoking ``nim m`` to emulate the exact
  search paths used in your project, e.g. ``--path:lib --path:vendor``.
- Compare two successive ``.nif`` files with ``diff`` to see what changed and
  why a module was rebuilt.

Where to change behavior
- Cache invalidation decisions and build-rule emission are implemented in
  ``compiler/deps.nim``. When investigating surprising
  rebuilds, instrument those modules to log the footprint/hash/comparison
  outcome.

See also
========

- `nif-spec` - NIF format specification (text format and node grammar):
  [nifspec/doc/nif-spec.md](../nifspec/doc/nif-spec.md)
