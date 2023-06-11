#
#
#            Nim's Runtime Library
#        (c) Copyright 2012 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## This module implements a simple proc for opening URLs with the user's
## default browser.
##
## Unstable API.

import std/private/since

import strutils

when defined(windows):
  import winlean
  from os import absolutePath
else:
  import os
  when not defined(osx):
    import osproc

const osOpenCmd* =
  when defined(macos) or defined(macosx) or defined(windows): "open" else: "xdg-open" ## \
  ## Alias for the operating system specific *"open"* command,
  ## `"open"` on OSX, MacOS and Windows, `"xdg-open"` on Linux, BSD, etc.

proc prepare(s: string): string =
  if s.contains("://"):
    result = s
  else:
    result = "file://" & absolutePath(s)

proc openDefaultBrowserImplPrep(url: string) =
  ## note the url argument should be alreadly prepared, i.e. the url is passed "AS IS"

  when defined(windows):
    var o = newWideCString(osOpenCmd)
    var u = newWideCString(url)
    discard shellExecuteW(0'i32, o, u, nil, nil, SW_SHOWNORMAL)
  elif defined(macosx):
    discard execShellCmd(osOpenCmd & " " & quoteShell(url))
  else:
    var u = quoteShell(url)
    if execShellCmd(osOpenCmd & " " & u) == 0: return
    for b in getEnv("BROWSER").split(PathSep):
      try:
        # we use `startProcess` here because we don't want to block!
        discard startProcess(command = b, args = [url], options = {poUsePath})
        return
      except OSError:
        discard

proc openDefaultBrowserImpl(url: string) =
  openDefaultBrowserImplPrep(prepare url)

proc openDefaultBrowser*(url: string) =
  ## Opens `url` with the user's default browser. This does not block.
  ## The URL must not be empty string, to open on a blank page see `openDefaultBrowser()`.
  ##
  ## Under Windows, `ShellExecute` is used. Under Mac OS X the `open`
  ## command is used. Under Unix, it is checked if `xdg-open` exists and
  ## used if it does. Otherwise the environment variable `BROWSER` is
  ## used to determine the default browser to use.
  ##
  ## This proc doesn't raise an exception on error, beware.
  ##
  ## .. code-block:: nim
  ##   block: openDefaultBrowser("https://nim-lang.org")
  doAssert url.len > 0, "URL must not be empty string"
  openDefaultBrowserImpl(url)

proc openDefaultBrowser*() {.since: (1, 1).} =
  ## Opens the user's default browser without any `url` (blank page). This does not block.
  ## Implements IETF RFC-6694 Section 3, "about:blank" must be reserved for a blank page.
  ##
  ## Under Windows, `ShellExecute` is used. Under Mac OS X the `open`
  ## command is used. Under Unix, it is checked if `xdg-open` exists and
  ## used if it does. Otherwise the environment variable `BROWSER` is
  ## used to determine the default browser to use.
  ##
  ## This proc doesn't raise an exception on error, beware.
  ##
  ## **See also:**
  ##
  ## * https://tools.ietf.org/html/rfc6694#section-3
  ##
  ## .. code-block:: nim
  ##   block: openDefaultBrowser()
  openDefaultBrowserImplPrep("about:blank")   # See IETF RFC-6694 Section 3.
