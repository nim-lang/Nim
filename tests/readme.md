This directory contains the test cases.

Each test must have a filename of the form: ``t*.nim``

**Note:** Testament is only aware of tests under a directory (eg `tests/foo/`) and will ignore
top-level tests like `tests/tbar.nim`.

# Specs

Each test can contain a spec in a ``discard """ ... """`` block.

**Check out the [``parseSpec`` procedure](https://github.com/nim-lang/Nim/blob/devel/testament/specs.nim#L158) in the ``specs`` module for a full and reliable reference**

## action

Specifies what action this test should take.

**Default: run**

Options:

* ``compile`` - compiles the module and fails the test if compilations fails.
* ``run`` - compiles and runs the module, fails the test if compilation or
            execution of test code fails.
* ``reject`` - compiles the module and fails the test if compilation succeeds.

There are certain spec keys that imply ``run``, including ``output`` and
``outputsub``.

## cmd

Specifies the Nim command to use for compiling the test.

There are a number of variables that are replaced in this spec option:

* ``$target`` - the compilation target, e.g. ``c``.
* ``$options`` - the options for the compiler.
* ``$file`` - the filename of the test.
* ``$filedir`` - the directory of the test file.

Example:

```nim
discard """
  cmd: "nim $target --nimblePath:./nimbleDir/simplePkgs $options $file"
"""
```

# Categories

Each folder under this directory represents a test category, which can be
tested by running `koch tests pcat <category>` (or `cat` to avoid parallel
testing, which is slower).

The folder ``dll`` contains simple DLL tests.

The folder ``realtimeGC`` contains a test for validating that the realtime GC
can run properly without linking against the nimrtl.dll/so.
