import sockets, strutils, parseurl, pegs

type
  response = tuple[version: string, status: string, headers: seq[header], body: string]
  header = tuple[htype: string, hvalue: string] 

  EInvalidHttp* = object of EBase ## exception that is raised when server does
                                  ## not conform to the implemented HTTP
                                  ## protocol

proc httpError(msg: string) =
  var e: ref EInvalidHttp
  new(e)
  e.msg = msg
  raise e

proc parseResponse(data: string): response =
  var i = 0

  #Parse the version
  #Parses the first line of the headers
  #``HTTP/1.1`` 200 OK
    
  var matches: array[0..1, string]
  var L = data.matchLen(peg"\i 'HTTP/' {'1.1'/'1.0'} \s+ {(!\n .)*}\n",
                        matches, i)
  if L < 0: httpError("invalid HTTP header")
  
  result.version = matches[0]
  result.status = matches[1]
  inc(i, L)
  
  #Parse the headers
  #Everything after the first line leading up to the body
  #htype: hvalue

  result.headers = @[]
  while true:
    var key = ""
    while data[i] != ':':
      if data[i] == '\0': httpError("invalid HTTP header, ':' expected")
      key.add(data[i])
      inc(i)
    inc(i) # skip ':'
    if data[i] == ' ': inc(i)
    var val = ""
    while data[i] notin {'\C', '\L', '\0'}:
      val.add(data[i])
      inc(i)
    
    result.headers.add((key, val))
    
    if data[i] == '\C': inc(i)
    if data[i] == '\L': inc(i)
    else: httpError("invalid HTTP header, CR-LF expected")
    
    if data[i] == '\C': inc(i)
    if data[i] == '\L':
      inc(i)
      break
    
  #Parse the body
  #Everything after the headers(The first double CRLF)
  result.body = data.copy(i)
  

proc readChunked(data: var string, s: TSocket): response =
  #Read data from socket until the terminating chunk size is found(0\c\L\c\L)
  while true:
    data.add(s.recv())
    #Contains because 
    #trailers might be present
    #after the terminating chunk size
    if data.contains("0\c\L\c\L"): 
      break
      
  result = parseResponse(data) #Re-parse the body
  
  var count, length, chunkLength: int = 0
  var newBody: string = ""
  var bodySplit: seq[string] = result.body.splitLines()
  #Remove the chunks
  for i in items(bodySplit):
    if count == 1: #Get the first chunk size
      chunkLength = ParseHexInt(i) - i.len() - 1
    else:
      if length >= chunkLength:
        #The chunk size determines how much text is left
        #Until the next chunk size
        chunkLength = ParseHexInt(i)
        length = 0
      else:
        #Break if the terminating chunk size is found
        #This should ignore the `trailers`
        if bodySplit[count] == "0": #This might cause problems...
          break
        
        #Add the text to the newBody
        newBody.add(i & "\c\L")
        length = length + i.len()
    inc(count)
  #Make the parsed body the new body
  result.body = newBody
    
proc getHeaderValue*(headers: seq[header], name: string): string =
  ## Retrieves a header by ``name``, from ``headers``.
  ## Returns "" if a header is not found
  for i in low(headers)..high(headers):
    if cmpIgnoreCase(headers[i].htype, name) == 0:
      return headers[i].hvalue
  return ""

proc request*(url: string): response =
  var r = parse(url)
  
  var headers: string
  if r.path != "":
    headers = "GET " & r.path & " HTTP/1.1\c\L"
  else:
    headers = "GET / HTTP/1.1\c\L"
  
  headers = headers & "Host: " & r.subdomain & r.domain & "\c\L\c\L"
  
  var s = socket()
  s.connect(r.subdomain & r.domain, TPort(80))
  s.send(headers)
  
  var data = s.recv()
  
  result = parseResponse(data)

  #-REGION- Transfer-Encoding 
  #-Takes precedence over Content-Length
  #(http://tools.ietf.org/html/rfc2616#section-4.4) NR.2
  var transferEncodingHeader = getHeaderValue(result.headers, "Transfer-Encoding")
  if transferEncodingHeader == "chunked":
    result = readChunked(data, s)
  
  #-REGION- Content-Length
  #(http://tools.ietf.org/html/rfc2616#section-4.4) NR.3
  var contentLengthHeader = getHeaderValue(result.headers, "Content-Length")
  if contentLengthHeader != "":
    var length = contentLengthHeader.parseint()

    while data.len() < length:
      data.add(s.recv())
      
    result = parseResponse(data)
    
  #(http://tools.ietf.org/html/rfc2616#section-4.4) NR.4 TODO
    
  #-REGION- Connection: Close
  #(http://tools.ietf.org/html/rfc2616#section-4.4) NR.5
  var connectionHeader = getHeaderValue(result.headers, "Connection")
  if connectionHeader == "close":
    while True:
      var nD = s.recv()
      if nD == "": break
      data.add(nD)
    result = parseResponse(data)
  
  s.close()

proc get*(url: string): response =
  result = request(url)
  

var r = get("http://www.google.co.uk/index.html")
#var r = get("http://www.crunchyroll.com")
echo("===================================")
echo(r.version & " " & r.status)

for htype, hvalue in items(r.headers):
  echo(htype, ": ", hvalue)
echo("---------------------------------")
echo(r.body)