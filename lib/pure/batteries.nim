#
#
#            Nim's Runtime Library
#        (c) Copyright 2012 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

when defined(nimdoc) and isMainModule:
  from std/compileSettings import nil
  when compileSettings.querySetting(compileSettings.SingleValueSetting.projectFull) == currentSourcePath:
    ## This is a module that imports commonly used modules for your convenience:
    ##
    ## ```nim
    ##   import batteries
    ## ```
    ##
    ## Same as:
    ##
    ## ```nim
    ##   import std/[os, strutils, times, parseutils, hashes, tables, sets,
    ##     sequtils, parseopt, strformat, sugar, options, strscans, algorithm,
    ##     math]
    ## ```
    ##
    ## This module is similar to the `prelude module <prelude.html>` which it
    ## deprecates.
    ## The differences with prelude are that this module should be imported
    ## (while prelude had to be included), and that it imports a few more modules
    ## than prelude.
    ## 
    ## Importing this module never triggers a UnusedImport warning, even if you
    ## don't use any if the modules it imports.
    runnableExamples:
      import std/batteries
        # same as:
        # import std/[os, strutils, times, parseutils, hashes, tables, sets,
        #   sequtils, parseopt, strformat, sugar, options, strscans, algorithm,
        #   math]
      let x = 1
      assert "foo $# $#" % [$x, "bar"] == "foo 1 bar"
      assert toSeq(1..3) == @[1, 2, 3]
      when not defined(js) or defined(nodejs):
        assert getCurrentDir().len > 0
        assert ($now()).startsWith "20"

  # xxx `nim doc -b:js -d:nodejs --doccmd:-d:nodejs lib/pure/batteries.nim` fails for some reason
  # specific to `nim doc`, but the code otherwise works with nodejs.

# Mark this module as used to avoid getting apparently "random" UnusedImport
# errors in the unlikely event that none of these modules is used
{.used.}

import std/[os, strutils, times, parseutils, hashes, tables, sets, sequtils,
  parseopt, strformat, sugar, options, strscans, algorithm, math]

export os, strutils, times, parseutils, hashes, tables, sets, sequtils,
  parseopt, strformat, sugar, options, strscans, algorithm, math
