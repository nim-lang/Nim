# Nimble

Nimble is the default *package manager* for the [Nim programming
language](https://nim-lang.org).

Interested in learning **how to create a package**? Skip directly to that section
[here](#creating-packages).

This documentation is for the latest commit of Nimble. Nim releases ship with a
specific version of Nimble and may not contain all the features and fixes described
here. `nimble -v` will display the version of Nimble in use and corresponding
documentation can be found [here](https://github.com/nim-lang/nimble/releases).

The Nimble change log can be found [here](https://github.com/nim-lang/nimble/blob/master/changelog.markdown).

## Contents

- [Requirements](#requirements)
- [Installation](#installation)
- [Nimble usage](#nimble-usage)
  - [nimble refresh](#nimble-refresh)
  - [nimble install](#nimble-install)
  - [nimble develop](#nimble-develop)
  - [nimble lock](#nimble-lock)
  - [nimble sync](#nimble-sync)
  - [nimble setup](#nimble-setup)
  - [nimble uninstall](#nimble-uninstall)
  - [nimble build](#nimble-build)
  - [nimble run](#nimble-run)
  - [nimble c](#nimble-c)
  - [nimble list](#nimble-list)
  - [nimble search](#nimble-search)
  - [nimble path](#nimble-path)
  - [nimble init](#nimble-init)
  - [nimble publish](#nimble-publish)
  - [nimble tasks](#nimble-tasks)
  - [nimble dump](#nimble-dump)
- [Configuration](#configuration)
- [Creating Packages](#creating-packages)
  - [Project structure](#project-structure)
    - [Tests](#tests)
  - [Libraries](#libraries)
  - [Binary packages](#binary-packages)
  - [Hybrids](#hybrids)
  - [Dependencies](#dependencies)
    - [External dependencies](#external-dependencies)
  - [Nim compiler](#nim-compiler)
  - [Versions](#versions)
    - [Releasing a new version](#releasing-a-new-version)
- [Publishing packages](#publishing-packages)
- [.nimble reference](#nimble-reference)
  - [[Package]](#package)
    - [Required](#required)
    - [Optional](#optional)
  - [[Deps]/[Dependencies]](#depsdependencies)
    - [Optional](#optional)
- [Troubleshooting](#troubleshooting)
- [Nimble's folder structure and packages](#nimbles-folder-structure-and-packages)
- [Repository information](#repository-information)
- [Contribution](#contribution)
- [About](#about)

## Requirements

Nimble has some runtime dependencies on external tools, these tools are used to
download Nimble packages. For instance, if a package is hosted on
[GitHub](https://github.com), you need to have [git](https://www.git-scm.com)
installed and added to your environment ``PATH``. The same goes for
[Mercurial](http://mercurial.selenic.com) repositories on
[Bitbucket](https://bitbucket.org). Nimble packages are typically hosted in Git
repositories so you may be able to get away without installing Mercurial.

**Warning:** Ensure that you have a fairly recent version of **Git** installed.
Current minimal supported version is **Git** `2.22` from `2019-06-07`.
Cloning of a specific **Git** commit described in the lock file uses a method
described [here](https://stackoverflow.com/a/3489576/853791) and requiring an
option enabled on server side with the configuration variable
`uploadpack.allowReachableSHA1InWant`. Currently the
feature is supported by both **GitHub** and **BitBucket**.

## Installation

Nimble is now bundled with [Nim](https://nim-lang.org)
(as of Nim version 0.15.0).
This means that you should have Nimble installed already, as long as you have
the latest version of Nim installed as well. Because of this **you likely do
not need to install Nimble manually**.

But in case you still want to install Nimble manually, you can follow the
following instructions.

There are two ways to install Nimble manually. Using ``koch`` and using Nimble
itself.

### Using koch

The ``koch`` tool is included in the Nim distribution and
[repository](https://github.com/nim-lang/Nim/blob/devel/koch.nim).
Simply navigate to the location of your Nim installation and execute the
following command to compile and install Nimble.

```
./koch nimble
```

This will clone the Nimble repository, compile Nimble and copy it into
Nim's bin directory.

### Using Nimble

In most cases you will already have Nimble installed, you can install a newer
version of Nimble by simply running the following command:

```
nimble install nimble
```

This will download the latest release of Nimble and install it on your system.

Note that you must have `~/.nimble/bin` in your PATH for this to work, if you're
using choosenim then you likely already have this set up correctly.

## Nimble usage

Once you have Nimble installed on your system you can run the ``nimble`` command
to obtain a list of available commands.

### nimble refresh

The ``refresh`` command is used to fetch and update the list of Nimble packages
(see below). There is no automatic update mechanism, so you need to run this
yourself if you need to *refresh* your local list of known available Nimble
packages. Example:

    $ nimble refresh
    Downloading package list from https://.../packages.json
    Done.

Some commands may remind you to run ``nimble refresh`` or will run it for you if
they fail.

You can also optionally supply this command with a URL if you would like to use
a third-party package list.

Package lists can be specified in Nimble's config. Take a look at the
config section below to see how to do this.

### nimble check

The ``check`` command will read your package's .nimble file. It will then
verify that the package's structure is valid.

Example:

    $ nimble check
        Error: Package 'x' has an incorrect structure. It should contain a single directory hierarchy for source files, named 'x', but file 'foobar.nim' is in a directory named 'incorrect' instead. This will be an error in the future.
         Hint: If 'incorrect' contains source files for building 'x', rename it to 'x'. Otherwise, prevent its installation by adding `skipDirs = @["incorrect"]` to the .nimble file.
      Failure: Validation failed

On `check` command the development mode dependencies are also validated against
the lock file. The following reasons for validation failure are possible:

* The package directory is not under version control.
* The package working copy directory is not in clean state.
* Current VCS revision is not pushed on any remote.
* The working copy needs sync.
* The working copy needs lock.
* The working copy needs merge or re-base.

### nimble install

The ``install`` command will download and install a package. You need to pass
the name of the package (or packages) you want to install. If any of the
packages depend on other Nimble packages Nimble will also install them.
Example:

    $ nimble install nake
    Downloading nake into /tmp/nimble/nake...
    Executing git...
    ...
    nake installed successfully

Nimble always fetches and installs the latest version of a package. Note that
the latest version is defined as the latest tagged version in the Git (or Mercurial)
repository, if the package has no tagged versions then the latest commit in the
remote repository will be installed. If you already have that version installed,
Nimble will ask you whether you wish to overwrite your local copy.

You can force Nimble to download the latest commit from the package's repo, for
example:

    $ nimble install nimgame@#head

This is of course Git-specific, for Mercurial, use ``tip`` instead of ``head``. A
branch, tag, or commit hash may also be specified in the place of ``head``.

Instead of specifying a VCS branch, you may also specify a concrete version or a
version range, for example:

    $ nimble install nimgame@0.5
    $ nimble install nimgame@"> 0.5"

The latter command will install a version that is greater than ``0.5``.

Nim flags provided to `nimble install` will be forwarded to the compiler when
building any binaries. Such compiler flags can be made persistent by using Nim
[configuration](https://nim-lang.org/docs/nimc.html#compiler-usage-configuration-files)
files.

#### Local Package Development

The ``install`` command can also be used for locally testing or developing a
Nimble package by leaving out the package name parameter. Your current working
directory must be a Nimble package and contain a valid ``package.nimble`` file.

Nimble will install the package residing in the current working directory when you
don't specify a package name and the directory contains a ``package.nimble`` file.
This can be useful for developers who are locally testing their ``.nimble`` files
before submitting them to the official package list.
See the [Creating Packages](#creating-packages) section for more info on this.

Dependencies required for developing or testing a project can be installed by
passing `--depsOnly` without specifying a package name. Nimble will then install
any missing dependencies listed in the package's ``package.nimble`` file in the
current working directoy. Note that dependencies will be installed globally.

For example to install the dependencies for a Nimble project ``myPackage``:

    $ cd myPackage/ && nimble install --depsOnly

#### Package URLs

A valid URL to a Git or Mercurial repository can also be specified, Nimble will
automatically detect the type of the repository that the url points to and
install it.

For repositories containing the Nimble package in a subdirectory, you can
instruct Nimble about the location of your package using the ``?subdir=<path>``
query parameter. For example:

    $ nimble install https://github.com/nimble-test/multi?subdir=alpha

### nimble develop

The develop command is used for putting packages in a development mode. When
executed with a list of packages it clones their repository. If it is executed
in a package directory it adds cloned packages to the special `nimble.develop`
file. This is a special file which is used for holding the paths to development
mode dependencies of the current directory package. It has the following
structure:

```json
{
    "version": 1,
    "includes": [],
    "dependencies": []
}
```

* `version` - JSON schema version
* `includes` - JSON array of paths to included files.
* `dependencies` - JSON array of paths to Nimble packages directories.

The format for included develop files is the same as the project's develop
file.

Develop files validation rules:

* The included develop files must be valid.
* The packages listed in the `dependencies` section and in the included develop
files are required to be valid **Nimble** packages, but they are not required
to be valid dependencies of the current project. In the latter case, they are
simply ignored.
* The develop files of the develop mode dependencies of a package are being
followed and processed recursively. Finally, only one common set of develop
mode dependencies is created.
* In the final set of develop mode dependencies, it is not allowed to have more
than one package with the same name but with different file system paths.

Just as with the ``install`` command, a package URL may also be specified
instead of a name.

If present, the validity of the package's develop file is added to the
requirements for validity of the package which is determined by `nimble check`
command.

The `develop` command has a list of options:

* `-p, --path path` - Specifies the path whether the packages should be cloned.
* `-c, --create [path]` - Creates an empty develop file with the name
`nimble.develop` in the current directory or, if a path is present, to the given
directory with a given name.
* `-a, --add path` - Adds the package at the given path to the `nimble.develop`
file.
* `-r, --removePath path` - Removes the package at the given path from the
`nimble.develop` file.
* `-n, --removeName path` - Removed the package with the given name from the
`nimble.develop` file.
* `-i, --include file` - Includes a develop file into the current directory's
one.
* `-e, --exclude file` - Excludes a develop file from the current directory's
one.
* `--withDependencies` - Clones for develop also the dependencies of the
packages for which the develop command is executed.
* `--developFile` - Changes the name of the develop file which to be
manipulated. It is useful for creating a free develop file which is not
associated with any project intended for inclusion in some other develop file.
* `-g, --global` - Creates an old style link file in the special `links`
directory. It is read by Nim to be able to use global develop mode packages.
Nimble uses it as a global develop file if a local one does not exist.

The options for manipulation of the develop files could be given only when
executing `develop` command from some package's directory unless
`--developFile` option with a name of develop file is explicitly given.

Because the develop files are user-specific and they contain local file system
paths they **MUST NOT** be committed.

### nimble lock

The `nimble lock` command will generate or update a package lock file named
`nimble.lock`. This file is used for pinning the exact versions of the
dependencies of the package. The file is intended to be committed and used by
other developers to ensure that exactly the same version of the dependencies is
used by all developers.

Currently the lock file have the structure as in the following example:

```json
{
  "version": 1,
  "packages": {
     ...
     "chronos": {
      "version": "3.0.2",
      "vcsRevision": "aab1e30a726bb47c5d3f4a75a826981836cde9e2",
      "url": "https://github.com/status-im/nim-chronos",
      "downloadMethod": "git",
      "dependencies": [
        "stew",
        "bearssl",
        "httputils",
        "unittest2"
      ],
      "checksums": {
        "sha1": "a1cdaa77995f2d1381e8f9dc129594f2fa2ee07f"
      }
    },
    ...
  }
}
```

* `version` - JSON schema version.
* `packages` - JSON object containing JSON objects for all dependencies,
* `chronos` - Nested JSON object keys are the names of the dependencies
packages.
* `version` - The version of the dependency.
* `vcsRevision` - The revision at which the dependency is locked.
* `url` - The URL of the repository of the package.
* `downloadMethod` - `git` or `hg` according to the type of the repository at
`url`.
* `dependencies` - The direct dependencies of the package. Used for writing the
reverse dependencies of the package in the `nimbledata.json` file. Those
packages' names also must be in the lock file.
* `checksums` - A JSON compound object containing different checksums used for
verifying that a downloaded package is exactly the same as the pinned in the
lock file package. Currently, only `sha1` checksums are supported
* `sha1` - The *sha1* checksum of the package files.

If a lock file `nimble.lock` exists, then on performing all Nimble commands
which require searching for dependencies and downloading them in the case they
are missing (like `build`, `install`, `develop`), it is read and its content is
used to download the same version of the project dependencies by using the URL,
download method and VCS revision written in it. The checksum of the downloaded
package is compared against the one written in the lock file. In the case the
two checksums are not equal then it will be printed error message and the
operation will be aborted. Reverse dependencies are added for installed locked
dependencies just like for any other package being locally installed.

### nimble sync

The `nimble sync` command will synchronize develop mode dependencies with the
content of the lock file. If the revision specified in the lock file is not
found locally, it tries to fetch it from the configured remotes. If it is present
on multiple branches, it tries to stay on the current one, and if can't, it prefers
local branches rather than remote-tracking ones. If found on more than one
branch, it gives the user a choice whether to switch.

Sync operation will also download non-develop mode dependencies versions
described in the lock file if they are not already present in the Nimble cache.

If the `-l, --listOnly` option is given then the command only lists
development mode dependencies whose working copies are out of sync, without
actually syncing them and without downloading missing non-develop mode
dependencies.

**Important implementation details:**

To be able to determine whether a working copy of development mode dependency
needs to be synced, locked again, or merged with or re-based on some other
branch a special sync file is kept in the VCS directory (.git or .hg) of the
current package. It keeps a record for every development mode dependency for
its current working copy revision during the last `lock`, `sync`, or `develop`
operation. The name of the file is `<package_name>.nimble.sync`.

### nimble setup

The `nimble setup` command creates a `nimble.paths` file containing file system
paths to the dependencies. It also includes the paths file in the `config.nims`
file (by creating it if it does not already exist) to make them available for
the compiler. `nimble.paths` file is user-specific and MUST NOT be committed.

The command also adds `nimble.develop` and `nimble.paths` files to the
`.gitignore` file.

### nimble uninstall

The ``uninstall`` command will remove an installed package. Attempting to remove
a package that other packages depend on will result in an error. You can use the
``--inclDeps`` or ``-i`` flag to remove all dependent packages along with the package.

Similar to the ``install`` command you can specify a version range, for example:

    $ nimble uninstall nimgame@0.5

### nimble build

The ``build`` command is mostly used by developers who want to test building
their ``.nimble`` package. This command will build the package with default
flags, i.e. a debug build which includes stack traces but no GDB debug
information. The ``install`` command will build the package in release mode
instead.

Nim flags provided to `nimble build` will be forwarded to the compiler. Such
compiler flags can be made persistent by using Nim
[configuration](https://nim-lang.org/docs/nimc.html#compiler-usage-configuration-files)
files.

### nimble run

The `run` command can be used to build and run any binary specified in your
package's `bin` list. The binary needs to be specified after any compilation flags
if there are several binaries defined. Any flags after the binary or `--`
are passed to the binary when it is run. It is possible to run a binary from some
dependency package. To do this pass the `--package, -p` option to Nimble. For example:

```
nimble --package:foo run <compilation_flags> bar <run_flags>
```

### nimble c

The ``c`` (or ``compile``, ``js``, ``cc``, ``cpp``) command can be used by
developers to compile individual modules inside their package. All options
passed to Nimble will also be passed to the Nim compiler during compilation.

Nimble will use the backend specified in the package's ``.nimble`` file if
the command ``c`` or ``compile`` is specified. The more specific ``js``, ``cc``,
``cpp`` can be used to override that.

### nimble list

The ``list`` command will display the known list of packages available for
Nimble. An optional ``--ver`` parameter can be specified to tell Nimble to
query remote Git repositories for the list of versions of the packages and to
then print the versions. Please note however that this can be slow as each
package must be queried separately.

### nimble search

If you don't want to go through the whole output of the ``list`` command you
can use the ``search`` command specifying as parameters the package name and/or
tags you want to filter. Nimble will look into the known list of available
packages and display only those that match the specified keywords (which can be
substrings). Example:

    $ nimble search math
    linagl:
      url:         https://bitbucket.org/BitPuffin/linagl (hg)
      tags:        library, opengl, math, game
      description: OpenGL math library
      license:     CC0

    extmath:
      url:         git://github.com/achesak/extmath.nim (git)
      tags:        library, math, trigonometry
      description: Nim math library
      license:     MIT

Searches are case insensitive.

An optional ``--ver`` parameter can be specified to tell Nimble to
query remote Git repositories for the list of versions of the packages and
then print the versions. However, please note that this can be slow as each
package must be queried separately.

### nimble path

The nimble ``path`` command will show the absolute path to the installed
packages matching the specified parameters. Since there can be many versions of
the same package installed, the ``path`` command will list all of them.

### nimble init

The nimble ``init`` command will start a simple wizard which will create
a quick ``.nimble`` file for your project in the current directory.

As of version 0.7.0, the ``.nimble`` file that this command creates will
use the new NimScript format.
Check out the [Creating Packages](#creating-packages) section for more info.

### nimble publish

Publishes your Nimble package to the official Nimble package repository.

**Note:** Requires a valid GitHub account with an SSH key attached to it. To upload your public key onto your GitHub account, follow [this link](https://github.com/settings/keys).

The token is stored in `$nimbleDir/github_api_token` which can be replaced if you need to update/replace your token.

### nimble tasks

For a Nimble package in the current working directory, list the tasks which that
package defines. This is only supported for packages utilising the new
nimscript .nimble files.

### nimble dump

Outputs information about the package in the current working directory in
an ini-compatible format. Useful for tools wishing to read metadata about
Nimble packages who do not want to use the NimScript evaluator.

The format can be specified with `--json` or `--ini` (and defaults to `--ini`).
Use `nimble dump pkg` to dump information about provided `pkg` instead.

## Configuration

At startup Nimble will attempt to read ``~/.config/nimble/nimble.ini`` on Linux
(on Windows it will attempt to read
``C:\Users\<YourUser>\AppData\Roaming\nimble\nimble.ini``).

The format of this file corresponds to the ini format with some Nim
enhancements. For example:

```ini
nimbleDir = r"C:\Nimble\"

[PackageList]
name = "CustomPackages"
url = "http://mydomain.org/packages.json"

[PackageList]
name = "Local project packages"
path = r"C:\Projects\Nim\packages.json"
```

You can currently configure the following in this file:

* ``nimbleDir`` - The directory which Nimble uses for package installation.
  **Default:** ``~/.nimble/``
* ``chcp`` - Whether to change the current code page when executing Nim
  application packages. If ``true`` this will add ``chcp 65001`` to the
  .cmd stubs generated in ``~/.nimble/bin/``.
  **Default:** ``true``
* ``[PackageList]`` + ``name`` + (``url``|``path``) - You can use this section to specify
  a new custom package list. Multiple package lists can be specified. Nimble
  defaults to the "Official" package list, you can override it by specifying
  a ``[PackageList]`` section named "official". Multiple URLs can be specified
  under each section, Nimble will try each in succession if
  downloading from the first fails. Alternatively, ``path`` can specify a
  local file path to copy a package list .json file from.
* ``cloneUsingHttps`` - Whether to replace any ``git://`` inside URLs with
  ``https://``.
  **Default: true**
* ``httpProxy`` - The URL of the proxy to use when downloading package listings.
  Nimble will also attempt to read the ``http_proxy`` and ``https_proxy``
  environment variables.
  **Default: ""**

## Creating Packages

Nimble works on Git repositories as its primary source of packages. Its list of
packages is stored in a JSON file which is freely accessible in the
[nim-lang/packages repository](https://github.com/nim-lang/packages).
This JSON file provides Nimble with the required Git URL to clone the package
and install it. Installation and build instructions are contained inside a
file with the ``.nimble`` file extension. The Nimble file shares the
package's name, i.e. a package
named "foobar" should have a corresponding ``foobar.nimble`` file.

These files specify information about the package including its author,
license, dependencies and more. Without one, Nimble is not able to install
a package.

A .nimble file can be created easily using Nimble's ``init`` command. This
command will ask you a bunch of questions about your package, then generate a
.nimble file for you in the current directory.

A bare minimum .nimble file follows:

```ini
# Package

version     = "0.1.0"
author      = "Your Name"
description = "Example .nimble file."
license     = "MIT"

# Deps

requires "nim >= 0.10.0"
```

You may omit the dependencies entirely, but specifying the lowest version
of the Nim compiler required is recommended.

You can also specify multiple dependencies like so:

```
# Deps

requires "nim >= 0.10.0", "foobar >= 0.1.0"
requires "fizzbuzz >= 1.0"
requires "https://github.com/user/pkg#5a54b5e"
```

There are also following version selector operators available for "requires":
 `<`,`>`, `>=`, `<=`, `==`, `^=` and `~=`.

The operator specification of `^=` is similar to `^` in
[npm](https://github.com/npm/node-semver#caret-ranges-123-025-004), while the
`~=` operator is similar to `~=` in
[python](https://www.python.org/dev/peps/pep-0440/#compatible-release):
- `^=` is selecting the latest compatible version according to
       [semver](https://semver.npmjs.com/). Major release number changes
       cause incompatibility.
- `~=` is selecting the latest version by increasing the last given digit
       to the highest version.

Both operators `^=` and `~=` were not available yet for Nimble 0.13.1 and
earlier and would cause error messages if used there.
Other more complex comparison operators that would be available in npm like
`!=`, `||`, `-`, `*` and `X` are also not available in Nimble.
```
# Examples for selector ^= and ~=

requires "nim ^= 1.2.2" # nim >= 1.2.2 & < 2.0.0
requires "nim ~= 1.2.2" # nim >= 1.2.2 & < 1.3.0
requires "jester ^= 0.4.1" # jester >= 0.4.1 & < 0.5.0
requires "jester ~= 0.4.1" # jester >= 0.4.1 & < 0.5.0
requires "jester ~= 0.4" # jester >= 0.4.0 & < 1.0.0
requires "choosenim ~= 0" # choosenim >= 0.0.0 & < 1.0.0
requires "choosenim ^= 0" # choosenim >= 0.0.0 & < 1.0.0
```

Nimble currently supports the installation of packages from a local directory, a
Git repository and a mercurial repository. The .nimble file must be present in
the root of the directory or repository being installed.

The .nimble file is very flexible because it is interpreted using NimScript.
Because of Nim's flexibility, the definitions remain declarative. With the added
ability to use the Nim language to enrich your package specification.
For example, you can define dependencies for specific platforms using Nim's
``when`` statement.

Another great feature
is the ability to define custom Nimble package-specific commands. These are
defined in the .nimble files of course.

```nim
task hello, "This is a hello task":
  echo("Hello World!")
```

You can then execute ``nimble hello``, which will result in the following
output:

```
Executing task hello in /Users/user/projects/pkg/pkg.nimble
Hello World!
```

Dependencies that are only needed for a certain task can be declared with `taskRequires` like so

```nim
taskRequires "hello", "choosenim == 0.4.0"
```


You can place any Nim code inside these tasks. As long as that code does not
access the FFI. The ``nimscript``
[module](https://nim-lang.org/docs/nimscript.html) in Nim's standard library defines
additional functionality such as the ability to execute external processes
which makes this feature very powerful.

You can also check what tasks are supported by the package in the current
directory by using the ``tasks`` command.

Nimble provides an API that adds even more functionality. For example,
you can specify
pre and post hooks for any Nimble command (including commands that
you define yourself). To do this you can add something like the following:

```nim
before hello:
  echo("About to call hello!")
```

That will result in the following output when ``nimble hello`` is executed (you
must also specify the ``task`` shown above).

```
Executing task hello in /Users/user/projects/pkg/pkg.nimble
About to call hello!
Hello World!
```

Similar to this an ``after`` block is also available for post hooks,
which are executed after Nimble finished executing a command. You can
also return ``false`` from these blocks to stop further execution.

The ``nimscriptapi.nim`` module specifies this and includes other definitions
which are also useful. Take a look at it for more information.

Tasks support two kinds of flags: `nimble <compflags> task <runflags>`. Compile
flags are those specified before the task name and are forwarded to the Nim
compiler that runs the `.nimble` task. This enables setting `--define:xxx`
values that can be checked with `when defined(xxx)` in the task, and other
compiler flags that are applicable in Nimscript mode. Run flags are those after
the task name and are available as command-line arguments to the task. They can
be accessed per usual from `commandLineParams: seq[string]`.

In order to forward compiler flags to `exec("nim ...")` calls executed within a
custom task, the user needs to specify these flags as run flags which will then
need to be manually accessed and forwarded in the task.

### Project structure

For a package named "foobar", the recommended project structure is the following:

```
.                   # The root directory of the project
├── LICENSE
├── README.md
├── foobar.nimble   # The project .nimble file
└── src
    └── foobar.nim  # Imported via `import foobar`
└── tests           # Contains the tests
    ├── config.nims
    ├── tfoo1.nim   # First test
    └── tfoo2.nim   # Second test

```

Note that the .nimble file needs to be in the project's root directory. This
directory structure will be created if you run ``nimble init`` inside a
``foobar`` directory.

**Warning:** When source files are placed in a ``src`` directory, the
.nimble file must contain a ``srcDir = "src"`` directive. The ``nimble init``
command takes care of that for you.

When introducing more modules into your package, you should place them in a
separate directory named ``foobar`` (i.e. your package's name). For example:

```
.                   # The root directory of the project
├── ...
├── foobar.nimble   # The project .nimble file
├── src
│   ├── foobar
│   │   ├── utils.nim   # Imported via `import foobar/utils`
│   │   └── common.nim  # Imported via `import foobar/common`
│   └── foobar.nim      # Imported via `import foobar`
└── ...
```

#### Private modules

You may wish to hide certain modules in your package from the users. Create a
``private`` directory for that purpose. For example:

```
.                   # The root directory of the project
├── ...
├── foobar.nimble   # The project .nimble file
├── src
│   ├── foobar
│   │   ├── private
│   │   │   └── hidden.nim  # Imported via `import foobar/private/hidden`
│   │   ├── utils.nim       # Imported via `import foobar/utils`
│   │   └── common.nim      # Imported via `import foobar/common`
│   └── foobar.nim          # Imported via `import foobar`
└── ...
```

#### Tests

A common problem that arises with tests is the fact that they need to import
the associated package. But the package is in the parent directory. This can
be solved in a few different ways:

* Expect that the package has been installed locally into your
  ``~/.nimble`` directory.
* Use a simple path modification to resolve the package properly.

The latter is highly recommended. Reinstalling the package to test an actively
changing codebase is a massive pain.

To modify the path for your tests only, simply add a ``nim.cfg`` file into
your ``tests`` directory with the following contents:

```
--path:"../src/"
```

Nimble offers a pre-defined ``test`` task that compiles and runs all files
in the ``tests`` directory beginning with 't' in their filename. Nim flags
provided to `nimble test` will be forwarded to the compiler when building
the tests.

You may wish to override this ``test`` task in your ``.nimble`` file. This
is particularly useful when you have a single test suite program. Just add
the following to your ``.nimble`` file to override the default ``test`` task.

```nim
task test, "Runs the test suite":
  exec "nim c -r tests/tester"
```

Running ``nimble test`` will now use the ``test`` task you have defined.

### Libraries

Library packages are likely the most popular form of Nimble packages. They are
meant to be used by other library or binary packages.

When Nimble installs a library, it will copy all of its files
into ``$nimbleDir/pkgs2/pkgname-ver-checksum``. It's up to the package creator
to make sure that the package directory layout is correct, this is so that users
of the package can correctly import the package.

It is suggested that the layout be as follows. The directory layout is
determined by the nature of your package, that is, whether your package exposes
only one module or multiple modules.

If your package exposes only a single module, then that module should be
present in the source directory of your Git repository and should be named
whatever your package's name is. A good example of this is the
[jester](https://github.com/dom96/jester) package which exposes the ``jester``
module. In this case, the jester package is imported with ``import jester``.

If your package exposes multiple modules then the modules should be in a
``PackageName`` directory. This will allow for a certain measure of isolation
from other packages which expose modules with the same names. In this case,
the package's modules will be imported with ``import PackageName/module``.

Here's a simple example multi-module library package called `kool`:

```
.
├── kool
│   ├── useful.nim
│   └── also_useful.nim
└── kool.nimble
```

In regards to modules which you do **not** wish to be exposed. You should place
them in a ``PackageName/private`` directory. Your modules may then import these
private modules with ``import PackageName/private/module``. This directory
structure may be enforced in the future.

All files and folders in the directory where the .nimble file resides will be
copied as-is, you can however skip some directories or files by setting
the ``skipDirs``, ``skipFiles`` or ``skipExt`` options in your .nimble file.
Directories and files can also be specified on a *whitelist* basis, if you
specify either of ``installDirs``, ``installFiles`` or ``installExt`` then
Nimble will **only** install the files specified.

### Binary packages

These are application packages which require building prior to installation.
A package is automatically a binary package as soon as it sets at least one
``bin`` value, like so:

```ini
bin = @["main"]
```

In this case when ``nimble install`` is invoked, Nimble will build the ``main.nim``
file, copy it into ``$nimbleDir/pkgs2/pkgname-ver-checksum/`` and subsequently
create a symlink to the binary in ``$nimbleDir/bin/``. On Windows, a stub .cmd
file is created instead.

The binary can be named differently than the source file with the ``namedBin``
table:

```nim
namedBin["main"] = "mymain"
namedBin = {"main": "mymain", "main2": "other-main"}.toTable()
```

Note that `namedBin` entries override duplicates in `bin`.

Dependencies are automatically installed before building.
It's a good idea to test that the dependencies you specified are correct by
running ``nimble build`` or ``nimble install`` in the directory
of your package.

### Hybrids

Binary packages will not install .nim files so include ``installExt = @["nim"]``
in your .nimble file if you intend for your package to be a hybrid binary/library
combo.

Historically, binaries that shared the name of a ``pkgname`` directory that
contains additional .nim files required workarounds. This is now handled behind
the scenes by appending a ``.out`` extension to the binary and is transparent to
commands like `nimble run` or symlinks which can still refer to the original
binary name.

### Dependencies

Dependencies are specified using the ``requires`` function. For example:

```
# Dependencies
requires "nim >= 0.10.0", "jester > 0.1 & <= 0.5"
```

Dependency lists support version ranges. These versions may either be a concrete
version like ``0.1``, or they may contain any of the less-than (``<``),
greater-than (``>``), less-than-or-equal-to (``<=``) and greater-than-or-equal-to
(``>=``) operators.
Two version ranges may be combined using the ``&`` operator, for example
``> 0.2 & < 1.0``, which will install a package with the version greater than 0.2
and less than 1.0.

Specifying a concrete version as a dependency is not a good idea because your
package may end up depending on two different versions of the same package.
If this happens, Nimble will refuse to install the package.

In addition to versions you may also specify Git/Mercurial tags, branches and commits.
Although these have to be specific; ranges of commits are not supported.
This is done with the ``#`` character,
for example: ``jester#head``. Which will make your package depend on the
latest commit of Jester.

#### External dependencies

**Warning:** This feature is brand new in Nimble v0.8.0. Breaking changes
related to it are more likely to be introduced than for any other Nimble
features.

Starting with Nimble v0.8.0, you can now specify external dependencies. These dependencies are not managed by Nimble and can only be installed via
your system's package manager or downloaded manually via the internet.

As an example, to specify a dependency on openssl you may put this in your
.nimble file:

```nim
when defined(nimdistros):
  import distros
  if detectOs(Ubuntu):
    foreignDep "libssl-dev"
  else:
    foreignDep "openssl"
```

The ``when`` branch is important to support installation using older versions
of Nimble.

The [distros module](https://nim-lang.org/docs/distros.html) in Nim's
standard library contains a list of all the supported Operating Systems and
Linux distributions.

With this inside your .nimble file, Nimble will output the following after
installing your package (on macOS):

```
  Hint: This package requires some external dependencies.
  Hint: To install them you may be able to run:
  Hint:   brew install openssl
```

### Versions

Versions of cloned packages via Git or Mercurial are determined through the
repository's *tags*.

When installing a package that needs to be downloaded, after the download is
complete and if the package is distributed through a VCS, Nimble will check the
cloned repository's tags list. If no tags exist, Nimble will simply install the
HEAD (or tip in Mercurial) of the repository. If tags exist, Nimble will attempt
to look for tags that resemble versions (e.g. v0.1) and will then find the
latest version out of the available tags, once it does so it will install the
package after checking out the latest version.

You can force the installation of the HEAD of the repository by specifying
``#head`` after the package name in your dependency list.

#### Releasing a new version

Version releases are done by creating a tag in your Git or Mercurial
repository.

Whenever you want to release a new version, you should remember to first
increment the version in your ``.nimble`` file and commit your changes. Only
after that is done should you tag the release.

To summarise, the steps for release are:

* Increment the version in your ``.nimble`` file.
* Commit your changes.
* Tag your release, by for example running ``git tag v0.2.0``.
* Push your tags and commits.

Once the new tag is in the remote repository, Nimble will be able to detect
the new version.

##### Git Version Tagging

Use dot-separated numbers to represent the release version in the git
tag label. Nimble will parse these git tag labels to know which
versions of a package are published.

``` text
v0.2.0        # 0.2.0
v1            # 1
v1.2.3-zuzu   # 1.2.3
foo-1.2.3.4   # 1.2.3.4
```

## Publishing packages

Publishing packages isn't a requirement. But doing so allows people to associate
a specific name to a URL pointing to your package. This mapping is stored
in an official packages repository located
[here](https://github.com/nim-lang/packages).

This repository contains a ``packages.json`` file that lists all the published
packages. It contains a set of package names with associated metadata. You
can read more about this metadata in the
[readme for the packages repository](https://github.com/nim-lang/packages#readme).

To publish your package you need to fork that repository and add an entry
into the ``packages.json`` file for your package. Then create a pull request
with your changes. **You only need to do this
once**.

Nimble includes a ``publish`` command which does this for you automatically.

## .nimble reference

### [Package]

#### Required

* ``name`` - The name of the package. *(This is not required in the new NimScript format)*
* ``version`` - The *current* version of this package. This should be incremented
  **before** tagging the current version using ``git tag`` or ``hg tag``.
* ``author`` - The name of the author of this package.
* ``description`` - A string describing the package.
* ``license`` - The name of the license under which this package is licensed.

#### Optional

* ``skipDirs`` - A list of directory names which should be skipped during
  installation, separated by commas.
* ``skipFiles`` - A list of file names which should be skipped during
  installation, separated by commas.
* ``skipExt`` - A list of file extensions which should be skipped during
  installation, the extensions should be specified without a leading ``.`` and
  should be separated by commas.
* ``installDirs`` - A list of directories which should exclusively be installed,
  if this option is specified nothing else will be installed except the dirs
  listed here, the files listed in ``installFiles``, the files which share the
  extensions listed in ``installExt``, the .nimble file and the binary
  (if ``bin`` / ``namedBin`` is specified). Separated by commas.
* ``installFiles`` - A list of files which should be exclusively installed,
  this complements ``installDirs`` and ``installExt``. Only the files listed
  here, directories listed in ``installDirs``, files which share the extension
  listed in ``installExt``, the .nimble file and the binary (if ``bin`` / ``namedBin``
  is specified) will be installed. Separated by commas.
* ``installExt`` - A list of file extensions which should be exclusively
  installed, this complements ``installDirs`` and ``installFiles``.
  Separated by commas.
* ``srcDir`` - Specifies the directory which contains the .nim source files.
  **Default**: The directory in which the .nimble file resides; i.e. root dir of
  the package.
* ``binDir`` - Specifies the directory where ``nimble build`` will output
  binaries.
  **Default**: The directory in which the .nimble file resides; i.e.
  root dir of the package.
* ``bin`` - A list of files which should be built separated by commas with
  no file extension required. This option turns your package into a *binary
  package*, Nimble will build the files specified and install them appropriately.
* ``namedBin`` - A list of name:value files which should be built with specified
  name, no file extension required. This option turns your package into a *binary
  package*, Nimble will build the files specified and install them approriately.
  `namedBin` entries override duplicates in `bin`.
* ``backend`` - Specifies the backend which will be used to build the files
  listed in ``bin``. Possible values include: ``c``, ``cc``, ``cpp``, ``objc``,
  ``js``.
  **Default**: c

### [Deps]/[Dependencies]

#### Optional

* ``requires`` - Specified a list of package names with an optional version
  range separated by commas.
  **Example**: ``nim >= 0.10.0, jester``; with this value your package will
  depend on ``nim`` version 0.10.0 or greater and on any version of ``jester``.

## Nimble's folder structure and packages

Nimble stores all installed packages and metadata in ``$HOME/.nimble`` by default.
Libraries are stored in ``$nimbleDir/pkgs2``, and compiled binaries are linked in
``$nimbleDir/bin``. The Nim compiler is aware of Nimble and will automatically
find modules so you can ``import modulename`` and have that working without
additional setup.

However, some Nimble packages can provide additional tools or commands. If you
don't add their location (``$nimbleDir/bin``) to your ``$PATH`` they will not
work properly and you won't be able to run them.

If the ``nimbledeps`` directory exists next to the package ``.nimble`` file,
Nimble will use that directory as ``$nimbleDir`` and ``$HOME/.nimble`` will be
ignored. This allows for project local dependencies and isolation from other
projects. The `-l | --localdeps` flag can be used to setup a project in local
dependency mode.

Nimble also allows overriding ``$nimbleDir`` on the command-line with the
``--nimbleDir`` flag or the ``NIMBLE_DIR`` environment variable if required.

If the default ``$HOME/.nimble`` is overridden by one of the above methods,
Nimble automatically adds ``$nimbleDir/bin`` to the PATH for all child processes.
In addition, the ``NIMBLE_DIR`` environment variable is also set to the specified
``$nimbleDir`` to inform child Nimble processes invoked in tasks.

### Nim compiler

The Nim compiler cannot read ``.nimble`` files. Its knowledge of Nimble is
limited to the ``nimblePath`` feature which allows it to use packages installed
in Nimble's package directory when compiling your software. This means that
it cannot resolve dependencies, and it can only use the latest version of a
package when compiling.

When Nimble builds your package it executes the Nim compiler.
It resolves the dependencies and feeds the path of each package to
the compiler so that it knows precisely which version to use.

This means that you can safely compile using the compiler when developing your
software, but you should use Nimble to build the package before publishing it
to ensure that the dependencies you specified are correct.

### Compile with `nim` after changing the Nimble directory

The Nim compiler has been preconfigured to look at the default ``$HOME/.nimble``
directory while compiling, so no extra step is required to use Nimble managed
packages. However, if a custom ``$nimbleDir`` is in use by one of the methods
mentioned earlier, you need to specify the ``--nimblePath:PATH`` option to Nim.

For example, if your Nimble directory is located at `/some/custom/path/nimble`,
this should work:

```
nim c --nimblePath:/some/custom/path/nimble/pkgs2 main.nim
```

In the case of package local dependencies with ``nimbledeps``:

```
nim c --nimblePath:nimbledeps/pkgs2 main.nim
```

Some code editors rely on `nim check` to check for errors under the hood (e.g.
VScode), and the editor extension may not allow users to pass custom option to
`nim check`, which will cause `nim check` to scream `Error: cannot open file:<the_package>`.
In this case, you will have to use the Nim compiler's configuration file capability.
Simply add the following line to the `nim.cfg` located in any directory listed
in the [documentation](https://nim-lang.org/docs/nimc.html#compiler-usage-configuration-files).
```
nimblePath = "/some/custom/path/nimble/pkgs2"
```

For project local dependencies:
```
nimblePath = "$project/nimbledeps/pkgs2"
```

## Troubleshooting

* ```SSL support is not available. Cannot connect over SSL. [HttpRequestError]```

Make sure that Nimble is configured to run with SSL, adding a ```-d:ssl```
flag to the file ```src/nimble.nim.cfg```.
After that, you can run ```src/nimble install``` and overwrite the existing
installation.

* ``Could not download: error:14077410:SSL routines:SSL23_GET_SERVER_HELLO:sslv3 alert handshake failure``

If you are on macOS, you need to set and export the ```DYLD_LIBRARY_PATH``` environment variable to the directory where your OpenSSL libraries are. For example, if you use OpenSSL, you have to set ```export DYLD_LIBRARY_PATH=/usr/local/opt/openssl/lib``` in your ```$HOME/.bashrc``` file.

* ``Error: ambiguous identifier: 'version' --use nimscriptapi.version or system.version``

Make sure that you are running at least version 0.16.0 of Nim (or the latest nightly).

* ``Error: cannot open '/home/user/.nimble/lib/system.nim'.``

Nimble cannot find the Nim standard library. This is considered a bug so
please report it. As a workaround, you can set the ``NIM_LIB_PREFIX`` environment
variable to the directory where ``lib/system.nim`` (and other standard library
files) are found. Alternatively, you can also configure this in Nimble's
config file.

## Repository information

This repository has two main branches: ``master`` and ``stable``.

The ``master`` branch is...

* default
* bleeding edge
* tested to compile with a pinned (close to HEAD) commit of Nim

The ``stable`` branch is...

* installed by ``koch tools``/``koch nimble``
* relatively stable
* should compile with Nim HEAD as well as the latest Nim version

Note: The travis build only tests whether Nimble works with the latest Nim
version.

A new Nim release (via ``koch xz``) will always bundle the ``stable`` branch.

## Contribution

If you would like to help, feel free to fork and make any additions you see fit
and then send a pull request.

If you have any questions about the project, you can ask me directly on GitHub,
ask on the Nim [forum](https://forum.nim-lang.org), or ask on Freenode in
the #nim channel.

## Implementation details

### .nimble-link

These files are created by Nimble when using the ``develop`` command. They
are very simple and contain two lines.

**The first line:** Always a path to the `.nimble` file.

**The second line:** Always a path to the Nimble package's source code. Usually
``$pkgDir/src``, depending on what ``srcDir`` is set to.

The paths written by Nimble are **always** absolute. But Nimble (and the
Nim compiler) also supports relative paths, which will be read relative to
the `.nimble-link` file.

## About

Nimble has been written by [Dominik Picheta](https://picheta.me/) with help from
a number of
[contributors](https://github.com/nim-lang/nimble/graphs/contributors).
It is licensed under the 3-clause BSD license, see [license.txt](license.txt)
for more information.
