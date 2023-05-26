# Atlas Package Cloner

Atlas is a simple package cloner tool that automates some of the
workflows and needs for Nim's stdlib evolution.

Atlas is compatible with Nimble in the sense that it supports the Nimble
file format.


## Concepts

Atlas uses three concepts:

1. Workspaces
2. Projects
3. Dependencies

### Workspaces

Every workspace is isolated, nothing is shared between workspaces.
A workspace is a directory that has a file `atlas.workspace` inside it. Use `atlas init`
to create a workspace out of the current working directory.

Projects plus their dependencies are stored in a workspace:

  $workspace / main project
  $workspace / other project
  $workspace / _deps / dependency A
  $workspace / _deps / dependency B

The deps directory can be set via `--deps:DIR` during `atlas init`.


### Projects

A workspace contains one or multiple "projects". These projects can use each other and it
is easy to develop multiple projects at the same time.

### Dependencies

Inside a workspace there can be a `_deps` directory where your dependencies are kept. It is
easy to move a dependency one level up and out the `_deps` directory, turning it into a project.
Likewise, you can move a project to the `_deps` directory, turning it into a dependency.

The only distinction between a project and a dependency is its location. For dependency resolution
a project always has a higher priority than a dependency.


## No magic

Atlas works by managing two files for you, the `project.nimble` file and the `nim.cfg` file. You can
edit these manually too, Atlas doesn't touch what should be left untouched.


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
