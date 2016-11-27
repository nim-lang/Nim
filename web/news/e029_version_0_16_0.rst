Version 0.16.0 released
=======================

.. container:: metadata

  Posted by xyz on dd/mm/yyyy

We're happy to announce that the latest release of Nim, version 0.16.0, is now
available!

As always, you can grab the latest version from the
`downloads page <http://nim-lang.org/download.html>`_.

This release includes almost xyz bug fixes and improvements. To see a full list
of changes, take a look at the detailed changelog
`below <#changelog>`_.

Some of the most significant changes in this release include: xyz


Changelog
~~~~~~~~~

Changes affecting backwards compatibility
-----------------------------------------

- ``staticExec`` now uses the directory of the nim file that contains the
  ``staticExec`` call as the current working directory.
- ``TimeInfo.tzname`` has been removed from ``times`` module because it was
  broken. Because of this, the option ``"ZZZ"`` will no longer work in format
  strings for formatting and parsing.

Library Additions
-----------------

- Added new parameter to ``error`` proc of ``macro`` module to provide better
  error message

- Added ``hideCursor`` and ``showCursor`` to the ``terminal``
  `(doc) <http://nim-lang.org/docs/terminal.html>`_ module.


Tool Additions
--------------


Compiler Additions
------------------


Language Additions
------------------


Bugfixes
--------

The list below has been generated based on the commits in Nim's git
repository. As such it lists only the issues which have been closed
via a commit, for a full list see
`this link on Github <https://github.com/nim-lang/Nim/issues?utf8=%E2%9C%93&q=is%3Aissue+closed%3A%222016-06-22+..+2016-09-30%22+>`_.
