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

Options for filtering can be provided multiple times so they form a list,
which works as:
* logical OR for positive filters:
  `--includeFile`, `--includeDir`, `--includeContext`,
  accepts if *any* pattern from the list is hit
* logical AND for negative filters:
  `--excludeFile`, `--excludeDir`, `--excludeContext`,
  accepts if *no* pattern from the list is hit.
  So patterns are effectively related by OR (`|`:literal:) also:
  `(NOT PAT1) AND (NOT PAT2) == NOT (PAT1|PAT2)`:literal: in pseudo-code.

That means you can always use only 1 such an option with logical OR, e.g.
`--excludeDir:PAT1 --excludeDir:PAT2` is fully equivalent to
`--excludeDir:'PAT1|PAT2'`.
If you want logical AND on patterns you should compose 1 appropriate pattern,
possibly combined with multi-line mode `(?s)`:literal:.
E.g. to require that multi-line context of matches has occurences of
**both** PAT1 and PAT2 use positive lookaheads (`(?=PAT)`:literal:):

.. code:: cmd
  nimgrep --includeContext:'(?s)(?=.*PAT1)(?=.*PAT2)'

Meaning of `^`:literal: and `$`:literal:
========================================

`nimgrep`:cmd: PCRE engine is run in a single-line mode so
`^`:literal: matches the beginning of whole input *file* and
`$`:literal: matches the end of *file* (or whole input *string* for
options like `--includeFile`).

Add the `(?m)`:literal: modifier to the beginning of your pattern for
`^`:literal: and `$`:literal: to match the beginnings and ends of *lines*.

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

+ To search only in paths containing the `tests`:literal: sub-directory
  recursively:

  .. code:: cmd
    nimgrep --recursive --includeDir:'(^|/)tests($|/)'
    # short: -r --id:'(^|/)tests($|/)'

  .. Attention:: note the subtle difference between `--excludeDir`:option: and
    `--includeDir`:option:\: the former is applied to relative directory entries
    and the latter is applied to the whole paths

+ Nimgrep can search multi-line, e.g. to find files containing `import`:literal:
  and then `strutils`:literal: use pattern `'import(.|\n)*?strutils'`:literal:.

