#
#
#            Nimrod's Runtime Library
#        (c) Copyright 2012 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## This module contains simple high-level procedures for dealing with the
## web. Use cases:
##
## * requesting URLs
## * sending and retrieving emails
## * sending and retrieving files from an FTP server
##
## Currently only requesting URLs is implemented. The implementation depends
## on the libcurl library!
##
## **Deprecated since version 0.8.8:** Use the
## `httpclient <httpclient.html>`_ module instead.
##

{.deprecated.}

import libcurl, streams

proc curlwrapperWrite(p: pointer, size, nmemb: int,
                      data: pointer): int {.cdecl.} =
  var stream = cast[PStream](data)
  stream.writeData(p, size*nmemb)
  return size*nmemb

proc URLretrieveStream*(url: string): PStream =
  ## retrieves the given `url` and returns a stream which one can read from to
  ## obtain the contents. Returns nil if an error occurs.
  result = newStringStream()
  var hCurl = easy_init()
  if hCurl == nil: return nil
  if easy_setopt(hCurl, OPT_URL, url) != E_OK: return nil
  if easy_setopt(hCurl, OPT_WRITEFUNCTION,
                      curlwrapperWrite) != E_OK: return nil
  if easy_setopt(hCurl, OPT_WRITEDATA, result) != E_OK: return nil
  if easy_perform(hCurl) != E_OK: return nil
  easy_cleanup(hCurl)

proc URLretrieveString*(url: string): TaintedString =
  ## retrieves the given `url` and returns the contents. Returns nil if an
  ## error occurs.
  var stream = newStringStream()
  var hCurl = easy_init()
  if hCurl == nil: return
  if easy_setopt(hCurl, OPT_URL, url) != E_OK: return
  if easy_setopt(hCurl, OPT_WRITEFUNCTION,
                      curlwrapperWrite) != E_OK: return
  if easy_setopt(hCurl, OPT_WRITEDATA, stream) != E_OK: return
  if easy_perform(hCurl) != E_OK: return
  easy_cleanup(hCurl)
  result = stream.data.TaintedString

when isMainModule:
  echo URLretrieveString("http://nimrod-code.org/")

