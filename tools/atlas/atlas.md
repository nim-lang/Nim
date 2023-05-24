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
version. Thanks to this design, lock files are much less important.


## Dependencies

Dependencies are neither installed globally, nor locally into the current
project. Instead a "workspace" is used. The workspace is the nearest parent
directory of the current directory that does not contain a `.git` subdirectory.
Dependencies are managed as **siblings**, not as children. Dependencies are
kept as git repositories.

Thanks to this setup, it's easy to develop multiple projects at the same time.

A project plus its dependencies are stored in a workspace:

  $workspace / main project
  $workspace / _deps / dependency A
  $workspace / _deps / dependency B

The deps directory can be set via `--deps:DIR` explicitly. It defaults to `_deps`.
If you want it to be the same as the workspace use `--deps:.`.

You can move a dependency out of the `_deps` subdirectory into the workspace.
This can be convenient should you decide to work on a dependency too. You need to
patch the `nim.cfg` then.


## Commands

Atlas supports the following commands:


## Use <url> / <package name>

Clone the package behind `url` or `package name` and its dependencies into
the `_deps` directory and make it available for your current project which
should be in the current working directory. Atlas will create or patch
the files `$project.nimble` and `nim.cfg` for you so that you can simply
import the required modules.

For example:

```
  mkdir newproject
  cd newproject
  git init
  atlas use lexim
  # add `import lexim` to your example.nim file
  nim c example.nim

```


### Clone/Update <url>

Clones a URL and all of its dependencies (recursively) into the workspace.
Creates or patches a `nim.cfg` file with the required `--path` entries.

**Note**: Due to the used algorithms an `update` is the same as a `clone`.


### Clone/Update <package name>

The `<package name>` is translated into an URL via `packages.json` and
then `clone <url>` is performed.

**Note**: Due to the used algorithms an `update` is the same as a `clone`.


### Search <term term2 term3 ...>

Search the package index `packages.json` for a package that the given terms
in its description (or name or list of tags).


### Install <proj.nimble>

Use the .nimble file to setup the project's dependencies.

### UpdateWorkspace [filter]

Update every package in the workspace that has a remote URL that
matches `filter` if a filter is given. The package is only updated
if there are no uncommitted changes.

### Others

Run `atlas --help` for more features.
