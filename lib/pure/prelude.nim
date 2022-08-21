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
    ## This is an include file that simply imports common modules for your convenience.
    runnableExamples:
      include std/prelude
        # same as:
        # import std/[os, strutils, times, parseutils, hashes, tables, sets, sequtils, parseopt]
      let x = 1
      assert "foo $# $#" % [$x, "bar"] == "foo 1 bar"
      assert toSeq(1..3) == @[1, 2, 3]
      when not defined(js) or defined(nodejs):
        assert getCurrentDir().len > 0
        assert ($now()).startsWith "20"

  # xxx `nim doc -b:js -d:nodejs --doccmd:-d:nodejs lib/pure/prelude.nim` fails for some reason
  # specific to `nim doc`, but the code otherwise works with nodejs.

import std/[os, strutils, times, parseutils, hashes, tables, sets, sequtils, parseopt, strformat]
