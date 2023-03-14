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

  ```cmd
  nim c -d:release tools/nimgrep.nim
  ```

And copy the executable somewhere in your ``$PATH``.


Command line switches
=====================

.. include:: nimgrep_cmdline.txt

Path filter options
-------------------

Let us assume we have file `dirA/dirB/dirC/file.nim`.
Filesystem path options will match for these parts of the path:

| option              | matches for                        |
| :------------------ | :--------------------------------  |
| `--[not]extensions` | ``nim``                            |
| `--[not]filename`   | ``file.nim``                       |
| `--[not]dirname`    | ``dirA`` and ``dirB`` and ``dirC`` |
| `--[not]dirpath`    | ``dirA/dirB/dirC``                 |

Combining multiple filter options together and negating them
------------------------------------------------------------

Options for filtering can be provided multiple times so they form a list,
which works as:
* positive filters
  `--filename`, `--dirname`, `--dirpath`, `--inContext`,
  `--inFile` accept files/matches if *any* pattern from the list is hit
* negative filters
  `--notfilename`, `--notdirname`, `--notdirpath`, `--notinContext`,
  `--notinFile` accept files/matches if *no* pattern from the list is hit.

In other words the same filtering option repeated many times means logical OR.

.. Important::
  Different filtering options are related by logical AND: they all must
  be true for a match to be accepted.
  E.g. `--filename:F --dirname:D1 --notdirname:D2` means
  `filename(F) AND dirname(D1) AND (NOT dirname(D2))`.

So negative filtering patterns are effectively related by logical OR also:
`(NOT PAT1) AND (NOT PAT2) == NOT (PAT1 OR PAT2)`:literal: in pseudo-code.

That means you can always use only 1 such an option with logical OR, e.g.
`--notdirname:PAT1 --notdirname:PAT2` is fully equivalent to
`--notdirname:'PAT1|PAT2'`.

.. Note::
   If you want logical AND on patterns you should compose 1 appropriate pattern,
   possibly combined with multi-line mode `(?s)`:literal:.
   E.g. to require that multi-line context of matches has occurrences of
   **both** PAT1 and PAT2 use positive lookaheads (`(?=PAT)`:literal:):
     ```cmd
     nimgrep --inContext:'(?s)(?=.*PAT1)(?=.*PAT2)'
     ```

Meaning of `^`:literal: and `$`:literal:
========================================

`nimgrep`:cmd: PCRE engine is run in a single-line mode so
`^`:literal: matches the beginning of whole input *file* and
`$`:literal: matches the end of *file* (or whole input *string* for
options like `--filename`).

Add the `(?m)`:literal: modifier to the beginning of your pattern for
`^`:literal: and `$`:literal: to match the beginnings and ends of *lines*.

Examples
========

All examples below use default PCRE Regex patterns:

+ To search recursively in Nim files using style-insensitive identifiers:

    ```cmd
    nimgrep --recursive --ext:'nim|nims' --ignoreStyle
    # short: -r --ext:'nim|nims' -y
    ```

  .. Note:: we used `'` quotes to avoid special treatment of `|` symbol
    for shells like Bash

+ To exclude version control directories (Git, Mercurial=hg, Subversion=svn)
  from the search:
    ```cmd
    nimgrep --notdirname:'^\.git$' --notdirname:'^\.hg$' --notdirname:'^\.svn$'
    # short: --ndi:'^\.git$' --ndi:'^\.hg$' --ndi:'^\.svn$'
    ```
+ To search only in paths containing the `tests`:literal: sub-directory
  recursively:
    ```cmd
    nimgrep --recursive --dirname:'^tests$'
    # short: -r --di:'^tests$'
    # or using --dirpath:
    nimgrep --recursive --dirpath:'(^|/)tests($|/)'
    # short: -r --pa:'(^|/)tests($|/)'
    ```
+ Nimgrep can search multi-line, e.g. to find files containing `import`:literal:
  and then `strutils`:literal: use pattern `'import(.|\n)*?strutils'`:literal:.
