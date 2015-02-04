#
#
#            Nim's Runtime Library
#        (c) Copyright 2015 Dominik Picheta
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## **Warnings:** This module is deprecated since version 0.10.2.
## Use the `uri <uri.html>`_ module instead.
##
## Parses & constructs URLs.

{.deprecated.}

import strutils

type
  Url* = tuple[      ## represents a *Uniform Resource Locator* (URL)
                     ## any optional component is "" if it does not exist
    scheme, username, password,
    hostname, port, path, query, anchor: string]

{.deprecated: [TUrl: Url].}

proc parseUrl*(url: string): Url {.deprecated.} =
  var i = 0

  var scheme, username, password: string = ""
  var hostname, port, path, query, anchor: string = ""

  var temp = ""

  if url[i] != '/': # url isn't a relative path
    while true:
      # Scheme
      if url[i] == ':':
        if url[i+1] == '/' and url[i+2] == '/':
          scheme = temp
          temp.setLen(0)
          inc(i, 3) # Skip the //
      # Authority(username, password)
      if url[i] == '@':
        username = temp
        let colon = username.find(':')
        if colon >= 0:
          password = username.substr(colon+1)
          username = username.substr(0, colon-1)
        temp.setLen(0)
        inc(i) #Skip the @
      # hostname(subdomain, domain, port)
      if url[i] == '/' or url[i] == '\0':
        hostname = temp
        let colon = hostname.find(':')
        if colon >= 0:
          port = hostname.substr(colon+1)
          hostname = hostname.substr(0, colon-1)

        temp.setLen(0)
        break

      temp.add(url[i])
      inc(i)

  if url[i] == '/': inc(i) # Skip the '/'
  # Path
  while true:
    if url[i] == '?':
      path = temp
      temp.setLen(0)
    if url[i] == '#':
      if temp[0] == '?':
        query = temp
      else:
        path = temp
      temp.setLen(0)

    if url[i] == '\0':
      if temp[0] == '?':
        query = temp
      elif temp[0] == '#':
        anchor = temp
      else:
        path = temp
      break

    temp.add(url[i])
    inc(i)

  return (scheme, username, password, hostname, port, path, query, anchor)

proc `$`*(u: Url): string {.deprecated.} =
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

