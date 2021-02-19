#
#
#            Nim's Runtime Library
#        (c) Copyright 2012 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

from std/compileSettings import nil

when isMainModule and compileSettings.querySetting(compileSettings.SingleValueSetting.projectFull) == currentSourcePath:
  ## This is an include file that simply imports common modules for your convenience.
  runnableExamples:
    include std/prelude
    # same as:
    # import std/[os, strutils, times, parseutils, hashes, tables, sets, sequtils, parseopt]
    when not defined js:
      let t = now()
      assert getCurrentDir().len > 0
      assert now() > t
    let x = 1
    assert "foo $# $#" % [$x, "bar"] == "foo 1 bar"
    assert toSeq(1..3) == @[1, 2, 3]

import std/[os, strutils, times, parseutils, hashes, tables, sets, sequtils, parseopt]
