#
#
#       Nim's Asynchronous Http Body Parser
#       (c) Copyright 2020 Nim Contributors
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## :Author: Henrique Dias
##
## This module parse request bodies and query strings in Nim. Supports
## application/x-www-form-urlencoded, as well multipart/form-data uploads.
##

##[

Example 1: Parse a form urlencoded request
==========================================

For http POST or PUT requests, the query string can be used in the
request body when the Content-Type header is set to
application/x-www-form-urlencoded.

.. code-block::nim

    # Example program to show the asynchttpbodyparser module.
    # Read and parse POST request form urlencoded body.

    import asyncdispatch, asynchttpserver, asynchttpbodyparser
    import strutils

    proc handler(req: Request) {.async.} =
      let htmlpage = """
    <!Doctype html>
    <html lang="en">
      <head>
        <meta charset="utf-8"/>
      </head>
      <body>
        <form action="/" method="post">
          <p>Input Text 1: <input type="text" name="testfield-1" value="Test 1"></p>
          <p>Input Text 2: <input type="text" name="testfield-2" value="Test 2"></p>
          <input type="submit">
        </form>
        <br />
        $1
      </body>
    </html>
    """
      if req.reqMethod == HttpPost:
        var html = "Data:<br />"
        try:
          let httpbody = await req.newAsyncHttpBodyParser()
          if httpbody.formdata.len > 0:
            html.add("<ul>")
            for k,v in httpbody.formdata:
              html.add("<li>$1 => $2</li>" % [k, v])
            html.add("</ul>")
          else:
            html.add("No data!")
        except HttpBodyParserError as e:
          echo e.msg
          await req.respond(e.httpStatusCode, $e.httpStatusCode)

        await req.respond(Http200, htmlpage % html)
      else:
        await req.respond(Http200, htmlpage % "No data!")

    var server = newAsyncHttpServer()
    waitFor server.serve(Port(8080), handler)
]##

##[

Example 2: Parse a multipart/form-data request
==============================================

This example parses a 'multipart/form-data' request, which is usually
generated from a HTML form submission. The parameters can include both
text values as well as binary files.

.. code-block::nim

    # The following example shows how to deal with uploaded files.
    # This example read the uploaded files directly from a future stream
    # and save them in a specify destination file.

    import asyncdispatch, asynchttpserver, asynchttpbodyparser
    import asyncfile
    import strutils

    proc handler(req: Request) {.async.} =
      let htmlpage = """
    <!Doctype html>
    <html lang="en">
      <head>
        <meta charset="utf-8"/>
      </head>
      <body>
        <form action="/" method="post" enctype="multipart/form-data">
          <p>File 1: <input type="file" name="testfile-1" accept="text/*"></p>
          <p>File 2: <input type="file" name="testfile-2" accept="text/*"></p>
          <p>Input 1: <input type="text" name="testfield-1" value="Test 1"></p>
          <p>Input 2: <input type="text" name="testfield-2" value="Test 2"></p>
          <input type="submit">
        </form>
        <br />
        $1
      </body>
    </html>
    """
      if req.reqMethod == HttpPost:
        try:
          let httpbody = await req.newAsyncHttpBodyParser()
          var html = "Data:<br />"
          if httpbody.multipart:
            if httpbody.formdata.len > 0:
              html.add("<ul>")
              for k,v in httpbody.formdata:
                html.add("<li>$1 => $2</li>" % [k, v])
              html.add("</ul>")
            html.add("Files:<br />")
            if httpbody.formfiles.len > 0:
              html.add("<ul>")
              for k,f in httpbody.formfiles:
                html.add("<li>$1:</li>" % k)
                html.add("<ul>")
                html.add("<li>Filename: $1</li>" % httpbody.formfiles[k].filename)
                html.add("<li>Content-Type: $1</li>" % httpbody.formfiles[k].content_type)
                html.add("<li>File Size: $1</li>" % $httpbody.formfiles[k].filesize)
                html.add("</ul>")
                # read data from future stream and output the file
                if httpbody.formfiles[k].filesize > 0:
                  let output = openAsync(httpbody.formfiles[k].filename, fmWrite)
                  while (let data = await httpbody.formfiles[k].fileStream.read(); data[0]):
                    await output.write(data[1])
                  output.close()
              html.add("</ul>")
            else:
              html.add("No Files!")
          else:
            html.add("No Multipart!")
          await req.respond(Http200, htmlpage % html)
        except HttpBodyParserError as e:
          echo e.msg
          await req.respond(e.httpStatusCode, $e.httpStatusCode)
      else:
        await req.respond(Http200, htmlpage % "No data!")

    let server = newAsyncHttpServer()
    waitFor server.serve(Port(8080), handler)
]##

import asyncnet, asyncdispatch, asynchttpserver
import tables, strutils
import httpcore
export asyncnet, tables

type
  FileAttributes* = object
    filename*: string    ## the filename of uploaded file 
    content_type*: string    ## the content type of uploaded file
    filesize*: BiggestInt    ## the size of uploaded file
    fileStream*: FutureStream[string]    ## the future stream of uploaded file

type
  AsyncHttpBodyParser* = ref object of RootObj
    formData*: TableRef[string, string]
    formFiles*: TableRef[string, FileAttributes]
    multipart*: bool

  HttpBodyParserError* = object of Exception
    httpStatusCode*: HttpCode

const chunkSize = 8*1024
# const debug: bool = true

# https://developer.mozilla.org/en-US/docs/Web/HTTP/Status
proc bodyParserError(code: HttpCode, msg: string) =
  var e: ref HttpBodyParserError
  new(e)
  e.msg = msg
  e.httpStatusCode = code
  raise e
  

proc splitInTwo(s: string, c: char): (string, string) =
  var p = find(s, c)
  if not (p > 0 and p < high(s)):
    return ("", "")

  let head = s[0 .. p-1]
  p += 1; while s[p] == ' ': p += 1
  return (head, s[p .. high(s)])


proc splitContentDisposition(s: string): (string, seq[string]) =
  var parts = newSeq[string]()

  var
    first_parameter = ""
    buff = ""
    p = 0

  while p < s.len:
    if s[p] == ';':
      if p > 0 and s[p-1] == '"':
        parts.add(buff)
        buff = ""

      if first_parameter.len == 0:
        if buff.len == 0: break
        first_parameter = buff
        buff = ""

      if buff == "":
        p += 1; while p < s.len and s[p] == ' ': p += 1
        continue
    buff.add(s[p])
    p += 1

  if buff.len > 0 and buff[high(buff)] == '"':
    parts.add(buff)

  return (first_parameter, parts)

#
# https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Content-Disposition
#
proc processHeader(
  raw_headers: seq[string]
): Future[(string, Table[string, string])] {.async.} =

  var
    formname = ""
    filename = ""
    content_type = ""

  for raw_header in raw_headers:
    # echo ">> Raw Header: " & raw_header
    let (h_head, h_tail) = splitInTwo(raw_header, ':')
    if h_head == "Content-Disposition":
      let (first_parameter, content_disposition_parts) = splitContentDisposition(h_tail)
      if first_parameter != "form-data": continue
      for content_disposition_part in content_disposition_parts:
        let pair = content_disposition_part.split("=", maxsplit=1)
        if pair.len == 2:
          let value = if pair[1][0] == '"' and pair[1][high(pair[1])] == '"':
              pair[1][1 .. pair[1].len-2]
            else:
              pair[1]
          # echo ">> Pair: " & pair[0] & " = " & value
          if value.len > 0:
            if pair[0] == "name":
              formname = value
          if pair[0] == "filename":
            filename = value

    elif h_head == "Content-Type":
      # echo ">> Raw Header: " & h_head & " = " & h_tail
      content_type = h_tail

  var formData = initTable[string, string]()
  if filename.len > 0 or content_type.len > 0:
    formData.add("filename", filename)
    formData.add("content-type", content_type)
  else:
    formData.add("data", "")

  # echo ">> Form Data: " & $formData

  return (formname, formData)

#
# https://tools.ietf.org/html/rfc7578
# https://tools.ietf.org/html/rfc2046#section-5.1
# https://www.w3.org/Protocols/rfc1341/7_2_Multipart.html
# https://httpstatuses.com/400
#
proc processRequestMultipartBody(
  self: AsyncHttpBodyParser,
  req: Request
): Future[void] {.async.} =

  let boundary = "--$1" % req.headers["Content-type"][30 .. high(req.headers["Content-type"])]
  # echo ">> Boundary: " & boundary
  if boundary.len < 3 or boundary.len > 72:
    bodyParserError(Http500, "Multipart/data malformed request syntax")

  self.formData = newTable[string, string]()
  self.formFiles = newTable[string, FileAttributes]()

  proc initFileAttributes(form: Table[string, string]): FileAttributes =
    var attributes: FileAttributes
    attributes.filename = if form.hasKey("filename"): form["filename"] else: "unknown"
    attributes.content_type = if form.hasKey("content_type"): form["content_type"] else: ""
    attributes.filesize = 0
    attributes.fileStream = newFutureStream[string]()

    return attributes

  block parser:

    var countBoundaryChars = 0

    var
      readBoundary = true
      findHeaders = false
      readHeader = false
      readContent = true

    var
      bag = ""
      buffer = ""

    var rawHeaders = newSeq[string]()
    var formname = ""

    # read 8*1024 bytes at a time
    while (let data = await req.bodyStream.read(); data[0]):
      for i in 0 .. data[1].len-1:

        if readContent:
          # echo data[1][0]
          
          # echo ">> Find a Boundary: " & data[1][i]
          if readBoundary and data[1][i] == boundary[countBoundaryChars]:
            if countBoundaryChars == high(boundary):
              # echo ">> Boundary found"
              
              # begin the suffix of boundary before "\c\L--boundary"
              if bag.len > 1:
                bag.removeSuffix("\c\L")

              buffer.add(data[1][i])

              #--- begin if there are still characters in the bag ---
              # echo "Check the bag: " & buffer & " = " & boundary
              if ((let diff = buffer.len - boundary.len); diff) > 0:
                # echo ">> Diferrence: " & $diff
                bag.add(buffer[0 .. diff - 1])

              if bag.len > 0:
                # echo ">> Empty bag: " & bag & " => " & formname
                if self.formFiles.hasKey(formname) and self.formFiles[formname].filename.len > 0:
                  await self.formFiles[formname].fileStream.write(bag)
                  self.formFiles[formname].filesize += bag.len
                elif self.formData.hasKey(formname):
                  self.formData[formname].add(bag)
                bag = ""

              if self.formFiles.hasKey(formname) and self.formFiles[formname].filename.len > 0:
                self.formFiles[formname].fileStream.complete()

              #--- end if there are still characters in the bag ---

              findHeaders = true
              readContent = false
              readHeader = false
              countBoundaryChars = 0
              continue

            # echo "On the right path to find the Boundary: " & data[1][i] & " = " & boundary[countBoundaryChars]
            buffer.add(data[1][i])
            countBoundaryChars += 1
            continue

          if buffer.len > 0:
            bag.add(buffer)
            buffer = ""

          # if not match the boundary char add stream char to the bag
          bag.add(data[1][i])
          
          # --- begin empty bag if full ---
          if bag.len > chunkSize:
            # echo ">> Empty bag: " & bag
            if self.formFiles.hasKey(formname) and self.formFiles[formname].filename.len > 0:
              await self.formFiles[formname].fileStream.write(bag)
              self.formFiles[formname].filesize += bag.len
            elif self.formData.hasKey(formname):
              self.formData[formname].add(bag)
            bag = ""
          # --- end empty bag if full ---

          countBoundaryChars = 0
          continue

        if readHeader:
          if data[1][i] == '\c': continue
          if data[1][i] == '\L':
            if buffer.len == 0:
              readHeader = false
              readContent = true
              # echo ">> Process headers"
              #--- begin process headers ---

              if rawHeaders.len > 0:
                # echo ">> Raw Headers: " & $rawHeaders
                let (name, form) = await processHeader(rawHeaders)

                formname = name
                # echo ">> Form Name: " & formname
                #---begin check the type if is a filename or a data value
                if form.hasKey("filename"):
                  var fileattr = initFileAttributes(form)
                  self.formFiles.add(name, fileattr)

                  if form.hasKey("content-type"):
                    self.formFiles[formname].content_type = form["content-type"]

                else:
                  self.formData.add(name, form["data"])
                rawHeaders.setLen(0)
                #-- end check the type if is a filename or a data value

              #--- end process headers ---
              continue

            # echo ">> Header Line: " & buffer
            rawHeaders.add(buffer)
            buffer = ""
            bag = ""
            continue

          buffer.add(data[1][i])
          continue

        if findHeaders:
          # echo ">> Find the tail of Boundary: " & buffer & " = " & buffer[buffer.len - 2 .. buffer.len - 1]
          if buffer[high(buffer) - 1 .. high(buffer)] == "--":
            # echo ">> Tail of Boundary found"
            buffer = ""
            break parser

          if data[1][i] == '-':
            buffer.add(data[1][i])
            continue
          if data[1][i] == '\c': continue
          if data[1][i] == '\L':
            readHeader = true
            buffer = ""
            continue

        bodyParserError(Http500, "Multipart/data malformed request syntax")

proc processRequestBody(
  self: AsyncHttpBodyParser,
  req: Request
): Future[void] {.async.} =

  # echo ">> Begin Process Body"
  self.formData = newTable[string, string]()

  var
    buffer = ""
    name = ""
    encodedchar = ""

  # read 8*1024 bytes at a time
  while (let data = await req.bodyStream.read(); data[0]):
    for i in 0 .. high(data[1]):
      # echo data[1][i]  

      if name.len > 0 and data[1][i] == '&':
        # echo ">> End of the value found"
        self.formData.add(name, buffer)
        name = ""
        buffer = ""
        continue

      if data[1][i] == '=':
        # echo ">> End of the key found"
        name = buffer
        buffer = ""
        continue

      if encodedchar.len > 1:
        encodedchar.add(data[1][i])
        if (encodedchar.len - 1) mod 3 == 0: # check the 3 and 3
          # echo ">> ENCODED CHAR: " & encodedchar
          let decodedchar = chr(fromHex[int](encodedchar))
          # echo ">> DECODED CHAR: " & decodedchar
          if decodedchar != '\x00':
            buffer.add(decodedchar)
            encodedchar = ""
            continue
        continue

      if data[1][i] == '%':
        encodedchar.add("0x")
        continue

      if data[1][i] == '+':
        buffer.add(' ')
        continue

      buffer.add(data[1][i])

  if name.len > 0:
    self.formData.add(name, buffer)

proc newAsyncHttpBodyParser*(req: Request): Future[AsyncHttpBodyParser] {.async.} =

  ## Creates a new ``AsyncHttpBodyParser`` instance.
  when (NimMajor, NimMinor) >= (1, 1):
    if not req.headers.hasKey("Content-type"):
      # 400 Bad Request
      bodyParserError(Http400, "No Content-Type header was found")

    new result
    if req.headers["Content-type"].len > 32 and
      req.headers["Content-type"][0 .. 29] == "multipart/form-data; boundary=":
      result.multipart = true
      await result.processRequestMultipartBody(req)
    elif req.headers["Content-type"] == "application/x-www-form-urlencoded":
      result.multipart = false
      await result.processRequestBody(req)
    else:
      bodyParserError(Http400,
        "Invalid Content-Type only multipart/form-data or application/x-www-form-urlencoded is supported")
  else:
    {.error: "the asynchttpbodyparser module require 1.1 Nim version or greater!".}
