Version 0.15.2 released
=======================

.. container:: metadata

  Posted by Andreas Rumpf on 23/10/2016

We're happy to announce that the latest release of Nim, version 0.15.2, is now
available!

As always, you can grab the latest version from the
`downloads page <http://nim-lang.org/download.html>`_.

This release is a pure bugfix release fixing the most pressing issues and
regressions of 0.15.0. For Windows we now provide zipfiles in addition to the
NSIS based installer which proves to be hard to maintain and after all these
months still has serious issues. So we encourage you download the .zip
file instead of the .exe file! Unzip it somewhere, run ``finish.exe`` to
detect your MingW installation, done. ``finish.exe`` can also set your PATH
environment variable.


Bugfixes
--------

The list below has been generated based on the commits in Nim's git
repository. As such it lists only the issues which have been closed
via a commit, for a full list see
`this link on Github <https://github.com/nim-lang/Nim/issues?utf8=%E2%9C%93&q=is%3Aissue+closed%3A%222016-09-30+..+2016-10-23%22+>`_.


- Fixed "`NimMain` not exported in DLL, but `NimMainInner` is"
  (`#4840 <https://github.com/nim-lang/Nim/issues/4840>`_)
- Fixed "Tables clear seems to be broken"
  (`#4844 <https://github.com/nim-lang/Nim/issues/4844>`_)
- Fixed "compiler: internal error"
  (`#4845 <https://github.com/nim-lang/Nim/issues/4845>`_)
- Fixed "trivial macro breaks type checking in the compiler"
  (`#4608 <https://github.com/nim-lang/Nim/issues/4608>`_)
- Fixed "derived generic types with static[T] breaks type checking in v0.15.0 (worked in v0.14.2)"
  (`#4863 <https://github.com/nim-lang/Nim/issues/4863>`_)
- Fixed "xmlparser.parseXml is not recognised as GC-safe"
  (`#4899 <https://github.com/nim-lang/Nim/issues/4899>`_)
- Fixed "async makes generics instantiate only once"
  (`#4856 <https://github.com/nim-lang/Nim/issues/4856>`_)
- Fixed "db_common docs aren't generated"
  (`#4895 <https://github.com/nim-lang/Nim/issues/4895>`_)
- Fixed "rdstdin  disappeared from documentation index"
  (`#3755 <https://github.com/nim-lang/Nim/issues/3755>`_)
- Fixed "ICE on template call resolution"
  (`#4875 <https://github.com/nim-lang/Nim/issues/4875>`_)
- Fixed "Invisible code-block"
  (`#3078 <https://github.com/nim-lang/Nim/issues/3078>`_)
- Fixed "nim doc does not generate doc comments correctly"
  (`#4913 <https://github.com/nim-lang/Nim/issues/4913>`_)
- Fixed "nim doc2 fails on ARM when running against lib/pure/coro.nim"
  (`#4879 <https://github.com/nim-lang/Nim/issues/4879>`_)
- Fixed "xmlparser does not unescape correctly"
  (`#1518 <https://github.com/nim-lang/Nim/issues/1518>`_)
- Fixed "[docs] mysterious "raise hook""
  (`#3485 <https://github.com/nim-lang/Nim/issues/3485>`_)
- Fixed "assertion failure in non-release Nim when compiling NimYAML"
  (`#4869 <https://github.com/nim-lang/Nim/issues/4869>`_)
- Fixed "A closure causes nimscript to fail with unhandled exception"
  (`#4906 <https://github.com/nim-lang/Nim/issues/4906>`_)
- Fixed "startProcess changes working directory"
  (`#4867 <https://github.com/nim-lang/Nim/issues/4867>`_)
- Fixed "bindsym to void template produces ICE"
  (`#4808 <https://github.com/nim-lang/Nim/issues/4808>`_)
- Fixed "readline(TFile, var string) segfaults if second argument is nil"
  (`#564 <https://github.com/nim-lang/Nim/issues/564>`_)
- Fixed "times.parse gives the wrong day of the week for the first hour of the day."
  (`#4922 <https://github.com/nim-lang/Nim/issues/4922>`_)
- Fixed "Internal error when passing parameter proc inside .gcsafe closure"
  (`#4927 <https://github.com/nim-lang/Nim/issues/4927>`_)
- Fixed "Upcoming asyncdispatch doesn't compile with C++ backend on OS X"
  (`#4928 <https://github.com/nim-lang/Nim/issues/4928>`_)
