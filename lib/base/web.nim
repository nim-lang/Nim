#
#
#            Nimrod's Runtime Library
#        (c) Copyright 2009 Andreas Rumpf
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

import libcurl, streams

proc curlwrapperWrite(p: pointer, size, nmemb: int, 
                      data: pointer): int {.cdecl.} = 
  var stream = cast[PStream](data)
  stream.writeData(stream, p, size*nmemb)
  return size*nmemb

proc URLretrieveStream*(url: string): PStream = 
  ## retrieves the given `url` and returns a stream which one can read from to
  ## obtain the contents. Returns nil if an error occurs.
  result = newStringStream()
  var hCurl = curl_easy_init() 
  if hCurl == nil: return nil
  if curl_easy_setopt(hCurl, CURLOPT_URL, url) != CURLE_OK: return nil
  if curl_easy_setopt(hCurl, CURLOPT_WRITEFUNCTION, 
                      curlwrapperWrite) != CURLE_OK: return nil
  if curl_easy_setopt(hCurl, CURLOPT_WRITEDATA, result) != CURLE_OK: return nil
  if curl_easy_perform(hCurl) != CURLE_OK: return nil
  curl_easy_cleanup(hCurl)
  
proc URLretrieveString*(url: string): string = 
  ## retrieves the given `url` and returns the contents. Returns nil if an
  ## error occurs.
  var stream = newStringStream()
  var hCurl = curl_easy_init()
  if hCurl == nil: return nil
  if curl_easy_setopt(hCurl, CURLOPT_URL, url) != CURLE_OK: return nil
  if curl_easy_setopt(hCurl, CURLOPT_WRITEFUNCTION, 
                      curlwrapperWrite) != CURLE_OK: return nil
  if curl_easy_setopt(hCurl, CURLOPT_WRITEDATA, stream) != CURLE_OK: return nil
  if curl_easy_perform(hCurl) != CURLE_OK: return nil
  curl_easy_cleanup(hCurl)
  result = stream.data

when isMainModule:
  echo URLretrieveString("http://nimrod.ethexor.com/")

