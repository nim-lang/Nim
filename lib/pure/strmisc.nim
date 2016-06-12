#
#
#            Nim's Runtime Library
#        (c) Copyright 2016 Joey Payne
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## This module contains various string utility routines that are uncommonly
## used in comparison to `strutils <strutils.html>`_.

import strutils

{.deadCodeElim: on.}

proc partition*(s: string, sep: string,
                right: bool = false): (string, string, string)
                {.noSideEffect, procvar.} =
  ## Split the string at the first or last occurrence of `sep` into a 3-tuple
  ##
  ## Returns a 3 string tuple of (beforeSep, `sep`, afterSep) or
  ## (`s`, "", "") if `sep` is not found and `right` is false or
  ## ("", "", `s`) if `sep` is not found and `right` is true

  let position = if right: s.rfind(sep) else: s.find(sep)

  if position != -1:
    let
      beforeSep = s[0 ..< position]
      afterSep = s[position + sep.len ..< s.len]

    return (beforeSep, sep, afterSep)

  return if right: ("", "", s) else: (s, "", "")

proc rpartition*(s: string, sep: string): (string, string, string)
                {.noSideEffect, procvar.} =
  ## Split the string at the last occurrence of `sep` into a 3-tuple
  ##
  ## Returns a 3 string tuple of (beforeSep, `sep`, afterSep) or
  ## ("", "", `s`) if `sep` is not found
  return partition(s, sep, right = true)

when isMainModule:
  doAssert partition("foo:bar", ":") == ("foo", ":", "bar")
  doAssert partition("foobarbar", "bar") == ("foo", "bar", "bar")
  doAssert partition("foobarbar", "bank") == ("foobarbar", "", "")
  doAssert partition("foobarbar", "foo") == ("", "foo", "barbar")
  doAssert partition("foofoobar", "bar") == ("foofoo", "bar", "")

  doAssert rpartition("foo:bar", ":") == ("foo", ":", "bar")
  doAssert rpartition("foobarbar", "bar") == ("foobar", "bar", "")
  doAssert rpartition("foobarbar", "bank") == ("", "", "foobarbar")
  doAssert rpartition("foobarbar", "foo") == ("", "foo", "barbar")
  doAssert rpartition("foofoobar", "bar") == ("foofoo", "bar", "")
