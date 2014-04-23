#
#
#            Nimrod's Runtime Library
#        (c) Copyright 2014 Dominik Picheta
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## Parses & constructs URLs.

import strutils

type
  TUrl* = tuple[      ## represents a *Uniform Resource Locator* (URL)
                      ## any optional component is "" if it does not exist
    scheme, username, password, 
    hostname, port, path, query, anchor: string]
    

proc skip(i: var int, skippedChars: string) = 
  inc(i, skippedChars.len)

proc readScheme(url: var TUrl, temp: string) =
  url.scheme = temp

proc readAuthority(url: var TUrl, temp: string) =
  let colon = temp.find(':')
  if colon >= 0:
    url.password = temp.substr(colon+1)
    url.username = temp.substr(0, colon-1)

proc readHostAndPort(url: var TUrl, temp: string) =
  let colon = temp.find(':')
  if colon >= 0:
    url.port = temp.substr(colon+1)
    url.hostname = temp.substr(0, colon-1)

proc readUntilPath(self: var TUrl, url: string): int =
  var temp = ""
  var i = 0
  let relative = url[i] == '/'
  if not relative:
    while True:
      if url[i] == ':':
        if url[i+1] == '/' and url[i+2] == '/':
          self.readScheme(temp)
          i.skip("://")
          temp.setlen(0)
      if url[i] == '@':
        self.readAuthority(temp)
        i.skip("@")
        temp.setlen(0)
      
      if url[i] == '/' or url[i] == '\0':
        self.readHostAndPort(temp)
        temp.setlen(0)
        break
      
      temp.add(url[i])
      inc(i)

  if url[i] == '/': 
    i.skip("/")
  return i

proc readPath(url: var TUrl, path: string) =
  var temp = ""
  var i = 0
  while True:
    if path[i] == '?':
      url.path = temp
      temp.setlen(0)
    if path[i] == '#':
      if temp[0] == '?':
        url.query = temp
      else:
        url.path = temp
      temp.setlen(0)
      
    if path[i] == '\0':
      if temp[0] == '?':
        url.query = temp
      elif temp[0] == '#':
        url.anchor = temp
      else:
        url.path = temp
      break
    temp.add(path[i])
    inc(i)

proc parseUrl*(url: string): TUrl =
  result.scheme = ""
  result.username = ""
  result.password = ""
  result.hostname = ""
  result.port = ""
  result.path = ""
  result.query = ""
  result.anchor = ""
  
  let lastIndex = result.readUntilPath(url)
  let path = url[lastIndex..url.len]
  result.readPath(path)
    

proc `$`*(u: TUrl): string =
  ## turns the URL `u` into its string representation.
  result = ""
  if u.scheme.len > 0:
    result.add(u.scheme)
    result.add("://")
  if u.username.len > 0:
    result.add(u.username)
    if u.password.len > 0:
      result.add(":")
      result.add(u.password)
    result.add("@")
  result.add(u.hostname)
  if u.port.len > 0: 
    result.add(":")
    result.add(u.port)
  if u.path.len > 0: 
    result.add("/")
    result.add(u.path)
  result.add(u.query)
  result.add(u.anchor)

proc nvl(a: string, b: string): string =
  if a == "":
    return b
  return a

proc `/`*(a, b: TUrl): TUrl =
  result.scheme = nvl(a.scheme, b.scheme)
  result.username = nvl(a.username, b.username)
  result.password = nvl(a.password, b.password)
  result.hostname = nvl(a.hostname, b.hostname)
  result.port = nvl(a.port, b.port)
  result.path = nvl(a.path, b.path)
  result.query = nvl(a.query, b.query)
  result.anchor = nvl(a.anchor, b.anchor)
  
when isMainModule:
  import unittest

  test "parse full URL":
    let url = parseUrl("http://localhost:5000/path?message1=Nimrod&message2=+is+cool!#anchor")
    check url.username == ""
    check url.password == ""
    check url.scheme == "http"
    check url.hostname == "localhost"
    check url.port == "5000"
    check url.path == "path"
    check url.query == "?message1=Nimrod&message2=+is+cool!"
    check url.anchor == "#anchor"

  test "parse full URL with username and password":
    let url = parseUrl("http://username:password@localhost:5000/path?message1=Nimrod&message2=+is+cool!#anchor")
    check url.username == "username"
    check url.password == "password"
    check url.scheme == "http"
    check url.hostname == "localhost"
    check url.port == "5000"
    check url.path == "path"
    check url.query == "?message1=Nimrod&message2=+is+cool!"
    check url.anchor == "#anchor"

  test "parse URL fragment localhost:5000":
    let url = parseUrl("localhost:5000")
    check url.username == ""
    check url.password == ""
    check url.scheme == ""
    check url.hostname == "localhost"
    check url.port == "5000"
    check url.path == ""
    check url.query == ""
    check url.anchor == ""

  test "parse URL fragment: /path?message1=Nimrod&message2=+is+cool!#anchor":
    let url = parseUrl("/path?message1=Nimrod&message2=+is+cool!#anchor")
    check url.username == ""
    check url.password == ""
    check url.scheme == ""
    check url.hostname == ""
    check url.port == ""
    check url.path == "path"
    check url.query == "?message1=Nimrod&message2=+is+cool!"
    check url.anchor == "#anchor"

  test "parse URL fragment: http://":
    let url = parseUrl("http://")
    check url.scheme == "http"
    check url.username == ""
    check url.password == ""
    check url.hostname == ""
    check url.port == ""
    check url.path == ""
    check url.query == ""
    check url.anchor == ""

  test "url concatenation":
    let url1 = parseUrl("http://localhost:5000")
    let url2 = parseUrl("/path?message1=Nimrod&message2=+is+cool!#anchor")
    let url = url1 / url2
    check url.username == ""
    check url.password == ""
    check url.scheme == "http"
    check url.hostname == "localhost"
    check url.port == "5000"
    check url.path == "path"
    check url.query == "?message1=Nimrod&message2=+is+cool!"
    check url.anchor == "#anchor"
