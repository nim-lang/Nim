# Package CI source cache

The existing Packages CI matrix also maintains a cache of bare Git repositories.
It records the Git downloads made by the real package tests, including dependencies
installed by package-specific tasks. There is no separate dependency list to keep
in sync with `testament/important_packages.nim`.

Each OS, architecture and package batch has its own snapshot. A successful `devel`
run creates one when the package list, batch assignments, Nimble pin or cache
tooling changes. The same matrix runs every Monday and can be started with **Run
workflow** on `devel` to refresh the snapshot. These refreshes matter because most
packages are tested at HEAD. No second copy of the package tests is added to a run.

PR jobs restore the latest matching snapshot from the base/default branch under
GitHub's normal cache access rules. A snapshot from older inputs can seed a new
one. Only trusted `nim-lang/Nim` `devel` jobs save snapshots or clone new mirrors;
PR cache misses go directly upstream. The cache actions are optional: a cache
service outage does not stop the package tests.

## Why bare repositories

`package_source_cache.nim` is compiled with the CI bootstrap compiler and installs
a job-local Git wrapper and remote helper. Git URL rewriting sends network reads
to bare mirrors, served by `git upload-pack`.
This supports Nimble's shallow clones and fetches. Atlas's static Git HTTP server
uses dumb HTTP, which does not support shallow cloning. A smart HTTP server could
work, but would add a server process and port without helping jobs on separate VMs.

The first use of each mirror in a job fetches the current upstream refs, tags and
HEAD. Mirrors keep complete advertised histories so version tags and pinned
commits remain available. Failed cache operations retry the original Git command
upstream. New refs that appear during a job can also fall back upstream. A failed
refresh does not silently substitute an old package version.

Metadata queries use the original Git configuration, so Nimble sees canonical
upstream remote URLs. Pushes and pulls use upstream Git directly. Nimble's
recursive clone command is split into a clone and submodule update, so a failed
submodule download can retry without deleting its parent checkout. Other
recursive-clone variants use upstream Git directly. Relative submodule URLs and
paths with spaces are supported.

Only bare source repositories are saved. Nimble directories, working checkouts,
compiler output and installed binaries are fresh in every job. The package
registry is still refreshed normally. HTTP APIs, release archives, Mercurial and
non-Git downloads in arbitrary package tasks still use their normal network paths.
This is a source download cache, not an offline package environment.

## Snapshot keys

The `package-sources-v2` namespace uses the standard library's SHA-1 digest of each
upstream URL for mirror filenames. The stored origin URL is still validated before
use. The new namespace avoids restoring the Python helper's SHA-256 filenames.
Only the bare mirrors are cached; the Nim executables and session files are built
fresh and need no Nimble dependencies.

Actions caches cannot be overwritten. Each saved snapshot includes the workflow
run ID and attempt. Restore requests use a different, never-saved `lookup` key and
then these prefix matches, in order:

1. The same OS, architecture, batch and input hash, followed by `-snapshot-`.
2. The same OS, architecture and batch, with any input hash.

Actions selects the most recently created matching cache for a prefix. For example,
after saving `INPUT-snapshot-100-1` and then `INPUT-snapshot-101-1`, a request for
`INPUT-lookup-102-1` restores snapshot 101. It cannot hit snapshot 100 as an exact
key. Thus a scheduled/manual refresh is visible to subsequent jobs even when the
input files have not changed. The input hash includes the package list, batching,
package-test driver, `koch.nim` (including the Nimble pin), helper and workflow.

## Local checks

```
nim c -d:release --out:bin/package_source_cache ci/package_source_cache.nim
nim c -r --out:bin/test_package_source_cache ci/test_package_source_cache.nim bin/package_source_cache
actionlint .github/workflows/ci_packages.yml
```

The Git fixtures use local repositories and enable `file://` only for the tests.
They exercise shallow clones/fetches, tags, changed heads/default branches, refs
created after first access, cache misses, invalid mirrors, upstream failures,
relative submodules, canonical URLs and concurrent clones.
