#
#
#            Nimrod's Runtime Library
#        (c) Copyright 2010 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## Parses & constructs URLs.


# From the spec:
#
#   This specification uses the Augmented Backus-Naur Form (ABNF)
#   notation of [RFC2234], including the following core ABNF syntax rules
#   defined by that specification: ALPHA (letters), CR (carriage return),
#   DIGIT (decimal digits), DQUOTE (double quote), HEXDIG (hexadecimal
#   digits), LF (line feed), and SP (space).
#
#
#   URI           = scheme ":" hier-part [ "?" query ] [ "#" fragment ]
#
#   hier-part     = "//" authority path-abempty
#                 / path-absolute
#                 / path-rootless
#                 / path-empty
#
#   URI-reference = URI / relative-ref
#
#   absolute-URI  = scheme ":" hier-part [ "?" query ]
#
#  relative-ref  = relative-part [ "?" query ] [ "#" fragment ]
#
#   relative-part = "//" authority path-abempty
#                 / path-absolute
#                 / path-noscheme
#                 / path-empty
#
#   scheme        = ALPHA *( ALPHA / DIGIT / "+" / "-" / "." )
#
#   authority     = [ userinfo "@" ] host [ ":" port ]
#   userinfo      = *( unreserved / pct-encoded / sub-delims / ":" )
#   host          = IP-literal / IPv4address / reg-name
#   port          = *DIGIT
#
#   IP-literal    = "[" ( IPv6address / IPvFuture  ) "]"
#
#   IPvFuture     = "v" 1*HEXDIG "." 1*( unreserved / sub-delims / ":" )
#
#   IPv6address   =                            6( h16 ":" ) ls32
#                 /                       "::" 5( h16 ":" ) ls32
#                 / [               h16 ] "::" 4( h16 ":" ) ls32
#                 / [ *1( h16 ":" ) h16 ] "::" 3( h16 ":" ) ls32
#                 / [ *2( h16 ":" ) h16 ] "::" 2( h16 ":" ) ls32
#                 / [ *3( h16 ":" ) h16 ] "::"    h16 ":"   ls32
#                 / [ *4( h16 ":" ) h16 ] "::"              ls32
#                 / [ *5( h16 ":" ) h16 ] "::"              h16
#                 / [ *6( h16 ":" ) h16 ] "::"
#
#   h16           = 1*4HEXDIG
#   ls32          = ( h16 ":" h16 ) / IPv4address
#   IPv4address   = dec-octet "." dec-octet "." dec-octet "." dec-octet
#
#   dec-octet     = DIGIT                 ; 0-9
#                 / %x31-39 DIGIT         ; 10-99
#                 / "1" 2DIGIT            ; 100-199
#                 / "2" %x30-34 DIGIT     ; 200-249
#                 / "25" %x30-35          ; 250-255
#
#   reg-name      = *( unreserved / pct-encoded / sub-delims )
#
#   path          = path-abempty    ; begins with "/" or is empty
#                 / path-absolute   ; begins with "/" but not "//"
#                 / path-noscheme   ; begins with a non-colon segment
#                 / path-rootless   ; begins with a segment
#                 / path-empty      ; zero characters
#
#   path-abempty  = *( "/" segment )
#   path-absolute = "/" [ segment-nz *( "/" segment ) ]
#   path-noscheme = segment-nz-nc *( "/" segment )
#   path-rootless = segment-nz *( "/" segment )
#   path-empty    = 0<pchar>
#
#   segment       = *pchar
#   segment-nz    = 1*pchar
#   segment-nz-nc = 1*( unreserved / pct-encoded / sub-delims / "@" )
#                 ; non-zero-length segment without any colon ":"
#
#   pchar         = unreserved / pct-encoded / sub-delims / ":" / "@"
#
#   query         = *( pchar / "/" / "?" )
#
#   fragment      = *( pchar / "/" / "?" )
#
#   pct-encoded   = "%" HEXDIG HEXDIG
#
#   unreserved    = ALPHA / DIGIT / "-" / "." / "_" / "~"
#   reserved      = gen-delims / sub-delims
#   gen-delims    = ":" / "/" / "?" / "#" / "[" / "]" / "@"
#   sub-delims    = "!" / "$" / "&" / "'" / "(" / ")"
#                 / "*" / "+" / "," / ";" / "="
#


import strutils

type
  TUrl* = tuple[      ## represents a *Uniform Resource Locator* (URL)
                      ## any optional component is "" if it does not exist
    protocol: string  ## for example ``http:``
    username: string  ## for example ``paul`` (optional)
    password: string  ## for example ``r2d2`` (optional)
    subdomain: string ## 
    domain,
    port,
    path,
    query,
    anchor: string]

proc host*(u: TUrl): string =
  ## returns the host of the URL

proc parse*(url: string): TURL =
  const pattern = r"([a-zA-Z]+://)?(.+@)?(.+\.)?(\w+)(\.\w+)(:[0-9]+)?(/.+)?"
  var m: array[0..7, string] #Array with the matches
  discard regexprs.match(url, pattern, m)
 
  var msplit = m[2].split(':')

  var username: string = ""
  var password: string = ""
  if m[2] != "":
    username = msplit[0]
    if msplit.len() == 2:
      password = msplit[1].replace("@", "")

  var path: string = ""
  var query: string = ""
  var anchor: string = ""
     
  if m[7] != nil:
    msplit = m[7].split('?')
    path = msplit[0]
    query = ""
    anchor = ""
    if msplit.len() == 2:
      query = "?" & msplit[1]
     
    msplit = path.split('#')
    if msplit.len() == 2:
      anchor = "#" & msplit[1]
      path = msplit[0]
    msplit = query.split('#')
    if msplit.len() == 2:
      anchor = "#" & msplit[1]
      query = msplit[0]
 
  result = (protocol: m[1], username: username, password: password,
    subdomain: m[3], domain: m[4] & m[5], port: m[6], path: path, query: query, anchor: anchor)
 
when isMainModule:
  proc test(r: TURL) =
    echo("protocol=" & r.protocol)
    echo("username=" & r.username)
    echo("password=" & r.password)
    echo("subdomain=" & r.subdomain)
    echo("domain=" & r.domain)
    echo("port=" & r.port)
    echo("path=" & r.path)
    echo("query=" & r.query)
    echo("anchor=" & r.anchor)
    echo("---------------")
   
  var r: TUrl
  r = parse(r"http://google.co.uk/search?var=bleahdhsad")
  test(r)
  r = parse(r"http://dom96:test@google.com:80/search.php?q=562gs6&foo=6gs6&bar=7hs6#test")
  test(r)
  r = parse(r"http://www.google.co.uk/search?q=multiple+subdomains&ie=utf-8&oe=utf-8&aq=t&rls=org.mozilla:pl:official&client=firefox-a")
  test(r)