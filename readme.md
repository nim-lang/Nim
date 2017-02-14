# ![Logo][image-nim-logo] Nim [![Build Status][badge-nim-travisci]][nim-travisci]

This repository contains the Nim compiler, Nim's stdlib, tools and documentation.
For more information about Nim, including downloads and documentation for
the latest release, check out [Nim's website][nim-site].

## Community
[![Join the IRC chat][badge-nim-irc]][nim-irc]
[![Join the Gitter chat][badge-nim-gitter]][nim-gitter]
[![Get help][badge-nim-forum-gethelp]][nim-forum]
[![View Nim posts on Stack Overflow][badge-nim-stackoverflow]][nim-stackoverflow-newest]
[![Follow @nim_lang on Twitter][badge-nim-twitter]][nim-twitter]

* The [forum][nim-forum] - the best place to ask questions and to discuss Nim.
* [#nim IRC Channel (Freenode)][nim-irc] - a place to discuss Nim in real-time.
  Also where most development decisions get made.
* [Gitter][nim-gitter] - an additional place to discuss Nim in real-time. There
  is a bridge between Gitter and the IRC channel.
* [Stack Overflow][nim-stackoverflow] - a popular Q/A site for programming related
  topics that includes posts about Nim.

## Compiling
The compiler currently officially supports the following platform and
architecture combinations:

  * Windows (Windows XP or greater) - x86 and x86_64
  * Linux (most, if not all, distributions) - x86, x86_64, ppc64 and armv6l
  * Mac OS X (10.04 or greater) - x86, x86_64 and ppc64

More platforms are supported, however they are not tested regularly and they
may not be as stable as the above-listed platforms.

Compiling the Nim compiler is quite straightforward if you follow these steps:

First, the C source of an older version of the Nim compiler is needed to
bootstrap the latest version because the Nim compiler itself is written in the
Nim programming language. Those C sources are available within the 
[``nim-lang/csources``][csources-repo] repository.

Next, to build from source you will need:

  * A C compiler such as ``gcc`` 3.x/later or an alternative such as ``clang``,
    ``Visual C++`` or ``Intel C++``. It is recommended to use ``gcc`` 3.x or
    later.
  * Either ``git`` or ``wget`` to download the needed source repositories.
  * The ``build-essentials`` package when using ``gcc`` on Ubuntu (and likely
    other distros as well). 

Then, if you are on a \*nix system or Windows, the following steps should compile
Nim from source using ``gcc``, ``git`` and the ``koch`` build tool (in the place
of ``sh build.sh`` you should substitute ``build.bat`` on x86 Windows or
``build64.bat`` on x86_64 Windows):

```
$ git clone https://github.com/nim-lang/Nim.git
$ cd Nim
$ git clone --depth 1 https://github.com/nim-lang/csources.git
$ cd csources
$ sh build.sh
$ cd ../
$ bin/nim c koch
$ ./koch boot -d:release
```

Finally, once you have finished the build steps (on Windows, Mac or Linux) you
should add the ``bin`` directory to your PATH.

## Koch
``koch`` is the build tool used to build various parts of Nim and to generate
documentation and the website, among other things. The ``koch`` tool can also
be used to run the Nim test suite. 

Assuming that you added Nim's ``bin`` directory to your PATH, you may execute
the tests using ``./koch tests``. The tests take a while to run, but you
can run a subset of tests by specifying a category (for example 
``./koch tests cat async``).

For more information on the ``koch`` build tool please see the documentation
within the [doc/koch.rst](doc/koch.rst) file.

## Nimble
``nimble`` is Nim's package manager and it can be acquired from the
[``nim-lang/nimble``][nimble-repo] repository. Assuming that you added Nim's
``bin`` directory to your PATH, you may install Nimble from source by running
``koch nimble`` within the root of the cloned repository.

## Contributing
[![Contribute to Nim via Gratipay][badge-nim-gratipay]][nim-gratipay]
[![Setup a bounty via Bountysource][badge-nim-bountysource]][nim-bountysource]
[![Donate Bitcoins][badge-nim-bitcoin]][nim-bitcoin]

We welcome everyone's contributions to Nim independent of how small or how large
they are. Anything from small spelling fixes to large modules intended to
be included in the standard library are welcome and appreciated. Before you get
started contributing, you should familiarize yourself with the repository structure:

* ``bin/``, ``build/`` - these directories are empty, but are used when Nim is built.
* ``compiler/`` - the compiler source code. Also includes nimfix, and plugins within
  ``compiler/nimfix`` and ``compiler/plugins`` respectively. Nimsuggest was moved to
  the [``nim-lang/nimsuggest``][nimsuggest-repo] repository, though it previously also 
  lived within the ``compiler/`` directory.
* ``config/`` - the configuration for the compiler and documentation generator.
* ``doc/`` - the documentation files in reStructuredText format.
* ``lib/`` - the standard library, including:
    * ``pure/`` - modules in the standard library written in pure Nim.
    * ``impure/`` - modules in the standard library written in pure Nim with
    dependencies written in other languages.
    * ``wrappers/`` - modules which wrap dependencies written in other languages.
* ``tests/`` - contains categorized tests for the compiler and standard library.
* ``tools/`` - the tools including ``niminst`` and ``nimweb`` (mostly invoked via
  ``koch``).
* ``web/`` - [the Nim website][nim-site].
* ``koch.nim`` - tool used to bootstrap Nim, generate C sources, build the website,
  and generate the documentation.

If you are not familiar with making a pull request using GitHub and/or git, please
read [this guide][pull-request-instructions].

Ideally you should make sure that all tests pass before submitting a pull request.
However, if you are short on time, you can just run the tests specific to your
changes by only running the corresponding categories of tests. Travis CI verifies
that all tests pass before allowing the pull request to be accepted, so only
running specific tests should be harmless.

If you're looking for ways to contribute, please look at our [issue tracker][nim-issues].
There are always plenty of issues labelled [``Easy``][nim-issues-easy]; these should
be a good starting point for an initial contribution to Nim.

You can also help with the development of Nim by making donations. Donations can be
made using:

* [Gratipay][nim-gratipay]
* [Bountysource][nim-bountysource]
* [Bitcoin][nim-bitcoin]

If you have any questions feel free to submit a question on the
[Nim forum][nim-forum], or via IRC on [the \#nim channel][nim-irc].

## License
The compiler and the standard library are licensed under the MIT license, except
for some modules which explicitly state otherwise. As a result you may use any
compatible license (essentially any license) for your own programs developed with
Nim. You are explicitly permitted to develop commercial applications using Nim.

Please read the [copying.txt](copying.txt) file for more details.

Copyright © 2006-2017 Andreas Rumpf, all rights reserved.

[nim-site]: https://nim-lang.org
[nim-forum]: https://forum.nim-lang.org
[nim-issues]: https://github.com/nim-lang/Nim/issues
[nim-issues-easy]: https://github.com/nim-lang/Nim/labels/Easy
[nim-irc]: https://webchat.freenode.net/?channels=nim
[nim-travisci]: https://travis-ci.org/nim-lang/Nim
[nim-twitter]: https://twitter.com/nim_lang
[nim-stackoverflow]: https://stackoverflow.com/questions/tagged/nim
[nim-stackoverflow-newest]: https://stackoverflow.com/questions/tagged/nim?sort=newest&pageSize=15
[nim-gitter]: https://gitter.im/nim-lang/Nim
[nim-gratipay]: https://gratipay.com/nim/
[nim-bountysource]: https://www.bountysource.com/teams/nim
[nim-bitcoin]: https://blockchain.info/address/1BXfuKM2uvoD6mbx4g5xM3eQhLzkCK77tJ
[nimble-repo]: https://github.com/nim-lang/nimble
[nimsuggest-repo]: https://github.com/nim-lang/nimsuggest
[csources-repo]: https://github.com/nim-lang/csources
[badge-nim-travisci]: https://img.shields.io/travis/nim-lang/Nim/devel.svg?style=flat-square
[badge-nim-irc]: https://img.shields.io/badge/chat-on_irc-blue.svg?style=flat-square
[badge-nim-gitter]: https://img.shields.io/badge/chat-on_gitter-blue.svg?style=flat-square
[badge-nim-forum-gethelp]: https://img.shields.io/badge/Forum-get%20help-4eb899.svg?style=flat-square
[badge-nim-twitter]: https://img.shields.io/twitter/follow/nim_lang.svg?style=social
[badge-nim-stackoverflow]: https://img.shields.io/badge/stackoverflow-nim_tag-yellow.svg?style=flat-square
[badge-nim-gratipay]: https://img.shields.io/gratipay/team/nim.svg?style=flat-square
[badge-nim-bountysource]: https://img.shields.io/bountysource/team/nim/activity.svg?style=flat-square
[badge-nim-bitcoin]: https://img.shields.io/badge/bitcoin-1BXfuKM2uvoD6mbx4g5xM3eQhLzkCK77tJ-D69134.svg?style=flat-square
[image-nim-logo]: https://images1-focus-opensocial.googleusercontent.com/gadgets/proxy?url=https://raw.githubusercontent.com/nim-lang/assets/master/Art/logo-crown.png&container=focus&resize_w=36&refresh=21600
[pull-request-instructions]: https://help.github.com/articles/using-pull-requests/
