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
  when defined(nimPreviewSlimSystem):
    import std/widestrs
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

proc openDefaultBrowserRaw(url: string) =
  ## Opens `url` with the user's default browser. This does not block.
  ## **NOTE**: the url argument is passed "AS IS", assuming it's a valid URL
  ##
  ## Under Windows, `ShellExecute` is used. Under Mac OS X the `open`
  ## command is used. Under Unix, it is checked if `xdg-open` exists and
  ## used if it does. Otherwise the environment variable `BROWSER` is
  ## used to determine the default browser to use.
  ##
  ## This proc doesn't raise an exception on error, beware.
  ##
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

proc openDefaultBrowser*() {.since: (1, 1).} =
  ## Opens the user's default browser without any `url` (default page). This does not block.
  ##
  ## Under Windows, `ShellExecute` is used. Under Mac OS X the `open`
  ## command is used. Under Unix, it is checked if `xdg-open` exists and
  ## used if it does. Otherwise the environment variable `BROWSER` is
  ## used to determine the default browser to use.
  ##
  ## This proc doesn't raise an exception on error, beware.
  ##
  ##   ```nim
  ##   block: openDefaultBrowser()
  ##   ```
  openDefaultBrowserRaw("http://")

proc openDefaultBrowser*(url: string) =
  ## Opens `url` with the user's default browser. This does not block.
  ## if URL is an empty string, it'll call `openDefaultBrowser()` and open a default page.
  ##
  ## Under Windows, `ShellExecute` is used. Under Mac OS X the `open`
  ## command is used. Under Unix, it is checked if `xdg-open` exists and
  ## used if it does. Otherwise the environment variable `BROWSER` is
  ## used to determine the default browser to use.
  ##
  ## This proc doesn't raise an exception on error, beware.
  ##
  ##   ```nim
  ##   block: 
  ##     # the following two are equivalent
  ##     openDefaultBrowser("https://nim-lang.org")
  ##     openDefaultBrowser("nim-lang.org")
  ##   ```
  if url.len == 0:
    openDefaultBrowser()
  else: 
    openDefaultBrowserRaw(prepare url)

