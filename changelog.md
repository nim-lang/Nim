# v1.8.x - yyyy-mm-dd


## Changes affecting backward compatibility

- `addr` is now available for all addressable locations,
  `unsafeAddr` is now deprecated and an alias for `addr`.

- `io`, `assertions`, `formatfloat`, and `` dollars.`$` `` for objects are about to move out of the `system` module. You may instead import `std/syncio`, `std/assertions`, `std/formatfloat` and `std/objectdollar`.
  The `-d:nimPreviewSlimSystem` option makes these imports required.

- The `gc:v2` option is removed.

- The `mainmodule` and `m` options are removed.

- The `threads:on` option is now the default.

- Optional parameters in combination with `: body` syntax (RFC #405) are now opt-in via
  `experimental:flexibleOptionalParams`.

## Standard library additions and changes

- Pointer to `cstring` conversion now triggers a `[PtrToCstringConv]` warning.
  This warning will become an error in future versions! Use a `cast` operation
  like `cast[cstring](x)` instead.

- `logging` will default to flushing all log level messages. To get the legacy behaviour of only flushing Error and Fatal messages, use `-d:nimV1LogFlushBehavior`.

- Object fields now support default values, see https://nim-lang.github.io/Nim/manual.html#types-default-values-for-object-fields for details.

- Redefining templates with the same signature was previously
  allowed to support certain macro code. To do this explicitly, the
  `{.redefine.}` pragma has been added. Note that this is only for templates.
  Implicit redefinition of templates is now deprecated and will give an error in the future.

- Using an unnamed break in a block is deprecated. This warning will become an error in future versions! Use a named block with a named break instead.

- Several Standard libraries are moved to nimble packages, use `nimble` to install them:
  - `std/punycode` => `punycode`
  - `std/asyncftpclient` => `asyncftpclient`
  - `std/smtp` => `smtp`
  - `std/db_common` => `db_connector/db_common`
  - `std/db_sqlite` => `db_connector/db_sqlite`
  - `std/db_mysql` => `db_connector/db_mysql`
  - `std/db_postgres` => `db_connector/db_postgres`
  - `std/db_odbc` => `db_connector/db_odbc`

- Previously, calls like `foo(a, b): ...` or `foo(a, b) do: ...` where the final argument of
  `foo` had type `proc ()` were assumed by the compiler to mean `foo(a, b, proc () = ...)`.
  This behavior is now deprecated. Use `foo(a, b) do (): ...` or `foo(a, b, proc () = ...)` instead.

- If no exception or any exception deriving from Exception but not Defect or CatchableError given in except, a `warnBareExcept` warning will be triggered.

## Standard library additions and changes

- `macros.parseExpr` and `macros.parseStmt` now accept an optional
  filename argument for more informative errors.
- Module `colors` expanded with missing colors from the CSS color standard.
- Fixed `lists.SinglyLinkedList` being broken after removing the last node ([#19353](https://github.com/nim-lang/Nim/pull/19353)).


## Language changes


- Pragma macros on type definitions can now return `nnkTypeSection` nodes as well as `nnkTypeDef`,
  allowing multiple type definitions to be injected in place of the original type definition.

  ```nim
  import macros

  macro multiply(amount: static int, s: untyped): untyped =
    let name = $s[0].basename
    result = newNimNode(nnkTypeSection)
    for i in 1 .. amount:
      result.add(newTree(nnkTypeDef, ident(name & $i), s[1], s[2]))

  type
    Foo = object
    Bar {.multiply: 3.} = object
      x, y, z: int
    Baz = object

  # becomes

  type
    Foo = object
    Bar1 = object
      x, y, z: int
    Bar2 = object
      x, y, z: int
    Bar3 = object
      x, y, z: int
    Baz = object
  ```
- [Case statement macros](manual.html#macros-case-statement-macros) are no longer experimental,
  meaning you no longer need to enable the experimental switch `caseStmtMacros` to use them.

## Compiler changes

- `nim` can now compile version 1.4.0 as follows: `nim c --lib:lib --stylecheck:off compiler/nim`,
  without requiring `-d:nimVersion140` which is now a noop.

- `--styleCheck` now only applies to the current package.


## Tool changes

- The `gc` switch has been renamed to `mm` ("memory management") in order to reflect the
  reality better. (Nim moved away from all techniques based on "tracing".)

- Nim now supports Nimble version 0.14 which added support for lock-files. This is done by
  a simple configuration change setting that you can do yourself too. In `$nim/config/nim.cfg`
  replace `pkgs` by `pkgs2`.

- There is a new switch `--nimMainPrefix:prefix` to influence the `NimMain` that the
  compiler produces. This is particularly useful for generating static libraries.
