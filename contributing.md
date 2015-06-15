# The git stuff

[Guide by github, scroll down a bit](https://guides.github.com/activities/contributing-to-open-source/)

# Deprecation

Backward compatibility is important, so if you are renaming a proc or
a type, you can use

```nim
{.deprecated [oldName: new_name].}
```

Or you can simply use

```nim
proc oldProc() {.deprecated.}
```

to mark a symbol as deprecated. Works for procs/types/vars/consts,
etc.

[Deprecated pragma in the manual.](http://nim-lang.org/docs/manual.html#pragmas-deprecated-pragma)

# Writing tests

Not all the tests follow this scheme, feel free to change the ones
that don't. Always leave the code cleaner than you found it.

## Stdlib

If you change the stdlib (anything under `lib/`), put a test in the
file you changed. Add the tests under an `when isMainModule:`
condition so they only get executed when the tester is building the
file. Each test should be in a separate `block:` statement, such that
each has its own scope. Use boolean conditions and `assert` for the
testing by itself, don't rely on echo statements or similar.

Sample test:

```nim
when isMainModule:
  block lenTest:
    var values: HashSet[int]
    assert(not values.isValid)
    assert values.len == 0
    assert values.card == 0
  block setIterator:
    type pair = tuple[a, b: int]
    var a, b = initSet[pair]()
    a.incl((2, 3))
    a.incl((3, 2))
    a.incl((2, 3))
    for x, y in a.items:
      b.incl((x - 2, y + 1))
    assert a.len == b.card
    assert a.len == 2
```

## Compiler

The tests for the compiler work differently, they are all located in
`tests/`. Each test has its own file, which is different from the
stdlib tests. At the beginning of every test is the expected side of
the test. Possible keys are:

- output: The expected output, most likely via `echo`
- exitcode: Exit code of the test (via `exit(number)`)
- errormsg: The expected error message
- file: The file the errormsg
- line: The line the errormsg was produced at

An example for a test:
```nim
discard """
  errormsg: "type mismatch: got (PTest)"
"""

type
  PTest = ref object

proc test(x: PTest, y: int) = nil

var buf: PTest
buf.test()
```

# Running tests

You can run the tests with

    ./koch tests

which will run a good subset of tests. Some tests may fail.

# Comparing tests

Because some tests fail in the current `devel` branch, not every fail
after your change is necessarily caused by your changes.

TODO
