discard """
  cmd:      "nim c -r --styleCheck:hint --panics:on $options $file"
  targets:  "c"
  nimout:   ""
  action:   "run"
  exitcode: 0
  timeout:  60.0
"""
import uri


block:
  let org = "udp://[2001:0db8:85a3:0000:0000:8a2e:0370:7334]:8080"
  let url = parseUri(org)
  doAssert url.hostname == "2001:0db8:85a3:0000:0000:8a2e:0370:7334" # true
  let newUrl = parseUri($url)
  doAssert newUrl.hostname == "2001:0db8:85a3:0000:0000:8a2e:0370:7334" # true
