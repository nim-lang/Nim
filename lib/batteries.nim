#
#
#            Nim's Runtime Library
#        (c) Copyright 2012 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## This is a module that simply imports common modules for your convenience:
##
## .. code-block:: nim
##   import batteries
##
## Same as:
##
## .. code-block:: nim
##   import os, strutils, times, parseutils, parseopt, hashes, tables, sets,
##     sugar, options, strformat, strscans, algorithm, math, sequtils
##
## This module is similar to the `prelude module <prelude.html>` which it
## deprecates.
## The main differences with prelude are that this module must be imported
## (while prelude had to be included), and that it imports a few more modules
## than prelude did.
## 
## Importing this module never triggers a UnusedImport warning, even if you
## don't use any if the modules it imports.

# Mark this module as used to avoid getting apparently "random" UnusedImport
# errors in the unlikely event that none of these modules is used
{.used.}

import std/[os, strutils, times, parseutils, parseopt, hashes, tables, sets,
  sugar, options, strformat, strscans, algorithm, math, sequtils]

export os, strutils, times, parseutils, parseopt, hashes, tables, sets,
  sugar, options, strformat, strscans, algorithm, math, sequtils
