=============
Packaging Nim
=============

This page provide hints on distributing Nim using OS packages.

See `distros <distros.html>`_ for tools to detect Linux distribution at runtime.

See `here <intern.html#bootstrapping-the-compiler-reproducible-builds>`_ for how to
compile reproducible builds.

Supported architectures
-----------------------

Nim runs on a wide variety of platforms. Support on amd64 and i386 is tested regularly, while less popular platforms are tested by the community.

- amd64
- arm64 (aka aarch64)
- armel
- armhf
- i386
- m68k
- mips64el
- mipsel
- powerpc
- ppc64
- ppc64el (aka ppc64le)
- riscv64

The following platforms are seldomly tested:

- alpha
- hppa
- ia64
- mips
- s390x
- sparc64

Packaging for Linux
-------------------

See https://github.com/nim-lang/Nim/labels/Installation for installation-related bugs.

Build Nim from the released tarball at https://nim-lang.org/install_unix.html
It is different from the GitHub sources as it contains Nimble, C sources & other tools.

The Debian package ships bash and ksh completion and manpages that can be reused.

Hints on the build process:

.. code:: cmd

   # build from C sources and then using koch
   make -j   # supports parallel build
   # alternatively: ./build.sh --os $os_type --cpu $cpu_arch
   ./bin/nim c -d:release koch
   ./koch boot -d:release

   # optionally generate docs into doc/html
   ./koch docs

   ./koch tools

   # extract files to be really installed
   ./install.sh <tempdir>

   # also include the tools
   for fn in nimble nimsuggest nimgrep; do cp ./bin/$fn <tempdir>/nim/bin/; done

What to install:

- The expected stdlib location is /usr/lib/nim
- Global configuration files under /etc/nim
- Optionally: manpages, documentation, shell completion
- When installing documentation, .idx files are not required
- The "compiler" directory contains compiler sources and should not be part of the compiler binary package

