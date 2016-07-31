# <img src="https://raw.githubusercontent.com/nim-lang/assets/master/Art/logo-crown.png" width="36"> Nim [![Build Status](https://travis-ci.org/nim-lang/Nim.svg?branch=devel)](https://travis-ci.org/nim-lang/Nim)

This repo contains the Nim compiler, Nim's stdlib, tools and
documentation. For more information about Nim, including downloads
and documentation for the latest release, check out
[Nim's website](http://nim-lang.org).

## Compiling
Compiling the Nim compiler is quite straightforward. Because
the Nim compiler itself is written in the Nim programming language
the C source of an older version of the compiler are needed to bootstrap the
latest version. The C sources are available in a separate
repo [here](http://github.com/nim-lang/csources).

The compiler currently supports the following platform and architecture
combinations:

  * Windows (Windows XP or greater) - x86 and x86_64
  * Linux (most, if not all, distributions) - x86, x86_64, ppc64 and armv6l
  * Mac OS X 10.04 or higher - x86, x86_64 and ppc64

In reality a lot more are supported, however they are not tested regularly.

To build from source you will need:

  * gcc 3.x or later recommended. Other alternatives which may work
    are: clang, Visual C++, Intel's C++ compiler
  * git or wget

**Note:** When installing ``gcc`` on Ubuntu (and likely other distros) ensure that the ``build-essentials`` package is installed also.

If you are on a fairly modern *nix system, the following steps should work:

```
$ git clone https://github.com/nim-lang/Nim.git
$ cd Nim
$ git clone --depth 1 https://github.com/nim-lang/csources
$ cd csources && sh build.sh
$ cd ..
$ bin/nim c koch
$ ./koch boot -d:release
```

You should then add the ``bin`` directory to your PATH, to make it easily
executable on your system.

The above steps can be performed on Windows in a similar fashion, the
``build.bat`` and ``build64.bat`` (for x86_64 systems) are provided to be used
instead of ``build.sh``.

The ``koch`` tool is the Nim build tool, more ``koch`` related options are
documented in [doc/koch.txt](doc/koch.txt).

## Nimble
[Nimble](https://github.com/nim-lang/nimble) is Nim's package manager. For the
source based installations where you added Nim's ``bin`` directory to your PATH
the easiest way of installing Nimble is via:

```
$ nim e install_nimble.nims
```

**Warning:** If you install Nimble this way, you will not be able to use binary
Nimble packages or update Nimble easily.
The [Nimble readme](https://github.com/nim-lang/nimble#installation)
provides thorough instructions on how to install Nimble, so that this isn't a
problem.

## Community
[![Join the Chat at irc.freenode.net#nim](https://img.shields.io/badge/IRC-join_chat_in_%23nim-blue.svg)](https://webchat.freenode.net/?channels=nim)
[![Get help](https://img.shields.io/badge/Forum-get%20help-4eb899.svg)](http://forum.nim-lang.org)
[![Stackoverflow](https://img.shields.io/badge/stackoverflow-use_%23nim_tag-yellow.svg)](http://stackoverflow.com/questions/tagged/nim?sort=newest&pageSize=15)
[![Follow @nim_lang!](https://img.shields.io/twitter/follow/nim_lang.svg?style=social)](https://twitter.com/nim_lang)

* The [forum](http://forum.nim-lang.org/) - the best place to ask questions and to discuss Nim.
* [IRC (Freenode#nim)](https://webchat.freenode.net/?channels=nim) - the best place to discuss
  Nim in real-time, this is also where most development decision get made!
* [Stackoverflow](http://stackoverflow.com/questions/tagged/nim)

## Contributing

[![Contribute to Nim via Gratipay!](https://img.shields.io/gratipay/team/nim.svg)](https://gratipay.com/nim/)
[![Bountysource](https://img.shields.io/bountysource/team/nim/activity.svg)](https://www.bountysource.com/teams/nim)

We welcome everyone's contributions to Nim. No matter how small or large
the contribution is, anything from small spelling fixes to large modules
intended to be included in the standard library are accepted. Before
you get started, you should know the following about this repositories
structure:

* ``bin/``, ``build/`` - these directories are empty, but are used when Nim is built.
* ``compiler/`` - the compiler source code, all the Nim source code files in this
  directory implement the compiler. This also includes nimfix, and plugins
  which live in ``compiler/nimfix`` and ``compiler/plugins``
  respectively. Nimsuggest used to live in the ``compiler`` directory also,
  but was moved to https://github.com/nim-lang/nimsuggest.
* ``config/`` - the configuration for the compiler and documentation generator.
* ``doc/`` - the documentation files in reStructuredText format.
* ``lib/`` - where the standard library lives.
    * ``pure/`` - modules in the standard library written in pure Nim.
    * ``impure/`` - modules in the standard library written in pure Nim which
      depend on libraries written in other languages.
    * ``wrappers/`` - modules which wrap libraries written in other languages.
* ``tests/`` - contains tests for the compiler and standard library, organised by
    category.
* ``tools/`` - the tools including ``niminst`` and ``nimweb``, most of these are invoked
    via ``koch``.
* ``web/`` - the Nim website (http://nim-lang.org).
* ``koch.nim`` - tool used to bootstrap Nim, generate C sources, build the website, documentation
  and more.

Most importantly, the ``koch`` tool can be used to run the test suite. To do so compile it first
by executing ``nim c koch``, then execute ``./koch tests``. The test suite takes a while to run,
but you can run specific tests by specifying a category to run, for example ``./koch tests cat async``.

Make sure that the tests all pass before
[submitting your pull request](https://help.github.com/articles/using-pull-requests/).
If you're short on time, you can
just run the tests specific to your change. Just run the category which corresponds to the change
you've made. When you create your pull request, Travis CI will verify that all the tests pass
anyway.

If you're looking for things to do, take a look at our
[issue tracker](https://github.com/nim-lang/Nim/issues). There is always plenty of issues
labelled [``Easy``](https://github.com/nim-lang/Nim/labels/Easy), these should be a good
starting point if this is your first contribution to Nim.

You can also help with the development of Nim by making donations. You can do so
in many ways:

* [Gratipay](https://gratipay.com/nim/)
* [Bountysource](https://www.bountysource.com/teams/nim)
* Bitcoin - 1BXfuKM2uvoD6mbx4g5xM3eQhLzkCK77tJ

Finally, if you have any questions feel free to submit a question on the issue tracker,
on the [Nim forum](http://forum.nim-lang.org), or on IRC.

## License
The compiler and the standard library are licensed under the MIT license,
except for some modules where the documentation suggests otherwise. This means
that you can use any license for your own programs developed with Nim,
allowing you to create commercial applications.

Read copying.txt for more details.

Copyright (c) 2006-2016 Andreas Rumpf.
All rights reserved.

# Build Status
[**Build Waterfall**][waterfall]

|        | Linux | Windows | Mac |
| ------ | ----- | ------- | --- |
| x86    | [![linux-x86][linux-x86-img]][linux-x86] | [![windows-x86][windows-x86-img]][windows-x86] |
| x86_64 | [![linux-x86_64][linux-x86_64-img]][linux-x86_64] | [![windows-x86_64][windows-x86_64-img]][windows-x86_64] | [![mac-x86_64][mac-x86_64-img]][mac-x86_64] |
| arm    | [![linux-armv5][linux-arm5-img]][linux-arm5]<br/> [![linux-armv6][linux-arm6-img]][linux-arm6]<br/> [![linux-armv7][linux-arm7-img]][linux-arm7]

[linux-x86]:          http://buildbot.nim-lang.org/builders/linux-x32-builder
[linux-x86-img]:      http://buildbot.nim-lang.org/buildstatusimage?builder=linux-x32-builder
[linux-x86_64]:       http://buildbot.nim-lang.org/builders/linux-x64-builder
[linux-x86_64-img]:   http://buildbot.nim-lang.org/buildstatusimage?builder=linux-x64-builder
[linux-arm5]:         http://buildbot.nim-lang.org/builders/linux-arm5-builder
[linux-arm5-img]:     http://buildbot.nim-lang.org/buildstatusimage?builder=linux-arm5-builder
[linux-arm6]:         http://buildbot.nim-lang.org/builders/linux-arm6-builder
[linux-arm6-img]:     http://buildbot.nim-lang.org/buildstatusimage?builder=linux-arm6-builder
[linux-arm7]:         http://buildbot.nim-lang.org/builders/linux-arm7-builder
[linux-arm7-img]:     http://buildbot.nim-lang.org/buildstatusimage?builder=linux-arm7-builder

[windows-x86]:        http://buildbot.nim-lang.org/builders/windows-x32-builder
[windows-x86-img]:    http://buildbot.nim-lang.org/buildstatusimage?builder=windows-x32-builder
[windows-x86_64]:     http://buildbot.nim-lang.org/builders/windows-x64-builder
[windows-x86_64-img]: http://buildbot.nim-lang.org/buildstatusimage?builder=windows-x64-builder

[mac-x86_64]:         http://buildbot.nim-lang.org/builders/mac-x64-builder
[mac-x86_64-img]:     http://buildbot.nim-lang.org/buildstatusimage?builder=mac-x64-builder

[waterfall]: http://buildbot.nim-lang.org/waterfall
