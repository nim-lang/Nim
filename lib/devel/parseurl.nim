import regexprs, strutils

type
  TURL* = tuple[protocol, username, password,
    subdomain, domain, port, path, query, anchor: string]

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
   
  var r: TURL
  r = parse(r"http://google.co.uk/search?var=bleahdhsad")
  test(r)
  r = parse(r"http://dom96:test@google.com:80/search.php?q=562gs6&foo=6gs6&bar=7hs6#test")
  test(r)
  r = parse(r"http://www.google.co.uk/search?q=multiple+subdomains&ie=utf-8&oe=utf-8&aq=t&rls=org.mozilla:pl:official&client=firefox-a")
  test(r)