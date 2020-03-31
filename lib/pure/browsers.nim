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

import strutils

when defined(windows):
  import winlean
else:
  import os, osproc

const osOpenCmd* =
  when defined(macos) or defined(windows): "open" else: "xdg-open" ## \
  ## Alias for the operating system specific *"open"* command,
  ## ``"open"`` on MacOS and Windows, ``"xdg-open"`` on Linux, BSD, etc.

proc openDefaultBrowser*(url: string) =
  ## Opens `url` with the user's default browser. This does not block.
  ## The URL must not be empty string.
  ##
  ## Under Windows, ``ShellExecute`` is used. Under Mac OS X the ``open``
  ## command is used. Under Unix, it is checked if ``xdg-open`` exists and
  ## used if it does. Otherwise the environment variable ``BROWSER`` is
  ## used to determine the default browser to use.
  ##
  ## This proc doesn't raise an exception on error, beware.
  ##
  ## .. code-block:: nim
  ##   block: openDefaultBrowser("https://nim-lang.org")
  doAssert url.len > 0, "URL must not be empty string"
  when defined(windows):
    var o = newWideCString(osOpenCmd)
    var u = newWideCString(url)
    discard shellExecuteW(0'i32, o, u, nil, nil, SW_SHOWNORMAL)
  elif defined(macosx):
    discard execShellCmd(osOpenCmd & " " & quoteShell(url))
  else:
    var u = quoteShell(url)
    if execShellCmd(osOpenCmd & " " & u) == 0: return
    for b in getEnv("BROWSER").string.split(PathSep):
      try:
        # we use ``startProcess`` here because we don't want to block!
        discard startProcess(command = b, args = [url], options = {poUsePath})
        return
      except OSError:
        discard
