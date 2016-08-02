Download the compiler
=====================

You can download the latest version of the Nim compiler here.

**Note:** The Nim compiler requires a C compiler to compile software. On
Windows we recommend that you use
`Mingw-w64 <http://mingw-w64.sourceforge.net/>`_. GCC is recommended on Linux
and Clang on Mac.


Binaries
--------

Unfortunately, right now we only provide binaries for Windows. You can download
an installer for both 32 bit and 64 bit versions of Windows below.

* | 32 bit: `nim-0.14.2_x32.exe <download/nim-0.14.2_x32.exe>`_
  | SHA-256  ca2de37759006d95db98732083a6fab20151bb9819186af2fa29d41884df78c9
* | 64 bit: `nim-0.14.2_x64.exe <download/nim-0.14.2_x64.exe>`_
  | SHA-256  1fec054d3a5f54c0a67a40db615bb9ecb1d56413b19e324244110713bd4337d1

These installers also include Aporia, Nimble and other useful Nim tools to get
you started with Nim development!

Installation based on generated C code
--------------------------------------

This installation method is the preferred way for Linux, Mac OS X, and other Unix
like systems. Binary packages may be provided later.


Firstly, download this archive:

* | `nim-0.14.2.tar.xz (4.5MB) <download/nim-0.14.2.tar.xz>`_
  | SHA-256  8f8d38d70ed57164795fc55e19de4c11488fcd31dbe42094e44a92a23e3f5e92

Extract the archive. Then copy the extracted files into your chosen installation
directory, ideally somewhere in your home directory.
For example: ``~/programs/nim``.

Now open a terminal and follow these instructions:

* ``cd`` into your installation directory, for example by executing
``cd ~/programs/nim``.
* run ``sh build.sh``.
* Add ``$your_install_dir/bin`` to your PATH.

After restarting your terminal, you should be able to run ``nim -v``
which should show you the version of Nim you just installed.

There are other ways to install Nim (like using the ``install.sh`` script),
but these tend to cause more problems.


Bleeding edge installation from GitHub
--------------------------------------

`GitHub <http://github.com/nim-lang/nim>`_ is where Nim's development takes
place. You may wish to grab the latest development version of Nim, because
sometimes bug fixes and new features may not have made it to an official
release yet. In those circumstances you are better off grabbing the
current development branch.

You will also need to do this if you would like to contribute to Nim.

Before you download the code, open a new terminal and ``cd`` into the
directory where you would like the download to take place.

The following commands can be used to download the current development branch
and then to build it::

  git clone git://github.com/nim-lang/Nim.git
  cd Nim
  git clone --depth 1 git://github.com/nim-lang/csources
  cd csources && sh build.sh
  cd ..
  bin/nim c koch
  ./koch boot -d:release

You should then add the ``./bin`` (make sure to expand this into an
absolute path) directory to your ``PATH``.


Docker Hub
----------

The `official Docker images <https://hub.docker.com/r/nimlang/nim/>`_
are published Docker Hub and include the compiler and Nimble. There are images
for standalone scripts as well as Nimble packages.

Get the latest stable image::

  docker pull nimlang/nim

The latest development version::

  docker pull nimlang/nim:devel
