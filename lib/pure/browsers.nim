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

import strutils

when defined(windows):
  import winlean
else:
  import os, osproc

proc openDefaultBrowser*(url: string) =
  ## opens `url` with the user's default browser. This does not block.
  ##
  ## Under Windows, ``ShellExecute`` is used. Under Mac OS X the ``open``
  ## command is used. Under Unix, it is checked if ``gnome-open`` exists and
  ## used if it does. Next attempt is ``kde-open``, then ``xdg-open``.
  ## Otherwise the environment variable ``BROWSER`` is used to determine the
  ## default browser to use.
  when defined(windows):
    when useWinUnicode:
      var o = newWideCString("open")
      var u = newWideCString(url)
      discard shellExecuteW(0'i32, o, u, nil, nil, SW_SHOWNORMAL)
    else:
      discard shellExecuteA(0'i32, "open", url, nil, nil, SW_SHOWNORMAL)
  elif defined(macosx):
    discard execShellCmd("open " & quoteShell(url))
  else:
    const attempts = ["gnome-open ", "kde-open ", "xdg-open "]
    var u = quoteShell(url)
    for a in items(attempts):
      if execShellCmd(a & u) == 0: return
    for b in getEnv("BROWSER").string.split(PathSep):
      try:
        # we use ``startProcess`` here because we don't want to block!
        discard startProcess(command=b, args=[url], options={poUsePath})
        return
      except OSError:
        discard
