#
#
#            Nimrod's Runtime Library
#        (c) Copyright 2010 Dominik Picheta
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## Parses & constructs URLs.

import strutils

type
  TURL* = tuple[      ## represents a *Uniform Resource Locator* (URL)
                      ## any optional component is "" if it does not exist
    scheme, username, password, 
    hostname, port, path, query, anchor: string]
    
proc parseUrl*(url: string): TURL =
  var i: int = 0

  var scheme, username, password: string = ""
  var hostname, port, path, query, anchor: string = ""

  var temp: string = ""
  
  if url[i] != '/': #url isn't a relative path
    while True:
      #Scheme
      if url[i] == ':':
        if url[i+1] == '/' and url[i+2] == '/':
          scheme = temp
          temp = ""
          inc(i, 3) #Skip the //
      #Authority(username, password)
      if url[i] == '@':
        username = temp.split(':')[0]
        if temp.split(':').len() > 1:
          password = temp.split(':')[1]
        temp = ""
        inc(i) #Skip the @ 
      #hostname(subdomain, domain, port)
      if url[i] == '/' or url[i] == '\0':
        hostname = temp
        if hostname.split(':').len() > 1:
          port = hostname.split(':')[1]
          hostname = hostname.split(':')[0]
        
        temp = ""
        break
      
      temp.add(url[i])
      inc(i)

  if url[i] == '/': inc(i) # Skip the '/'
  #Path
  while True:
    if url[i] == '?':
      path = temp
      temp = ""
    if url[i] == '#':
      if temp[0] == '?':
        query = temp
      else:
        path = temp
      temp = ""
      
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

proc `$`*(t: TURL): string =
  result = ""
  if t.scheme != "": result.add(t.scheme & "://")
  if t.username != "":
    if t.password != "":
      result.add(t.username & ":" & t.password & "@")
    else:
      result.add(t.username & "@")
  result.add(t.hostname)
  if t.port != "": result.add(":" & t.port)
  if t.path != "": result.add("/" & t.path)
  result.add(t.query)
  result.add(t.anchor)
