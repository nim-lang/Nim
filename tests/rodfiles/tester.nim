#
#
#            Nimrod Tester
#        (c) Copyright 2011 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## This program tests Nimrod's ROD file mechanism.

import
  parseutils, strutils, pegs, os, osproc, streams, parsecfg, browsers, json,
  marshal, cgi

const
  cmdTemplate = r"nimrod cc --hints:on $# $#"
  resultsFile = "testresults.html"
  jsonFile = "testresults.json"
  Usage = "usage: tester reject|compile|examples|run|merge [nimrod options]"

proc myExec(cmd: string): string =
  result = osproc.execProcess(cmd)

var
  pegLineError = peg"{[^(]*} '(' {\d+} ', ' \d+ ') Error:' \s* {.*}"
  pegOtherError = peg"'Error:' \s* {.*}"
  pegSuccess = peg"'Hint: operation successful'.*"
  pegOfInterest = pegLineError / pegOtherError / pegSuccess

