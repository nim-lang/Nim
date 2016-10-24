Download the compiler
=====================

You can download the latest version of the Nim compiler here.

Windows
-------

Zips
%%%%

We now encourage you to install via the provided zipfiles:

* | 32 bit: `nim-0.15.2_x32.zip <download/nim-0.15.2_x32.zip>`_
  | SHA-256  0f1bfb74751f55e090140a361c08e9f39f1dd03f1f0c070c061f2d5049ab9f96
* | 64 bit: `nim-0.15.2_x64.zip <download/nim-0.15.2_x64.zip>`_
  | SHA-256  ceea42de6ebcd41032ee51f04526dc4cf2cbb0958ca6ad2321cf21944e05f553

Unzip these where you want and optionally run ``finish.exe`` to
detect your MingW environment.

Exes
%%%%

You can download an installer for both 32 bit and 64 bit versions of
Windows below. Note that these installers have some known issues and
so will unlikely to be provided further in the future. These
installers have everything you need to use Nim, including a C compiler.

* | 32 bit: `nim-0.15.2_x32.exe <download/nim-0.15.2_x32.exe>`_
  | SHA-256  8d648295dbd59cb315c98926a1da9f1f68773a1a2ef3d9d4c91c59387167efa3
* | 64 bit: `nim-0.15.2_x64.exe <download/nim-0.15.2_x64.exe>`_
  | SHA-256  8c7efc6571921c2d2e5e995f801d4229ea1de19fbdabdcba1628307bd4612392

These installers also include Aporia, Nimble and other useful Nim tools to get
you started with Nim development!

Installation based on generated C code
--------------------------------------

**Note:** The Nim compiler requires a C compiler to compile software. On
Windows we recommend that you use
`Mingw-w64 <http://mingw-w64.sourceforge.net/>`_. GCC is recommended on Linux
and Clang on Mac. The Windows installers above already includes a C compiler.

This installation method is the preferred way for Linux, Mac OS X, and other Unix
like systems.

Firstly, download this archive:

* | `nim-0.15.2.tar.xz (4.5MB) <download/nim-0.15.2.tar.xz>`_
  | SHA-256  905df2316262aa2cbacae067acf45fc05c2a71c8c6fde1f2a70c927ebafcfe8a

Extract the archive. Then copy the extracted files into your chosen installation
directory, ideally somewhere in your home directory.
For example: ``~/programs/nim``.

Now open a terminal and follow these instructions:

* ``cd`` into your installation directory, for example by executing
``cd ~/programs/nim``.
* run ``sh build.sh``.
* Add ``$your_install_dir/bin`` to your PATH.
* To build associated tools like ``nimble`` and ``nimsuggest`` run ``nim c koch && koch tools``.

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

  git clone https://github.com/nim-lang/Nim.git
  cd Nim
  git clone --depth 1 https://github.com/nim-lang/csources
  cd csources && sh build.sh
  cd ..
  bin/nim c koch
  ./koch boot -d:release
  koch tools

You should then add the ``./bin`` (make sure to expand this into an
absolute path) directory to your ``PATH``.


Docker Hub
----------

The `official Docker images <https://hub.docker.com/r/nimlang/nim/>`_
are published on Docker Hub and include the compiler and Nimble. There are images
for standalone scripts as well as Nimble packages.

Get the latest stable image::

  docker pull nimlang/nim

The latest development version::

  docker pull nimlang/nim:devel
