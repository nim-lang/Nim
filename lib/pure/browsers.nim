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
from os import findExe
import strutils

when defined(windows):
  import winlean
else:
  import os, osproc

since (1, 3):
  type WebBrowsers* = enum          ## Web Browsers
    wbFirefox = "firefox"           ## Mozilla Firefox
    wbChrome = "google-chrome"      ## Google Chrome
    wbChromium = "chromium-browser" ## Chromium
    wbInternetExplorer = "iexplore" ## Microsoft Internet Explorer
    wbEdge = "microsoft-edge"       ## Microsoft Edge
    wbSafari = "safari"             ## Apple Safari
    wbChromiumSnapshotBin = "chromium-snapshot-bin" ## Chromium Snapshot Binary
    wbChromiumSnapshot = "chromium-snapshot"        ## Chromium Snapshot from Sources
    wbUngoogledChromium = "ungoogled-chromium"      ## Chromium Fork
    wbIceweasel = "iceweasel"       ## Mozilla Firefox Fork
    wbTorbrowser = "torbrowser"     ## Mozilla Firefox Fork https://www.torproject.org/download
    wbIcecat = "icecat"             ## Mozilla Firefox Fork
    wbIceape = "iceape"             ## Mozilla Firefox Fork
    wbSeamonkey = "seamonkey"       ## Mozilla Firefox Fork
    wbWaterfox = "waterfox"         ## Mozilla Firefox Fork https://www.waterfox.net
    wbPalemoon = "palemoon"         ## Mozilla Firefox Fork https://www.palemoon.org
    wbFalkon = "falkon"             ## KDE Falkon https://www.falkon.org
    wbKonqueror = "konqueror"       ## KDE Web Browser
    wbEpiphany = "epiphany"         ## Gnome Web Browser
    wbMidori = "midori"             ## https://astian.org/midori
    wbBrave = "brave-browser"       ## https://brave.com
    wbVivaldi = "vivaldi-browser"   ## https://vivaldi.com
    wbOpera = "opera"               ## Opera
    wbSkipstone = "skipstone"       ## GTK/Mozilla based Web Browser
    wbElinks = "elinks"             ## eLinks http://www.jikos.cz/~mikulas/links
    wbLynx = "lynx"                 ## Lynx http://lynx.browser.org
    wbW3m = "w3m"                   ## W3M http://w3m.sourceforge.net
    wbDillo = "dillo"               ## https://www.dillo.org


const osOpenCmd* =
  when defined(macos) or defined(macosx) or defined(windows): "open" else: "xdg-open" ## \
  ## Alias for the operating system specific *"open"* command,
  ## ``"open"`` on OSX, MacOS and Windows, ``"xdg-open"`` on Linux, BSD, etc.


template openDefaultBrowserImpl(url: string) =
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

proc openDefaultBrowser*(url: string) =
  ## Opens `url` with the user's default browser. This does not block.
  ## The URL must not be empty string, to open on a blank page see `openDefaultBrowser()`.
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
  openDefaultBrowserImpl(url)

proc openDefaultBrowser*() {.since: (1, 1).} =
  ## Opens the user's default browser without any `url` (blank page). This does not block.
  ## Implements IETF RFC-6694 Section 3, "about:blank" must be reserved for a blank page.
  ##
  ## Under Windows, ``ShellExecute`` is used. Under Mac OS X the ``open``
  ## command is used. Under Unix, it is checked if ``xdg-open`` exists and
  ## used if it does. Otherwise the environment variable ``BROWSER`` is
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
  openDefaultBrowserImpl("http:about:blank")  # See IETF RFC-6694 Section 3.

proc findInstalledBrowsers*(limit = 3.Positive, followSymlinks = true): set[WebBrowsers] {.inline, since: (1, 3).} =
  ## Try to find *all* installed web browsers within `PATH`, not just the default one.
  ## * if `followSymlinks` is `true` it will follow symbolic links when searching for web browsers.
  ## * `limit` is the maximum limit of *installed* web browsers to return.
  ##
  ## .. code-block:: nim
  ##   echo findInstalledBrowsers()  ## {firefox, chromium, safari}
  var i = 0
  for x in WebBrowsers:
    if i > limit: break
    if findExe($x, followSymlinks).len > 0:
      inc i
      incl result, x

proc openBrowsers*(url: string, browsers: openArray[tuple[browser: WebBrowsers, params: string]]) {.since: (1, 3).} =
  ## Open an `url` with one or more web browsers with arbitrary `params`.
  ## This does not block. The URL must not be empty string.
  ## This proc does not raise an exception on error, beware.
  ## To check for installed web browsers see `findInstalledBrowsers()`.
  ##
  ## .. code-block:: nim
  ##   openBrowsers("https://nim-lang.org", [(wbFirefox, "-new-tab"), (wbChromium, "--new-window")])
  ##   openBrowsers("http://localhost/karax-spa/index.html", [(wbFirefox, "--devtools")])
  doAssert url.len > 0, "URL must not be empty string"
  assert browsers.len > 0
  for x in browsers:
    when defined(windows):
      var o = newWideCString($x.browser & " " & x.params)
      var u = newWideCString(url)
      discard shellExecuteW(0'i32, o, u, nil, nil, SW_SHOWNORMAL)
    else:
      discard execShellCmd($x.browser & " " & quoteShell(x.params) & " " & quoteShell(url))
