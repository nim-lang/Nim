#
#
#            Nim's Runtime Library
#        (c) Copyright 2014 Dominik Picheta
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## This module implements URI parsing as specified by RFC 3986.

import strutils, parseutils
type
  Url* = distinct string

  Uri* = object
    scheme*, username*, password*: string 
    hostname*, port*, path*, query*, anchor*: string

{.deprecated: [TUrl: Url, TUri: Uri].}

proc `$`*(url: TUrl): string {.deprecated.} =
  ## **Deprecated since 0.9.6**: Use ``TUri`` instead.
  return string(url)

proc `/`*(a, b: TUrl): TUrl {.deprecated.} =
  ## Joins two URLs together, separating them with / if needed.
  ##
  ## **Deprecated since 0.9.6**: Use ``TUri`` instead.
  var urlS = $a
  var bS = $b
  if urlS == "": return b
  if urlS[urlS.len-1] != '/':
    urlS.add('/')
  if bS[0] == '/':
    urlS.add(bS.substr(1))
  else:
    urlS.add(bs)
  result = TUrl(urlS)

proc add*(url: var TUrl, a: TUrl) {.deprecated.} =
  ## Appends url to url.
  ##
  ## **Deprecated since 0.9.6**: Use ``TUri`` instead.
  url = url / a

proc parseAuthority(authority: string, result: var TUri) =
  var i = 0
  var inPort = false
  while true:
    case authority[i]
    of '@':
      result.password = result.port
      result.port = ""
      result.username = result.hostname
      result.hostname = ""
      inPort = false
    of ':':
      inPort = true
    of '\0': break
    else:
      if inPort:
        result.port.add(authority[i])
      else:
        result.hostname.add(authority[i])
    i.inc

proc parsePath(uri: string, i: var int, result: var TUri) =
  
  i.inc parseUntil(uri, result.path, {'?', '#'}, i)

  # The 'mailto' scheme's PATH actually contains the hostname/username
  if result.scheme.ToLower() == "mailto":
    parseAuthority(result.path, result)
    result.path = ""

  if uri[i] == '?':
    i.inc # Skip '?'
    i.inc parseUntil(uri, result.query, {'#'}, i)

  if uri[i] == '#':
    i.inc # Skip '#'
    i.inc parseUntil(uri, result.anchor, {}, i)

proc initUri(): TUri =
  result = TUri(scheme: "", username: "", password: "", hostname: "", port: "",
                path: "", query: "", anchor: "")

proc parseUri*(uri: string): TUri =
  ## Parses a URI.
  result = initUri()

  var i = 0

  # Check if this is a reference URI (relative URI)
  if uri[i] == '/':
    parsePath(uri, i, result)
    return

  # Scheme
  i.inc parseWhile(uri, result.scheme, Letters + Digits + {'+', '-', '.'}, i)
  if uri[i] != ':':
    # Assume this is a reference URI (relative URI)
    i = 0
    result.scheme = ""
    parsePath(uri, i, result)
    return
  i.inc # Skip ':'

  # Authority
  if uri[i] == '/' and uri[i+1] == '/':
    i.inc(2) # Skip //
    var authority = ""
    i.inc parseUntil(uri, authority, {'/', '?', '#'}, i)
    if authority == "":
      raise newException(EInvalidValue, "Expected authority got nothing.")
    parseAuthority(authority, result)

  # Path
  parsePath(uri, i, result)

proc removeDotSegments(path: string): string =
  var collection: seq[string] = @[]
  let endsWithSlash = path[path.len-1] == '/'
  var i = 0
  var currentSegment = ""
  while true:
    case path[i]
    of '/':
      collection.add(currentSegment)
      currentSegment = ""
    of '.':
      if path[i+1] == '.' and path[i+2] == '/':
        if collection.len > 0:
          discard collection.pop()
          i.inc 3
          continue
      elif path[i+1] == '/':
        i.inc 2
        continue
      currentSegment.add path[i]
    of '\0':
      if currentSegment != "":
        collection.add currentSegment
      break
    else:
      currentSegment.add path[i]
    i.inc

  result = collection.join("/")
  if endsWithSlash: result.add '/'

proc merge(base, reference: TUri): string =
  # http://tools.ietf.org/html/rfc3986#section-5.2.3
  if base.hostname != "" and base.path == "":
    '/' & reference.path
  else:
    let lastSegment = rfind(base.path, "/")
    if lastSegment == -1:
      reference.path
    else:
      base.path[0 .. lastSegment] & reference.path

proc combine*(base: TUri, reference: TUri): TUri =
  ## Combines a base URI with a reference URI.
  ##
  ## This uses the algorithm specified in
  ## `section 5.2.2 of RFC 3986 <http://tools.ietf.org/html/rfc3986#section-5.2.2>`_.
  ##
  ## This means that the slashes inside the base URI's path as well as reference
  ## URI's path affect the resulting URI.
  ##
  ## For building URIs you may wish to use \`/\` instead.
  ##
  ## Examples:
  ##
  ## .. code-block::
  ##   let foo = combine(parseUri("http://example.com/foo/bar"), parseUri("/baz"))
  ##   assert foo.path == "/baz"
  ##
  ##   let bar = combine(parseUri("http://example.com/foo/bar"), parseUri("baz"))
  ##   assert foo.path == "/foo/baz"
  ##
  ##   let bar = combine(parseUri("http://example.com/foo/bar/"), parseUri("baz"))
  ##   assert foo.path == "/foo/bar/baz"
  
  template setAuthority(dest, src: expr): stmt =
    dest.hostname = src.hostname
    dest.username = src.username
    dest.port = src.port
    dest.password = src.password

  result = initUri()
  if reference.scheme != base.scheme and reference.scheme != "":
    result = reference
    result.path = removeDotSegments(result.path)
  else:
    if reference.hostname != "":
      setAuthority(result, reference)
      result.path = removeDotSegments(reference.path)
      result.query = reference.query
    else:
      if reference.path == "":
        result.path = base.path
        if reference.query != "":
          result.query = reference.query
        else:
          result.query = base.query
      else:
        if reference.path.startsWith("/"):
          result.path = removeDotSegments(reference.path)
        else:
          result.path = removeDotSegments(merge(base, reference))
        result.query = reference.query
      setAuthority(result, base)
    result.scheme = base.scheme
  result.anchor = reference.anchor

proc combine*(uris: varargs[TUri]): TUri =
  ## Combines multiple URIs together.
  result = uris[0]
  for i in 1 .. <uris.len:
    result = combine(result, uris[i])

proc `/`*(x: TUri, path: string): TUri =
  ## Concatenates the path specified to the specified URI's path.
  ##
  ## Contrary to the ``combine`` procedure you do not have to worry about
  ## the slashes at the beginning and end of the path and URI's path
  ## respectively.
  ##
  ## Examples:
  ##
  ## .. code-block::
  ##   let foo = parseUri("http://example.com/foo/bar") / parseUri("/baz")
  ##   assert foo.path == "/foo/bar/baz"
  ##
  ##   let bar = parseUri("http://example.com/foo/bar") / parseUri("baz")
  ##   assert foo.path == "/foo/bar/baz"
  ##
  ##   let bar = parseUri("http://example.com/foo/bar/") / parseUri("baz")
  ##   assert foo.path == "/foo/bar/baz"
  result = x
  if result.path[result.path.len-1] == '/':
    if path[0] == '/':
      result.path.add(path[1 .. path.len-1])
    else:
      result.path.add(path)
  else:
    if path[0] != '/':
      result.path.add '/'
    result.path.add(path)

proc `$`*(u: TUri): string =
  ## Returns the string representation of the specified URI object.
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
    if u.path[0] != '/': result.add("/")
    result.add(u.path)
  result.add(u.query)
  result.add(u.anchor)

when isMainModule:
  block:
    let test = parseUri("http://localhost:8080/test")
    doAssert test.scheme == "http"
    doAssert test.port == "8080"
    doAssert test.path == "/test"
    doAssert test.hostname == "localhost"

  block:
    let test = parseUri("foo://username:password@example.com:8042/over/there" &
                        "/index.dtb?type=animal&name=narwhal#nose")
    doAssert test.scheme == "foo"
    doAssert test.username == "username"
    doAssert test.password == "password"
    doAssert test.hostname == "example.com"
    doAssert test.port == "8042"
    doAssert test.path == "/over/there/index.dtb"
    doAssert test.query == "type=animal&name=narwhal"
    doAssert test.anchor == "nose"

  block:
    let test = parseUri("urn:example:animal:ferret:nose")
    doAssert test.scheme == "urn"
    doAssert test.path == "example:animal:ferret:nose"

  block:
    let test = parseUri("mailto:username@example.com?subject=Topic")
    doAssert test.scheme == "mailto"
    doAssert test.username == "username"
    doAssert test.hostname == "example.com"
    doAssert test.query == "subject=Topic"

  block:
    let test = parseUri("magnet:?xt=urn:sha1:72hsga62ba515sbd62&dn=foobar")
    doAssert test.scheme == "magnet"
    doAssert test.query == "xt=urn:sha1:72hsga62ba515sbd62&dn=foobar"

  block:
    let test = parseUri("/test/foo/bar?q=2#asdf")
    doAssert test.scheme == ""
    doAssert test.path == "/test/foo/bar"
    doAssert test.query == "q=2"
    doAssert test.anchor == "asdf"

  block:
    let test = parseUri("test/no/slash")
    doAssert test.path == "test/no/slash"

  # Remove dot segments tests
  block:
    doAssert removeDotSegments("/foo/bar/baz") == "/foo/bar/baz"

  # Combine tests
  block:
    let concat = combine(parseUri("http://google.com/foo/bar/"), parseUri("baz"))
    doAssert concat.path == "/foo/bar/baz"
    doAssert concat.hostname == "google.com"
    doAssert concat.scheme == "http"

  block:
    let concat = combine(parseUri("http://google.com/foo"), parseUri("/baz"))
    doAssert concat.path == "/baz"
    doAssert concat.hostname == "google.com"
    doAssert concat.scheme == "http"

  block:
    let concat = combine(parseUri("http://google.com/foo/test"), parseUri("bar"))
    doAssert concat.path == "/foo/bar"

  block:
    let concat = combine(parseUri("http://google.com/foo/test"), parseUri("/bar"))
    doAssert concat.path == "/bar"

  block:
    let concat = combine(parseUri("http://google.com/foo/test"), parseUri("bar"))
    doAssert concat.path == "/foo/bar"

  block:
    let concat = combine(parseUri("http://google.com/foo/test/"), parseUri("bar"))
    doAssert concat.path == "/foo/test/bar"

  block:
    let concat = combine(parseUri("http://google.com/foo/test/"), parseUri("bar/"))
    doAssert concat.path == "/foo/test/bar/"

  block:
    let concat = combine(parseUri("http://google.com/foo/test/"), parseUri("bar/"),
                         parseUri("baz"))
    doAssert concat.path == "/foo/test/bar/baz"

  # `/` tests
  block:
    let test = parseUri("http://example.com/foo") / "bar/asd"
    doAssert test.path == "/foo/bar/asd"

  block:
    let test = parseUri("http://example.com/foo/") / "/bar/asd"
    doAssert test.path == "/foo/bar/asd"

  
