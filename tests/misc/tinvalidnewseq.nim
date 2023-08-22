discard """
  errormsg: "type mismatch: got <array[0..6, string], int literal(7)>"
  file: "tinvalidnewseq.nim"
  line: 15
"""
import re, strutils

type
  TURL = tuple[protocol, subdomain, domain, port: string, path: seq[string]]

proc parseURL(url: string): TURL =
  #([a-zA-Z]+://)?(\w+?\.)?(\w+)(\.\w+)(:[0-9]+)?(/.+)?
  var pattern: string = r"([a-zA-Z]+://)?(\w+?\.)?(\w+)(\.\w+)(:[0-9]+)?(/.+)?"
  var m: array[0..6, string] #Array with the matches
  newSeq(m, 7) #ERROR
  discard re.match(url, re(pattern), m)

  result = (protocol: m[1], subdomain: m[2], domain: m[3] & m[4],
            port: m[5], path: m[6].split('/'))

var r: TUrl

r = parseUrl(r"http://google.com/search?var=bleahdhsad")
echo(r.domain)
