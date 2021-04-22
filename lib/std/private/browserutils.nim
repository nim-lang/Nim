##[
Experimental API, subject to change
]##

#[
TODO:

## scratch
# let dir = getTempDir() / "D20210227T155249" # PRTEMP mkstmp ?
# fileHtml = getHtmlFile(nimcacheDir.querySetting, fileJs)
]#

from std/browsers import openDefaultBrowser
import std/os
import std/strformat
from std/strutils import `%`
import std/compilesettings

proc buildHtml(inner: string): string =
  fmt"""
<!DOCTYPE html>
<html>
<head>
  <title>NimBrowserTest</title>
</head>
{inner}
<body>
</body>
</html>
"""
<html>
<head>
<title>Nim</title>
</head>

# proc serveJsBrowser*(fileJs: string, port: int) =
proc serveJsBrowser*(fileJs: string) =
  let port = 7031 # PRTEMP
  let jsname = "input.js"
  let html = buildHtml(fmt"""<script src="{jsname}"></script>""")
  let dir = getTempDir() / "D20210227T155249" # PRTEMP mkstmp ?
  createDir(dir)
  let fileHtml = dir / "index.html"
  let fileJs2 = dir / jsname
  writeFile(fileHtml, html)
  removeFile(fileJs2)
  createSymlink(fileJs, fileJs2)
  echo (fileHtml,)
  let url = fmt"http://localhost:{port}/"
  # python3 -m http.server 7031 --directory /tmp/d06/
  openDefaultBrowser(fileHtml)
  let status = execShellCmd(fmt"python3 -m http.server {port} --directory {dir.quoteShell}")
  doAssert status == 0

proc getHtmlFile*(dir: string, file: string): string =
  dir / "htmljs" / file.splitFile.name.changeFileExt(".html")

const portOff = -1

proc helpMsg*(file: string, port: int): string =
  &"install livereload with: `npm install -g livereload`\nand then run once: `livereload {file.quoteShell} -p {port}`"

proc livereloadString*(port: int): string =
  # TOOD: infer domain etc
  if port != portOff:
    result = fmt"""<script src="http://localhost:{port}/livereload.js"></script>"""

proc serveJsBrowserLivereload*(fileJs: string, fileHtml = "", port = portOff) =
  ##[
  [livereload-js - npm](https://www.npmjs.com/package/livereload-js)
  ]##

  let content = fileJs.readFile
  var extra = livereloadString(port)
  let html = buildHtml(fmt"""
{extra}
<script>
{content}
</script>
""")
  var fileHtml = fileHtml
  if fileHtml.len == 0:
    when (NimMajor, NimMinor, NimPatch) >= (1, 5, 1):
      fileHtml = getHtmlFile(querySetting(nimcacheDir), fileJs)
    else:
      doAssert false
  createDir(fileHtml.parentDir)
  writeFile(fileHtml, html)
  if port != portOff:
    # echo fmt"writing to: {fileHtml.quoteShell}"
    # openDefaultBrowser(fileHtml)
    echo helpMsg(fileHtml, port)
