# Atlas Package Cloner

Atlas is a simple package cloner tool. It manages an isolated workspace that
contains projects and dependencies.

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

```
  $workspace / main project
  $workspace / other project
  $workspace / _deps / dependency A
  $workspace / _deps / dependency B
```

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


### Use <url> / <package name>

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


### Clone/Update <url>/<package name>

Clones a URL and all of its dependencies (recursively) into the workspace.
Creates or patches a `nim.cfg` file with the required `--path` entries.

**Note**: Due to the used algorithms an `update` is the same as a `clone`.


If a `<package name>` is given instead the name is first translated into an URL
via `packages.json` or via a github search.


### Search <term term2 term3 ...>

Search the package index `packages.json` for a package that the given terms
in its description (or name or list of tags).


### Install <proj.nimble>

Use the .nimble file to setup the project's dependencies.

### UpdateProjects / updateDeps [filter]

Update every project / dependency in the workspace that has a remote URL that
matches `filter` if a filter is given. The project / dependency is only updated
if there are no uncommitted changes.

### Others

Run `atlas --help` for more features.


## Overrides

You can override how Atlas resolves a package name or a URL. The overrides use
a simple pattern matching language and are flexible enough to integrate private
gitlab repositories.

To setup an override file, edit the `$workspace/atlas.workspace` file to contain
a line like `overrides="urls.rules"`. Then create a file `urls.rules` that can
contain lines like:

```
customProject -> https://gitlab.company.com/customProject
https://github.com/araq/ormin -> https://github.com/useMyForkInstead/ormin
```

The `$` has a special meaning in a pattern:

=================   ========================================================
``$$``              Matches a single dollar sign.
``$*``              Matches until the token following the ``$*`` was found.
                    The match is allowed to be of 0 length.
``$+``              Matches until the token following the ``$+`` was found.
                    The match must consist of at least one char.
``$s``              Skips optional whitespace.
=================   ========================================================

For example, here is how to override any github link:

```
https://github.com/$+ -> https://utopia.forall/$#
```

You can use `$1` or `$#` to refer to captures.


## Virtual Nim environments

Atlas supports setting up a virtual Nim environment via the `env` command. You can
even install multiple different Nim versions into the same workspace.

For example:

```
atlas env 1.6.12
atlas env devel
```

When completed, run `source nim-1.6.12/activate.sh` on UNIX and `nim-1.6.12/activate.bat` on Windows.


## Dependency resolution

To change the used dependency resolution mechanism, edit the `resolver` value of
your `atlas.workspace` file. The possible values are:

### MaxVer

The default resolution mechanism is called "MaxVer" where the highest available version is selected
that still fits the requirements.

Suppose you have a dependency called "mylibrary" with the following available versions:
1.0.0, 1.1.0, and 2.0.0. `MaxVer` selects the version 2.0.0.



### SemVer

Adhere to Semantic Versioning (SemVer) by selecting the highest version that satisfies the specified
version range. SemVer follows the format of `MAJOR.MINOR.PATCH`, where:

MAJOR version indicates incompatible changes.

MINOR version indicates backward-compatible new features.

PATCH version indicates backward-compatible bug fixes.

Consider the same "mylibrary" dependency with versions 1.0.0, 1.1.0, and 2.0.0. If you set the
resolver to `SemVer` and specify a version range requirement of `>= 1.0.0`, the highest version
that satisfies the range that does not introduce incompatible changes will be selected. In this
case, the selected version would be 1.1.0.


### MinVer

For the "mylibrary" dependency with versions 1.0.0, 1.1.0, and 2.0.0, if you set the resolver
to `MinVer` and specify multiple minimum versions, the highest version among the minimum
required versions will be selected. For example, if you specify a minimum requirement of
both `>=1.0.0` and `>=2.0.0`, the selected version would be 2.0.0.


## Reproducible builds / lockfiles

Atlas supports lockfiles for reproducible builds via its `pin` and `rep` commands.

**Notice**: Atlas helps with reproducible builds, but it is not a complete solution.
For a truely reproducible build you also need to pin the used C++ compiler, any
third party dependencies ("libc" etc.) and the version of your operating system.


### pin [atlas.lock]

`atlas pin` can be run either in the workspace or in a specific project. It "pins" the used
repositories to their current commit hashes.
If run in the workspace the entire workspace is "pinned" in the `atlas.lock` file.
If run in a project the project's dependencies but not the project itself is "pinned" in the
lock file.

### rep [atlas.lock]

The `rep` command replays or repeats the projects to use the pinned commit hashes. If the
projects have any "build" instructions these are performed too unless the `--noexec` switch
is used.


## Plugins

Atlas operates on a graph of dependencies. A dependency is a git project of a specific commit.
The graph and version selection algorithms are mostly programming language agnostic. Thus it is
easy to integrate foreign projects as dependencies into your project.

This is accomplished by Atlas plugins. A plugin is a NimScript snippet that can call into
external tools via `exec`.

To enable plugins, add the line `plugins="_plugins"` to your `atlas.workspace` file. Then create
a directory `_plugins` in your workspace. Every `*.nims` file inside the plugins directory is
integrated into Atlas.


### Builders

A builder is a build tool like `make` or `cmake`. What tool to use is determined by the existence
of certain files in the project's top level directory. For example, a file `CMakeLists.txt`
indicates a `cmake` based build:

```nim

builder "CMakeLists.txt":
  mkDir "build"
  withDir "build":
    exec "cmake .."
    exec "cmake --build . --config Release"

```

Save this as `_plugins/cmake.nims`. Then every dependency that contains a `CMakeLists.txt` file
will be build with `cmake`.

**Note**: To disable any kind of action that might run arbitrary code, use the `--noexec` switch.
