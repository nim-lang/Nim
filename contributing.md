# guidelines for contributing PR's, code style guide, guidelines for issues, forum
This document should grow over time. These are just guidelines not hard rules (depending on circumstances).
Rationale should be provided for contentious guidelines.

## git
### use `git rebase` instead of `git merge`
In command line (for person doing PR):
```
git pull --rebase origin devel
# etc: resolve conflicts
```
In github (for person integrating PR):
use `Rebase and merge` instead of `Squash and merge`:
https://help.github.com/articles/about-pull-request-merges/#rebase-and-merge-your-pull-request-commits

rationale:
* keeps history linear
* makes it practical to use git bisect
* no-one cares when a feature was started being worked on
* makes it a bit harder on committer (he may have to resolve conflicts a bit more often after `git pull --rebase origin devel` than after `git pull origin devel`) but makes it easier for everyone else

There is some debate on rebase vs merge but generally the arguments for `git merge` are that it's simpler to use (less merge conflicts)
see also: https://github.com/nim-lang/Nim/pull/2981

### squashing commits
in a multi-commit PR, trivial commits should be squashed; more complex commits (or commits that deal with individual aspects) should not be squashed
```
git rebase -i $starting_hash^
# etc
```

## github issues
* include `nim --version` and OS information in PR
TODO: we should have a cmd line to get all context we need, eg: `nim --issueContext`, analog to `brew gist-logs`
* make sure to include verbatim relevant parts of error message, to make it easier to search for dedupping

## forum
### forum title should be descriptive
Here are some examples take from https://forum.nim-lang.org/

good:
* Jester v0.3.0 and our first CVE ID
* How to pass module and function name to call in a template (or macro)?

bad:
* "explain this behavior for me"
* "i have some question !?"

## documentation
exported functions should have nimdoc comments (eg with `##`)

## testing

### runnableExamples
* try to use `runnableExamples:` block to make generated docs more illustrative and for testing purposes

### unit tests
* more extensive testing (eg that would be overkill for docs) can be done in `when isMainModule` blocks right below the proc:

```nim
proc absolutePath*(path: string, root = getCurrentDir()): string =
    ## Returns the absolute path of `path`, rooted at `root` (which must be absolute)
    ## if `path` is absolute, return it, ignoring `root`
    runnableExamples:
      doAssert absolutePath("a") == getCurrentDir() / "a"
    if isAbsolute(path): path
    ...
  
  when isMainModule:
    doAssertRaises(ValueError): discard absolutePath("a", "b")
    doAssert absolutePath("a") == getCurrentDir() / "a"
    ...
```

### integration tests
TODO

## code
Here's a sample code that can serve as reference:
```nim
proc myStringify(a: int) : string =
  ## Stringifies ``a``.
  ##
  ## On Windows, follows this [spec](https://en.wikipedia.org/wiki/Hidden_file_and_hidden_directory).
  ##
  ## **Warning:** may call ``mod.funName`` depending on ``a``.
  runnableExamples:
    doAssert foo(0) == "0"
  result = $(a)
```
* we use double backticks (bolds text in RST) as ooposed to single backticks (italicizes it)

### prefer `proc` > `template` > `macro` when possible
As general rule of thumb, a `proc` should be preferred over a `template`, and a `template` should be preferred over a `macro` whenever possible (use the simplest tool for the job).

rationale:
* procedures are more hygienic and easier to debug
* procedures are compiled only once (or once per instantiating type for generics), unlike templates and macros which are evaluated at every call site; this can affect compile time performance
* templates and macros don't appear in stackraces, making debugging harder
* at high enough optimization levels, the C/C++ compiler will inline the corresponding proc anyways so shouldn't affect performance

Caveats with templates and macros: `untyped` parameters can prevent method call syntax in some cases, eg `myIter.toSeq` see [docs](https://nim-lang.org/docs/manual.html#templates-limitations-of-the-method-call-syntax)

### prefer `any` or `void` (or even `auto`) over `untyped` for `template` and `macro` output when possible
rationale: early type checking makes it easier to debug errors

### prefer `any` or a explicit or generic type over `untyped` for `template` and `macro` parameters when possible
rationale: early type checking makes it easier to debug errors

###  use `void` instead of `typed` for `template` and `macro` output
```nim
# don't use that, `typed` as output means something very different from `typed` as parameter
template foo(): typed = discard

# instead use one of these which are synonyms and more readable
template foo(): void = discard
template foo() = discard
```
