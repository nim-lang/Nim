=========================
  nimgrep User's manual
=========================

:Author: Andreas Rumpf
:Version: 1.6.0

.. default-role:: option
.. contents::

Nimgrep is a command line tool for search and replace tasks. It can search for
regex or peg patterns and can search whole directories at once. User
confirmation for every single replace operation can be requested.

Nimgrep has particularly good support for Nim's
eccentric *style insensitivity* (see option `-y` below).
Apart from that it is a generic text manipulation tool.


Installation
============

Compile nimgrep with the command:

.. code:: cmd
  nim c -d:release tools/nimgrep.nim

And copy the executable somewhere in your ``$PATH``.


Command line switches
=====================

.. include:: nimgrep_cmdline.txt

Examples
========

All examples below use default PCRE Regex patterns:

+ To search recursively in Nim files using style-insensitive identifiers:

  .. code:: cmd
    nimgrep --recursive --ext:'nim|nims' --ignoreStyle
    # short: -r --ext:'nim|nims' -y

  .. Note:: we used `'` quotes to avoid special treatment of `|` symbol
    for shells like Bash

+ To exclude version control directories (Git, Mercurial=hg, Subversion=svn)
  from the search:

  .. code:: cmd
    nimgrep --excludeDir:'^\.git$' --excludeDir:'^\.hg$' --excludeDir:'^\.svn$'
    # short: --ed:'^\.git$' --ed:'^\.hg$' --ed:'^\.svn$'

+ To search only in paths containing the `tests` sub-directory recursively::

  .. code:: cmd
    nimgrep --recursive --includeDir:'(^|/)tests($|/)'
    # short: -r --id:'(^|/)tests($|/)'

  .. Attention:: note the subtle difference between `--excludeDir`:option: and
    `--includeDir`:option:\: the former is applied to relative directory entries
    and the latter is applied to the whole paths

+ Nimgrep can search multi-line, e.g. to find files containing `import`
  and then `strutils` use pattern `'import(.|\n)*?strutils'`:option:.

