discard """
  cmd: "nim c --threads:on -d:ssl $file"
  output: '''302 FOUND
301 Moved Permanently
200 OK
302 FOUND
'''
"""

import os
import httpclient

proc test_redirect() =
  var client = newHTTPClient(maxRedirects = 1)
  let data = client.get("http://httpbin.org/redirect/2")
  echo $data.status

proc test_redirect_1(max_r: int) =
  var client = newHTTPClient(maxRedirects = max_r)
  let data = client.get("http://httpbin.org/redirect-to?url=https://httpbin.org/redirect-to?url=http://nim-lang.org")
  echo $data.status

proc test_redirect_deprecated() =
  let data = get("http://httpbin.org/redirect/2", maxRedirects = 1)
  echo $data.status

proc test_redirect_download() =
  var fname = "httpbin.json"
  var client = newHTTPClient(maxRedirects = 1)
  client.downloadFile("http://httpbin.org/redirect/2", fname)
  let fp = open(fname, fmRead)
  echo fp.readAll()
  fp.close()
  os.removeFile(fname)


test_redirect()
test_redirect_1(2)
test_redirect_1(3)
test_redirect_deprecated()
test_redirect_download()
