#
#
#           The Nimrod Compiler
#        (c) Copyright 2010 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## Creates a server, opens a browser and starts serving a Repl for the user.
## Unfortunately it doesn't ever stop...

import httpserver, sockets, browsers, strutils, cgi, options

const
  gui = """
<html>  
  <head>
    <title>Nimrod Interactive Web Console</title>
  </head>
  
  <body>
    <form action="exec" method="get">
      <input type="submit" value="Run" /><br />
      <textarea name="code" cols="80" rows="30">import strutils, os

# your code here</textarea>
      <table border="0">
        <tr>
          <td><input type="checkbox" name="objChecks" checked="true"
               value="on">objChecks</input></td>
          <td><input type="checkbox" name="fieldChecks" checked="true"
               value="on">fieldChecks</input></td>
          <td><input type="checkbox" name="rangeChecks" checked="true"
               value="on">rangeChecks</input></td>
        </tr><tr>
          <td><input type="checkbox" name="boundChecks" checked="true"
               value="on">boundChecks</input></td>
          <td><input type="checkbox" name="overflowChecks" checked="true"
               value="on">overflowChecks</input></td>
          <td><input type="checkbox" name="nanChecks" checked="true"
               value="on">nanChecks</input></td>
        </tr><tr>
          <td><input type="checkbox" name="infChecks" checked="true"
               value="on">infChecks</input></td>
          <td><input type="checkbox" name="assertions" checked="true"
               value="on">assertions</input></td>
        </tr>
      </table>
    </form>
    $1
  </body>
</html>
"""

proc runCode(input: string): string =
  nil

proc handleRequest(client: TSocket, path, query: string) =
  var output = query
  client.send(gui % output & wwwNL)


var s: TServer
open(s, TPort(0))
browsers.openDefaultBrowser("http://localhost:" & $s.port)
while true: 
  next(s)
  handleRequest(s.client, s.path, s.query)
  close(s.client)
close(s)
