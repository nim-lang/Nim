# Atlas Package Cloner

Atlas is a simple package cloner tool that automates some of the
workflows and needs for Nim's stdlib evolution.

Atlas is compatible with Nimble in the sense that it supports the Nimble
file format.


## How it works

Atlas uses git commits internally; version requirements are translated
to git commits via `git show-ref --tags`.

Atlas uses URLs internally; Nimble package names are translated to URLs
via Nimble's  `packages.json` file.

Atlas does not call the Nim compiler for a build, instead it creates/patches
a `nim.cfg` file for the compiler. For example:

```
############# begin Atlas config section ##########
--noNimblePath
--path:"../nimx"
--path:"../sdl2/src"
--path:"../opengl/src"
############# end Atlas config section   ##########
```

The version selection is deterministic, it picks up the *minimum* required
version. Thanks to this design, lock files are not required.


## Dependencies

Dependencies are neither installed globally, nor locally into the current
project. Instead a "workspace" is used. The workspace is the nearest parent
directory of the current directory that does not contain a `.git` subdirectory.
Dependencies are managed as **siblings**, not as children. Dependencies are
kept as git repositories.

Thanks to this setup, it's easy to develop multiple projects at the same time.

A project plus its dependencies are stored in a workspace:

  $workspace / main project
  $workspace / dependency A
  $workspace / dependency B


No attempts are being made at keeping directory hygiene inside the
workspace, you're supposed to create appropriate `$workspace` directories
at your own leisure.


## Commands

Atlas supports the following commands:


### Clone <url>

Clones a URL and all of its dependencies (recursively) into the workspace.
Creates or patches a `nim.cfg` file with the required `--path` entries.


### Clone <package name>

The `<package name>` is translated into an URL via `packages.json` and
then `clone <url>` is performed.


### Search <term term2 term3 ...>

Search the package index `packages.json` for a package that the given terms
in its description (or name or list of tags).

