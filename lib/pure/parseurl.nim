import regexprs, strutils

type
  TUrl* = tuple[protocol, subdomain, domain, port: string, path: seq[string]]

proc parseUrl*(url: string): TUrl =
  #([a-zA-Z]+://)?(\w+?\.)?(\w+)(\.\w+)(:[0-9]+)?(/.+)?
  const pattern = r"([a-zA-Z]+://)?(\w+?\.)?(\w+)(\.\w+)(:[0-9]+)?(/.+)?"
  var m: array[0..6, string] #Array with the matches
  discard regexprs.match(url, pattern, m)
 
  result = (protocol: m[1], subdomain: m[2], domain: m[3] & m[4], 
            port: m[5], path: m[6].split('/'))
 
when isMainModule:
  var r = parseUrl(r"http://google.com/search?var=bleahdhsad")
  echo(r.domain)

