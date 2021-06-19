---
name: Bug report
about: Have you found an unexpected behavior? Use this template.
title: Think about the title, twice
labels: ''
assignees: ''

---

(Consider writing a PR targetting devel branch after filing this, see [contributing.html](https://nim-lang.github.io/Nim/contributing.html)).

Function `echo` outputs the wrong string.

### Example
```nim
echo "Hello World!"
# This code should be a minimum reproducible example:
# try to simplify and minimize as much as possible. If it's a compiler
# issue, try to minimize further by removing any imports if possible.
```

### Current Output
please check whether the problem still exists in git head before posting,
see [rebuilding the compiler](https://nim-lang.github.io/Nim/intern.html#rebuilding-the-compiler).
```
Hola mundo!
```

### Expected Output
```
Hello World!
```

### Possible Solution

* In file xyz there is a call that might be the cause of it.

### Additional Information
If it's a regression, you can help us by identifying which version introduced
the bug, see [Bisecting for regressions](https://nim-lang.github.io/Nim/intern.html#bisecting-for-regressions),
or at least try known past releases (eg `choosenim 1.2.0`).

If it's a pre-existing compiler bug, see [Debugging the compiler](https://nim-lang.github.io/Nim/intern.html#debugging-the-compiler)
which should give more context on a compiler crash.

* Issue #abc is related, but different because of ...
* This issue is blocking my project xyz

```
$ nim -v
Nim Compiler Version 0.1.2
# make sure to include the git hash if not using a tagged release
```
