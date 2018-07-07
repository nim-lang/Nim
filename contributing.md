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

## code

### documentation
exported functions should have nimdoc comments (eg with `##`)

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

### proc vs template vs macro
as general rule of thumb, a proc should be preferred over a template, and a template should be preferred over a macro.

rationale:
* proc are more hygienic
* macros don't work well with UFCS
* templates and macros don't appear in stackraces, making debugging harder
* at high enough optimization levels, the C/C++ compiler will inline the corresponding proc anyways so shouldn't affect performance

