#
#
#            Nim's Runtime Library
#        (c) Copyright 2015 Dominik Picheta
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
    opaque*: bool

{.deprecated: [TUrl: Url, TUri: Uri].}

{.push warning[deprecated]: off.}
proc `$`*(url: Url): string {.deprecated.} =
  ## **Deprecated since 0.9.6**: Use ``Uri`` instead.
  return string(url)

proc `/`*(a, b: Url): Url {.deprecated.} =
  ## Joins two URLs together, separating them with / if needed.
  ##
  ## **Deprecated since 0.9.6**: Use ``Uri`` instead.
  var urlS = $a
  var bS = $b
  if urlS == "": return b
  if urlS[urlS.len-1] != '/':
    urlS.add('/')
  if bS[0] == '/':
    urlS.add(bS.substr(1))
  else:
    urlS.add(bs)
  result = Url(urlS)

proc add*(url: var Url, a: Url) {.deprecated.} =
  ## Appends url to url.
  ##
  ## **Deprecated since 0.9.6**: Use ``Uri`` instead.
  url = url / a
{.pop.}

proc parseAuthority(authority: string, result: var Uri) =
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

proc parsePath(uri: string, i: var int, result: var Uri) =
  
  i.inc parseUntil(uri, result.path, {'?', '#'}, i)

  # The 'mailto' scheme's PATH actually contains the hostname/username
  if result.scheme.toLower == "mailto":
    parseAuthority(result.path, result)
    result.path = ""

  if uri[i] == '?':
    i.inc # Skip '?'
    i.inc parseUntil(uri, result.query, {'#'}, i)

  if uri[i] == '#':
    i.inc # Skip '#'
    i.inc parseUntil(uri, result.anchor, {}, i)

proc initUri(): Uri =
  result = Uri(scheme: "", username: "", password: "", hostname: "", port: "",
                path: "", query: "", anchor: "")

proc parseUri*(uri: string): Uri =
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
      raise newException(ValueError, "Expected authority got nothing.")
    parseAuthority(authority, result)
  else:
    result.opaque = true

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

proc merge(base, reference: Uri): string =
  # http://tools.ietf.org/html/rfc3986#section-5.2.3
  if base.hostname != "" and base.path == "":
    '/' & reference.path
  else:
    let lastSegment = rfind(base.path, "/")
    if lastSegment == -1:
      reference.path
    else:
      base.path[0 .. lastSegment] & reference.path

proc combine*(base: Uri, reference: Uri): Uri =
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
  ##   assert bar.path == "/foo/baz"
  ##
  ##   let bar = combine(parseUri("http://example.com/foo/bar/"), parseUri("baz"))
  ##   assert bar.path == "/foo/bar/baz"
  
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

proc combine*(uris: varargs[Uri]): Uri =
  ## Combines multiple URIs together.
  result = uris[0]
  for i in 1 .. <uris.len:
    result = combine(result, uris[i])

proc `/`*(x: Uri, path: string): Uri =
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
  ##   assert bar.path == "/foo/bar/baz"
  ##
  ##   let bar = parseUri("http://example.com/foo/bar/") / parseUri("baz")
  ##   assert bar.path == "/foo/bar/baz"
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

proc `$`*(u: Uri): string =
  ## Returns the string representation of the specified URI object.
  result = ""
  if u.scheme.len > 0:
    result.add(u.scheme)
    if u.opaque:
      result.add(":")
    else:
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
    result.add(u.path)
  if u.query.len > 0:
    result.add("?")
    result.add(u.query)
  if u.anchor.len > 0:
    result.add("#")
    result.add(u.anchor)

when isMainModule:
  block:
    let str = "http://localhost"
    let test = parseUri(str)
    doAssert test.path == ""

  block:
    let str = "http://localhost/"
    let test = parseUri(str)
    doAssert test.path == "/"

  block:
    let str = "http://localhost:8080/test"
    let test = parseUri(str)
    doAssert test.scheme == "http"
    doAssert test.port == "8080"
    doAssert test.path == "/test"
    doAssert test.hostname == "localhost"
    doAssert($test == str)

  block:
    let str = "foo://username:password@example.com:8042/over/there" &
              "/index.dtb?type=animal&name=narwhal#nose"
    let test = parseUri(str)
    doAssert test.scheme == "foo"
    doAssert test.username == "username"
    doAssert test.password == "password"
    doAssert test.hostname == "example.com"
    doAssert test.port == "8042"
    doAssert test.path == "/over/there/index.dtb"
    doAssert test.query == "type=animal&name=narwhal"
    doAssert test.anchor == "nose"
    doAssert($test == str)

  block:
    let str = "urn:example:animal:ferret:nose"
    let test = parseUri(str)
    doAssert test.scheme == "urn"
    doAssert test.path == "example:animal:ferret:nose"
    doAssert($test == str)

  block:
    let str = "mailto:username@example.com?subject=Topic"
    let test = parseUri(str)
    doAssert test.scheme == "mailto"
    doAssert test.username == "username"
    doAssert test.hostname == "example.com"
    doAssert test.query == "subject=Topic"
    doAssert($test == str)

  block:
    let str = "magnet:?xt=urn:sha1:72hsga62ba515sbd62&dn=foobar"
    let test = parseUri(str)
    doAssert test.scheme == "magnet"
    doAssert test.query == "xt=urn:sha1:72hsga62ba515sbd62&dn=foobar"
    doAssert($test == str)

  block:
    let str = "/test/foo/bar?q=2#asdf"
    let test = parseUri(str)
    doAssert test.scheme == ""
    doAssert test.path == "/test/foo/bar"
    doAssert test.query == "q=2"
    doAssert test.anchor == "asdf"
    doAssert($test == str)

  block:
    let str = "test/no/slash"
    let test = parseUri(str)
    doAssert test.path == "test/no/slash"
    doAssert($test == str)

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
