=========================
  nimgrep User's manual
=========================

:Author: Andreas Rumpf
:Version: 0.9


Nimgrep is a command line tool for search&replace tasks. It can search for
regex or peg patterns and can search whole directories at once. User
confirmation for every single replace operation can be requested.

Nimgrep has particularly good support for Nim's
eccentric *style insensitivity*. Apart from that it is a generic text
manipulation tool.


Installation
============

Compile nimgrep with the command::

  nim c -d:release tools/nimgrep.nim

And copy the executable somewhere in your ``$PATH``.


Command line switches
=====================

Usage:
  nimgrep [options] [pattern] [replacement] (file/directory)*
Options:
  --find, -f          find the pattern (default)
  --replace, -r       replace the pattern
  --peg               pattern is a peg
  --re                pattern is a regular expression (default); extended
                      syntax for the regular expression is always turned on
  --recursive         process directories recursively
  --confirm           confirm each occurrence/replacement; there is a chance
                      to abort any time without touching the file
  --stdin             read pattern from stdin (to avoid the shell's confusing
                      quoting rules)
  --word, -w          the match should have word boundaries (buggy for pegs!)
  --ignoreCase, -i    be case insensitive
  --ignoreStyle, -y   be style insensitive
  --ext:EX1|EX2|...   only search the files with the given extension(s)
  --verbose           be verbose: list every processed file
  --help, -h          shows this help
  --version, -v       shows the version
