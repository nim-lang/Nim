
[comment]: # (Before releasing, make sure to follow the steps in https://github.com/nim-lang/nimble/wiki/Releasing-a-new-version)

# Nimble changelog

## 0.14.0

This is a major release containing four new features:

- A new dependencies development mode.
- Support for lock files.
- Download tarballs when downloading packages from GitHub.
- A setup command.
- Added a `--package, -p` command line option.

## 0.13.0

This is a bugfix release. It enhances the security in multiple aspects:

- URLs default to `https`.
- SSL certificates are checked.
- Shell escaping bugs have been fixed.


## 0.12.0

This is a major release containing multiple improvements and bug fixes:

- `nimble dump` now provides `--json` output.
- Calls to the Nim compiler now display `--hints:off` output by default.
  The `--verbose` flag will print the full Nim command as well as regular
  compiler output.
- Custom tasks can now be passed compiler flags as well as run flags when run
  as `nimble <compflags> task <runflags>`. This includes the custom `test`
  task if defined. Compile flags are forwarded to `nim e` that executes the
  `.nimble` task and can be used to set `--define:xxx` and other compiler flags
  that are applicable in Nimscript mode. Run flags can be accessed per usual
  from `commandLineParams: seq[string]`.
- The default `nimble test` task also allows passing compiler flags but given
  run flags are not really applicable for multiple test binaries, it allows
  specifying compile flags before or after the `test` task.
- `nimble install` also allows passing compiler flags similar to the default
  `nimble test` and no longer requires the `--passNim` flag.
- The Nim compiler to be used by Nimble can now be specified with the `--nim`
  flag. This is useful for debugging purposes.
- Nimble now supports project local dependency mode - if a `nimbledeps` directory
  exists within a project, Nimble will use it to store all package dependencies
  instead of `~/.nimble/bin`. This enables isolation of a project and its
  dependencies from other projects being developed.
- The `-l | --localdeps` flag can be used to setup a project in local dependency
  mode.
- Nimble output can now be suppressed using `--silent`.
- Binaries compiled by Nimble can now be named differently than the source file
  with the `namedBin` table instead of `bin`. In addition, binary names that clash
  with a `pkgname` directory containing .nim files no longer require appending
  `pkg` to the directory.

----

Full changelog: https://github.com/nim-lang/nimble/compare/v0.11.4...v0.12.0

## 0.11.4 - 19/05/2020

This is a minor release containing just 2 commits and a few minor bug fixes.

----

Full changelog: https://github.com/nim-lang/nimble/compare/v0.11.2...v0.11.4

## 0.11.2 - 02/05/2020

This is a minor release containing just 15 commits. This release brings mostly
bug fixes with some minor new features:

- The `==` operator can now be used in version requirements.
- Handling of arguments for `nimble run` has been improved.
- The `nimble run` command can now be used without any arguments if the
  package has only one binary specified.

----

Full changelog: https://github.com/nim-lang/nimble/compare/v0.11.0...v0.11.2

## 0.11.0 - 22/09/2019

This is a major release containing nearly 60 commits. Most changes are
bug fixes, but this release also includes a couple new features:

- Binaries can now be built and run using the new ``run`` command.
- The ``NimblePkgVersion`` is now defined so you can easily get the package
  version in your source code
  ([example](https://github.com/nim-lang/nimble/blob/4a2aaa07d/tests/nimbleVersionDefine/src/nimbleVersionDefine.nim)).

Some other highlights:

- Temporary files are now kept when the ``--debug`` flag is used.
- Fixed dependency resolution issues with "#head" packages (#432 and #672).
- The `install` command can now take Nim compiler flags via the new
  ``--passNim`` flag.
- Command line arguments are now passed properly to tasks (#633).
- The ``test`` command now respects the specified backend (#631).
- The ``dump`` command will no longer prompt and now has an implicit ``-y``.
- Fixed bugs with the new nimscript executor (#665).
- Fixed multiple downloads and installs of the same package (#678).
- Nimble init no longer overwrites existing files (#581).
- Fixed incorrect submodule version being pulled when in a non-master branch (#675).

----

Full changelog: https://github.com/nim-lang/nimble/compare/v0.10.2...v0.11.0

## 0.10.2 - 03/06/2019

This is a small release which avoids object variant changes that are now
treated as runtime errors (Nim #1286). It also adds support for `backend`
selection during `nimble init`.

Multiple bug fixes are also included:
- Fixed an issue where failing tasks were not returning a non-zero return
  value (#655).
- Error out if `bin` is a Nim source file (#597).
- Fixed an issue where nimble task would not run if file of same name exists.
- Fixed an issue that prevented multiple instances of nimble from running on
  the same package.

----

Full changelog: https://github.com/nim-lang/nimble/compare/v0.10.0...v0.10.2

## 0.10.0 - 27/05/2019

Nimble now uses the Nim compiler directly via `nim e` to execute nimble
scripts rather than embedding the Nim VM. This has multiple benefits:
- Evolve independently from Nim enabling new versions of Nimble to work
  with multiple versions of Nim.
- Inherit all nimscript enhancements and bug fixes rather than having to
  duplicate functionality.
- Fast build time and smaller binary.
- No dependency on the compiler package which could cause dependency issues
  when nimble is used as a package.

Several other features and fixes have been implemented to improve general
development and test workflows.
- `nimble test` now sports a `-continue` or `-c` flag that allows tests
  to continue on failure, removes all created test binaries on completion
  and warns if no tests found.
- The `--inclDeps` or `-i` flag enables `nimble uninstall` to remove all
  dependent packages during uninstall.
- Added documentation on the usage of a custom `nimbleDir`.
- Package type interactive prompt is more readable.
- Save temporary files in a per-user temp dir to enable Nimble on multi-user
  systems.
- CTRL-C is now handled correctly in interactive prompts.
- Fixed issue where empty package list led to error.
- Fixed issue where file:// was prepended incorrectly.
- Fixed miscellaneous issues in version parsing, Github auth and briefClone.
- Miscellaneous cleanup of deprecated procs.

----

Full changelog: https://github.com/nim-lang/nimble/compare/v0.9.0...v0.10.0

## 0.9.0 - 19/09/2018

This is a major new release which contains at least one breaking change.
Unfortunately even though it was planned, support for lock files did not
make it into this release. The release does
however contain a large number of fixes spread across 57 commits.

The breaking change in this release is to do with the handling of binary
package. **Any package that specifies a ``bin`` value in it's .nimble file**
**will no longer install any Nim source code files**, in other words it's not
going to be a hybrid package by default. This means that so called "hybrid
packages" now need to specify ``installExt = @["nim"]`` in their metadata,
otherwise they will become binary packages only.

- **Breaking:** hybrid packages require ``installExt = @["nim"]``
  ([Commit](https://github.com/nim-lang/nimble/commit/09091792615eacd503e87ca70252c572a4bde2b5))
- **The ``init`` command can now show a list of choices for information such as**
  **the license.**
- **The ``init`` command now creates correct project structures for all package**
  **types.**
- **Fatal errors are no longer created when the path inside a .nimble-link file**
  **doesn't exist.**
- **The ``develop`` command now always clones HEAD and grabs the full repo history.**
- **The default ``test`` task no longer executes all tests (only those starting with 't').**
- Colour is no longer used when `isatty` is false.
- ``publish`` now shows the URL of the created PR.
- The ``getPkgDir`` procedure has been fixed in the Nimble file API.
- Improved handling of proxy environment variables.
- Codebase has been improved not to rely on `nil` in strings and seqs.
- The handling of pre- and post-hooks has been improved significantly.
- Fixed the ``path`` command for packages with a ``srcDir`` and optimised the
  package look-up.

----

Full changelog: https://github.com/nim-lang/nimble/compare/v0.8.10...v0.9.0

## 0.8.10 - 23/02/2018

The first release of 2018! Another fairly big release containing 40 commits.
This release fixes many
issues, with most being fixed by our brilliant contributors. Thanks a lot
everyone!

One big new feature is the new support for multiple Nimble packages in a single
Git/Hg repository. You can now specify ``?subdir=<dir>`` at the end of your
repo's URL and Nimble will know to look in ``<dir>`` for your package.

* **Implemented support for multi-package repos.** See
  [#421](https://github.com/nim-lang/nimble/issues/421) for the relevant issue.
* **Better error message when the user has an outdated stdlib version that confuses Nimble**
* **The validity of a Nimble package can now be checked using the new ``check`` command**
* Nimble no longer silently ignores an erroneous '@' in for example
  ``nimble install compiler@``.
* Issues with the ``nimble path`` command have been fixed.
* The ``nimble publish`` command has been improved and stabilised.
* Messages for the ``NIM_LIB_PREFIX`` env var have been improved.
* ``before install`` is now called when packages are installed by their name.
  See [#280](https://github.com/nim-lang/nimble/issues/280).
* Fixed issue with ``nimble init``. See [#446](https://github.com/nim-lang/nimble/issues/446).
* Nimble now rejects [reserved names on Windows](https://github.com/nim-lang/nimble/commit/74856a87084b73451254555b2c20ad932cf84270).
* The ``NIMBLE_DIR`` environment variable is now supported, in addition to the
  command line flag and config setting.
* The ``init`` command has been improved significantly.

----

Full changelog: https://github.com/nim-lang/nimble/compare/v0.8.8...v0.8.10

## 0.8.8 - 03/09/2017

This is a relatively big release containing 57 commits, with multiple new
features and many bug fixes.

* **Implemented the `develop` command.** See
  [readme](https://github.com/nim-lang/nimble#nimble-develop) for details.
* **Implemented a default `test` task** for packages that don't define it.
* **Lowered the memory consumption** in cases where a package contained many files.
* Nimble now accepts .nimble symlinks.
* Locally stored package list files can now be specified in the Nimble config.
* Fixed branch checkout and handling of branch names with dashes.
* Improved URL detection in ``publish`` feature.
* Fixed many issues related to binary management. Packages are now resymlinked
  when an newer version is removed.
  ([#331](https://github.com/nim-lang/nimble/issues/331))
* Fixed issues with CLI arg passing to the Nim compiler.
  ([#351](https://github.com/nim-lang/nimble/issues/351))
* Improved performance of ``list -i`` command.
* Fixed issue where warnings weren't suppressed for some commands.
  ([#290](https://github.com/nim-lang/nimble/issues/290))
* Special versions other than `#head` are no longer considered to be newest.
* Improves the reverse dependency lookup by cross checking it with the
  installed list of packages.
  ([#287](https://github.com/nim-lang/nimble/issues/287))

----

Full changelog: https://github.com/nim-lang/nimble/compare/v0.8.6...v0.8.8

## 0.8.6 - 05/05/2017

Yet another point release which includes various bug fixes and improvements.

* Improves heuristic for finding Nim standard library to support choosenim
  installations and adds ability to override it via ``NIM_LIB_PREFIX``
  environment variable.
* Implement ``--noColor`` option to remove color from the output.
* Fixes bug when ``srcDir`` contains trailing slash.
* Fixes failure when ``-d`` flag is passed to ``c`` command.
* Show raw output for certain commands.
* GitHub API token can now be specified via the ``NIMBLE_GITHUB_API_TOKEN``
  environment variable.
* GitHub API token is now stored in ``~/.nimble/api_token`` so that it
  doesn't need to be specified each time.
* Fixes multiple flags not being passed in Nimble task.

----

Full changelog: https://github.com/nim-lang/nimble/compare/v0.8.4...v0.8.6

## 0.8.4 - 29/01/2017

Another bug fix release which resolves problems related to stale nimscriptapi
files in /tmp/, no compilation output when ``nimble build`` fails, and issues
with the new package validation on Windows.

----

Full changelog: https://github.com/nim-lang/nimble/compare/v0.8.2...v0.8.4

## 0.8.2 - 08/01/2017

This is a small bug fix release which resolves problems with the installation
of Aporia (and likely other Nimble packages).

## 0.8.0 - 05/01/2017

This is a large release containing multiple new features and many bug fixes.

* Implemented a completely new output system.
  * Supports different message types and priorities. Each is differently
    encoded using a color and a brightness.
  * The amount of messages shown can be changed by using the new ``--verbose``
    and ``--debug`` flags, by default only high priority messages are shown.
  * Duplicate warnings are filtered out to prevent too much noise.
* Package namespaces are now validated. You will see a warning whenever an
  incorrectly namespaced package is read by Nimble, this can occur either
  during installation or when the installed package database is being loaded.
  The namespacing rules are described in Nimble's
  [readme](https://github.com/nim-lang/nimble#libraries).
  **Consider these warnings to be unstable, if you see something that you
  think is incorrect please report it**.
* Special version dependencies are now installed into a directory with that
  special version in its name. For example, ``compiler@#head`` will be installed
  into ``~/.nimble/pkgs/compiler-#head``. This reduces the amount of redundant
  installs. See [#88](https://github.com/nim-lang/nimble/issues/88) for
  more information.
* External dependencies can now be specified in .nimble files. Nimble doesn't
  install these, but does instruct the user on how they can be installed.
  More information about this feature can be found in the
  [readme](https://github.com/nim-lang/nimble#external-dependencies).
* Nimble now supports package aliases in the packages.json files.
* Fixed regression that caused transitive dependencies to not be installed.
* Fixed problem with ``install`` command when a ``src`` directory is present
  in the current directory.
* Improved quoting of process execution arguments.
* Many improvements to custom ``--nimbleDir`` handling. All commands should now
  support it correctly.
* Running ``nimble -v`` will no longer read the Nimble config before displaying
  the version.
* Refresh command now supports a package list name as argument.
* Fixes issues with symlinks not being removed correctly.
* Changed the way the ``dump`` command locates the .nimble file.

----

Full changelog: https://github.com/nim-lang/nimble/compare/v0.7.10...v0.8.0

Full list of issues which have been closed: https://github.com/nim-lang/nimble/issues?utf8=%E2%9C%93&q=is%3Aissue+closed%3A%222016-10-09+..+2017-01-05%22+

## 0.7.10 - 09/10/2016

This release includes multiple bug fixes.

* Reverted patch that breaks binary stubs in Git Bash on Windows.
* The ``nimscriptapi.nim`` file is now statically compiled into the binary.
  This should fix the "could not find nimscriptapi.nim" errors. The file can
  still be overriden by placing a file named ``nimscriptapi.nim`` inside a
  ``nimblepkg`` directory that is placed alongside the Nimble binary, or
  by a ``nimscriptapi.nim`` file inside ``~/.nimble/pkgs/nimble-ver/nimblepkg/``.
  For more information see the
  [code that looks for this file](https://github.com/nim-lang/nimble/blob/v0.7.10/src/nimblepkg/nimscriptsupport.nim#L176).
* Nim files can now be imported in .nimble nimscript files. (Issue [#186](https://github.com/nim-lang/nimble/issues/186))
* Requiring a specific git commit hash no longer fails. (Issue [#129](https://github.com/nim-lang/nimble/issues/129))

----

Full changelog: https://github.com/nim-lang/nimble/compare/v0.7.8...v0.7.10

## 0.7.8 - 28/09/2016

This is a hotfix release which fixes crashes when Nimble (or Nim) is installed
to ``C:\Program Files`` or other paths with spaces in them.

## 0.7.6 - 26/09/2016

This is a small release designed to coincide with the release of Nim 0.15.0.

* Fixes ``--depsOnly`` flag ([commit](https://github.com/nim-lang/nimble/commit/f6a19b54e47c7c99f2b473fc02915277273f8c41))
* Fixes compilation on 0.15.0.
* Fixes #239.
* Fixes #215.
* VCS information is now stored in the Nimble package metadata.

## 0.7.4 - 06/06/2016

This release is mainly a bug fix release. The installation problems
introduced by v0.7.0 should now be fixed.

* Fixed symlink install issue
  (Thank you [@yglukhov](https://github.com/yglukhov)).
* Fixed permission issue when installing packages
  (Thank you [@SSPkrolik](https://github.com/SSPkrolik)).
* Work around for issue #204.
  (Thank you [@Jeff-Ciesielski](https://github.com/Jeff-Ciesielski)).
* Fixed FD leak.
  (Thank you [@yglukhov](https://github.com/yglukhov)).
* Implemented the ``--depsOnly`` option for the ``install`` command.
* Various fixes to installation/nimscript support problems introduced by
v0.7.0.

----

Full changelog: https://github.com/nim-lang/nimble/compare/v0.7.2...v0.7.4

## 0.7.2 - 11/02/2016

This is a hotfix release which alleviates problems when building Nimble.

See Issue [#203](https://github.com/nim-lang/nimble/issues/203) for more
information.

## 0.7.0 - 30/12/2015

This is a major release.
Significant changes include NimScript support, configurable package list
URLs, a new ``publish`` command, the removal of the dependency on
OpenSSL, and proxy support. More detailed list of changes follows:

* Fixed ``chcp`` on Windows XP and Windows Vista
  (Thank you [@vegansk](https://github.com/vegansk)).
* Fixed incorrect command line processing
  (Issue [#151](https://github.com/nim-lang/nimble/issues/151))
* Merged ``developers.markdown`` back into ``readme.markdown``
  (Issue [#132](https://github.com/nim-lang/nimble/issues/132))
* Removed advertising clause from license
  (Issue [#153](https://github.com/nim-lang/nimble/issues/153))
* Implemented ``publish`` command
  (Thank you for taking the initiative [@Araq](https://github.com/Araq))
* Implemented NimScript support. Nimble now import a portion of the Nim
  compiler source code for this.
  (Thank you for taking the initiative [@Araq](https://github.com/Araq))
* Fixes incorrect logic for finding the Nim executable
  (Issue [#125](https://github.com/nim-lang/nimble/issues/125)).
* Renamed the ``update`` command to ``refresh``. **The ``update`` command will
  mean something else soon!**
  (Issue [#158](https://github.com/nim-lang/nimble/issues/158))
* Improvements to the ``init`` command.
  (Issue [#96](https://github.com/nim-lang/nimble/issues/96))
* Package names must now officially be valid Nim identifiers. Package's
  with dashes in particular will become invalid in the next version.
  Warnings are shown now but the **next version will show an error**.
  (Issue [#126](https://github.com/nim-lang/nimble/issues/126))
* Added error message when no build targets are present.
  (Issue [#108](https://github.com/nim-lang/nimble/issues/108))
* Implemented configurable package lists. Including fallback URLs
  (Issue [#75](https://github.com/nim-lang/nimble/issues/75)).
* Removed the OpenSSL dependency
  (Commit [ec96ee7](https://github.com/nim-lang/nimble/commit/ec96ee7709f0f8bd323aa1ac5ed4c491c4bf23be))
* Implemented proxy support. This can be configured using the ``http_proxy``/
  ``https_proxy`` environment variables or Nimble's configuration
  (Issue [#86](https://github.com/nim-lang/nimble/issues/86)).
* Fixed issues with reverse dependency storage
  (Issue [#113](https://github.com/nim-lang/nimble/issues/113) and
   [#168](https://github.com/nim-lang/nimble/issues/168)).

----

Full changelog: https://github.com/nim-lang/nimble/compare/v0.6.2...v0.7.0

## 0.6.4 - 30/12/2015

This is a hotfix release fixing compilation with Nim 0.12.0.

See Issue [#180](https://github.com/nim-lang/nimble/issues/180) for more
info.

## 0.6.2 - 19/06/2015

* Added ``binDir`` option to specify where the build output should be placed
  (Thank you [@minciue](https://github.com/minciue)).
* Fixed deprecated code (Thank you [@lou15b](https://github.com/lou15b)).
* Fixes to old ``.babel`` folder handling
  (Thank you [@ClementJnc](https://github.com/ClementJnc)).
* Added ability to list only the installed packages via
  ``nimble list --installed`` (Thank you
  [@hiteshjasani](https://github.com/hiteshjasani).
* Fixes compilation with Nim v0.11.2 (Thank you
  [@JCavallo](https://github.com/JCavallo)).
* Implements the ``--nimbleDir`` option (Thank you
  [@ClementJnc](https://github.com/ClementJnc)).
* [Fixes](https://github.com/nim-lang/nimble/issues/128) ``nimble uninstall``
  not giving an error when no package name is
  specified (Thank you [@dom96](https://github.com/dom96)).
* [When](https://github.com/nim-lang/nimble/issues/139) installing and building
  a tagged version of a package fails, Nimble will
  now attempt to install and build the ``#head`` of the repo
  (Thank you [@dom96](https://github.com/dom96)).
* [Fixed](https://github.com/nim-lang/nimble/commit/1234cdce13c1f1b25da7980099cffd7f39b54326)
  cloning of git repositories with non-standard default branches
  (Thank you [@dom96](https://github.com/dom96)).

----

Full changelog: https://github.com/nim-lang/nimble/compare/v0.6...v0.6.2

## 0.6.0 - 26/12/2014

* Renamed from Babel to Nimble
* Introduces compatibility with Nim v0.10.0+
* Implemented the ``init`` command which generates a .nimble file for new
  projects. (Thank you
  [@singularperturbation](https://github.com/singularperturbation))
* Improved cloning of git repositories.
  (Thank you [@gradha](https://github.com/gradha))
* Fixes ``path`` command issues (Thank you [@gradha](https://github.com/gradha))
* Fixes problems with symlinking when there is a space in the path.
  (Thank you [@philip-wernersbach](https://github.com/philip-wernersbach))
* The code page will now be changed when executing Nimble binary packages.
  This adds support for Unicode in cmd.exe (#54).
* ``.cmd`` files are now used in place of ``.bat`` files. Shell files for
  Cygwin/Git bash are also now created.

## 0.4.0 - 24/06/2014

* Introduced the ability to delete packages.
* When installing packages, a list of files which have been copied is stored
  in the babelmeta.json file.
* When overwriting an already installed package babel will no longer delete
  the whole directory but only the files which it installed.
* Versions are now specified on the command line after the '@' character when
  installing and uninstalling packages. For example: ``babel install foobar@0.1``
  and ``babel install foobar@#head``.
* The babel package installation directory can now be changed in the new
  config.
* Fixes a number of issues.
