.. default-role:: code

=====================
  Nimfix User Guide
=====================

:Author: Andreas Rumpf
:Version: |nimversion|

**WARNING**: Nimfix is currently beta-quality.

Nimfix is a tool to help you upgrade from Nimrod (<= version 0.9.6) to
Nim (=> version 0.10.0).

It performs 3 different actions:

1. It makes your code case consistent.
2. It renames every symbol that has a deprecation rule. So if a module has a
   rule `{.deprecated: [TFoo: Foo].}` then `TFoo` is replaced by `Foo`.
3. It can also check that your identifiers adhere to the official style guide
   and optionally modify them to do so (via `--styleCheck:auto`).

Note that `nimfix` defaults to **overwrite** your code unless you
use `--overwriteFiles:off`! But hey, if you do not use a version control
system by this day and age, your project is already in big trouble.


Installation
------------

Nimfix is part of the compiler distribution. Compile via::

  nim c compiler/nimfix/nimfix.nim
  mv compiler/nimfix/nimfix bin

Or on windows::

  nim c compiler\nimfix\nimfix.nim
  move compiler\nimfix\nimfix.exe bin

Usage
-----

Usage:
  nimfix [options] projectfile.nim

Options:

  --overwriteFiles:on|off       overwrite the original nim files. DEFAULT is ON!
  --wholeProject                overwrite every processed file.
  --checkExtern:on|off          style check also extern names
  --styleCheck:on|off|auto      performs style checking for identifiers
                                and suggests an alternative spelling;
                                'auto' corrects the spelling.

In addition, all command line options of Nim are supported.


