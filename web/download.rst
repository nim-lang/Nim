Download the compiler
=====================

You can download the latest version of the Nim compiler here.

Windows
-------

Zips
%%%%

We now encourage you to install via the provided zipfiles:

* | 32 bit: `nim-0.16.0_x32.zip <download/nim-0.16.0_x32.zip>`_
  | SHA-256  69af94a6875a02543c1bf0fa03c665f126f8500a2c0e226c32571e64c6842e57
* | 64 bit: `nim-0.16.0_x64.zip <download/nim-0.16.0_x64.zip>`_
  | SHA-256  e667cdad1ae8e9429147aea5031fa8a80c4ccef6d274cec0e9480252d9c3168c

Unzip these where you want and **optionally** run ``finish.exe`` to
detect your MingW environment. (Though that's not reliable yet.)

You can find the required DLLs here, if you lack them for some reason:

* | 32 and 64 bit: `DLLs.zip <download/dlls.zip>`_
  | SHA-256  198112d3d6dc74d7964ba452158d44bfa57adef4dc47be8c39903f2a24e4a555


Exes
%%%%

You can download an installer for both 32 bit and 64 bit versions of
Windows below. Note that these installers have some known issues and
so will unlikely to be provided further in the future. These
installers have everything you need to use Nim, including a C compiler.

* | 32 bit: `nim-0.16.0_x32.exe <download/nim-0.16.0_x32.exe>`_
  | SHA-256  37c55d9f9b3a2947559901c8bbd10b6a16191b562ca2bebdc145a6c24f5d004e
* | 64 bit: `nim-0.16.0_x64.exe <download/nim-0.16.0_x64.exe>`_
  | SHA-256  13934282b01cbcaf7ad7aecb67e954dd0ea2b576c6c8102016cb9a9a30cce744

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

* | `nim-0.16.0.tar.xz (2.9MB) <download/nim-0.16.0.tar.xz>`_
  | SHA-256  9e199823be47cba55e62dd6982f02cf0aad732f369799fec42a4d8c2265c5167

Extract the archive. Then copy the extracted files into your chosen installation
directory, ideally somewhere in your home directory.
For example: ``~/programs/nim``.

Now open a terminal and follow these instructions:

* ``cd`` into your installation directory, for example by executing
``cd ~/programs/nim``.
* run ``sh build.sh``.
* Add ``$your_install_dir/bin`` to your PATH.
* To build associated tools like ``nimble`` and ``nimsuggest`` run ``nim c koch && ./koch tools``.

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
