# Nim Compiler
This repo contains the Nim compiler, Nim's stdlib, tools and
documentation.

## Compiling
Compiling the Nim compiler is quite straightforward. Because
the Nim compiler itself is written in the Nim programming language
the C source of an older version of the compiler are needed to bootstrap the
latest version. The C sources are available in a separate repo [here](http://github.com/nim-lang/csources).

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

If you are on a fairly modern *nix system, the following steps should work:

```
$ git clone git://github.com/Araq/Nim.git
$ cd Nim
$ git clone --depth 1 git://github.com/nim-lang/csources
$ cd csources && sh build.sh
$ cd ..
$ bin/nim c koch
$ ./koch boot -d:release
```

``koch install [dir]`` may then be used to install Nim, but lots of things don't work then so don't do that. Add it to your PATH instead. More ``koch`` related options are documented in
[doc/koch.txt](doc/koch.txt).

The above steps can be performed on Windows in a similar fashion, the
``build.bat`` and ``build64.bat`` (for x86_64 systems) are provided to be used
instead of ``build.sh``.

## Getting help
A [forum](http://forum.nim-lang.org/) is available if you have any
questions, and you can also get help in the IRC channel on
[Freenode](irc://irc.freenode.net/nim) in #nim. If you ask questions on
[StackOverflow use the nim
tag](http://stackoverflow.com/questions/tagged/nim).

## License
The compiler and the standard library are licensed under the MIT license,
except for some modules where the documentation suggests otherwise. This means
that you can use any license for your own programs developed with Nim,
allowing you to create commercial applications.

Read copying.txt for more details.

Copyright (c) 2006-2015 Andreas Rumpf.
All rights reserved.

# Build Status
[**Build Waterfall**][waterfall]

|        | Linux                                                                                                  | Windows                               | Mac                           |
| ------ | -----                                                                                                  | -------                               | ---                           |
| x86    | ![linux-x86][linux-x86-img]                                                                            | ![windows-x86][windows-x86-img]       | ![mac-x86][mac-x86-img]       |
| x86_64 | ![linux-x86_64][linux-x86_64-img]                                                                      | ![windows-x86_64][windows-x86_64-img] | ![mac-x86_64][mac-x86_64-img] |
| arm    | ![linux-armv5][linux-arm5-img]<br/> ![linux-armv6][linux-arm6-img]<br/> ![linux-armv7][linux-arm7-img] |                                       |                               |

[linux-x86-img]:      http://buildbot.nim-lang.org/buildstatusimage?builder=linux-x32-builder
[linux-x86_64-img]:   http://buildbot.nim-lang.org/buildstatusimage?builder=linux-x64-builder
[linux-arm5-img]:     http://buildbot.nim-lang.org/buildstatusimage?builder=linux-arm5-builder
[linux-arm6-img]:     http://buildbot.nim-lang.org/buildstatusimage?builder=linux-arm6-builder
[linux-arm7-img]:     http://buildbot.nim-lang.org/buildstatusimage?builder=linux-arm7-builder

[windows-x86-img]:    http://buildbot.nim-lang.org/buildstatusimage?builder=windows-x32-builder
[windows-x86_64-img]: http://buildbot.nim-lang.org/buildstatusimage?builder=windows-x64-builder

[mac-x86-img]:        http://buildbot.nim-lang.org/buildstatusimage?builder=mac-x32-builder
[mac-x86_64-img]:     http://buildbot.nim-lang.org/buildstatusimage?builder=mac-x64-builder

[waterfall]: http://buildbot.nim-lang.org/waterfall
