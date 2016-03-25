discard """
  action: run
"""

import xmltree, strtabs, xmlparser, future, strutils, unittest

let xml = """
<SOAP-ENV:Envelope xmlns:SOAP-ENV="http://schemas.xmlsoap.org/soap/envelope/"
    xmlns:v1="http://test.lan/api/v1">
    <SOAP-ENV:Header/>
    <SOAP-ENV:Body>
        <v1:LogonRequest>
            <v1:user_name>test</v1:user_name>
            <v1:password>pwd</v1:password>
        </v1:LogonRequest>
    </SOAP-ENV:Body>
</SOAP-ENV:Envelope>
""".parseXml

suite "xmltree":
  test "Contructor macro":
    let x = <>a(href="nim.de", newText("www.nim-test.de"))
    check: $x == "<a href=\"nim.de\">www.nim-test.de</a>"

  test "findAll with predicate":
    let n = xml.findAll(n => n.tag.endsWith(":password"))
    check: n.len == 1 and n[0].innerText() == "pwd"

  test "child with predicate":
    let c = xml.child(n => n.len == 0)
    check: c != nil and c.tag == "SOAP-ENV:Header"

  test "findAttr with predicate":
    let ns = xml.findAttr(n => n.split(":").len == 2 and xml.attr(n) == "http://test.lan/api/v1").split(":")[1]
    check: ns == "v1"
