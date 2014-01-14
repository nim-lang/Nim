#
#
#            Nimrod Tester
#        (c) Copyright 2014 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## HTML generator for the tester.

import db_sqlite, cgi, backend, strutils

const
  TableHeader = """<table border="1">
                      <tr><td>Test</td><td>Category</td><td>Target</td>
                          <td>Action</td>
                          <td>Expected</td>
                          <td>Given</td>
                          <td>Success</td></tr>"""
  TableFooter = "</table>"
  HtmlBegin = """<html>
    <head> 
      <title>Test results</title>
      <style type="text/css">
      <!--""" & slurp("css/boilerplate.css") & "\n" &
                slurp("css/style.css") &
      """
ul#tabs { list-style-type: none; margin: 30px 0 0 0; padding: 0 0 0.3em 0; }
ul#tabs li { display: inline; }
ul#tabs li a { color: #42454a; background-color: #dedbde; 
               border: 1px solid #c9c3ba; border-bottom: none; 
               padding: 0.3em; text-decoration: none; }
ul#tabs li a:hover { background-color: #f1f0ee; }
ul#tabs li a.selected { color: #000; background-color: #f1f0ee; 
                        font-weight: bold; padding: 0.7em 0.3em 0.38em 0.3em; }
div.tabContent { border: 1px solid #c9c3ba; 
                 padding: 0.5em; background-color: #f1f0ee; }
div.tabContent.hide { display: none; }
      -->
    </style>
    <script>

    var tabLinks = new Array();
    var contentDivs = new Array();
    
    function init() {
      // Grab the tab links and content divs from the page
      var tabListItems = document.getElementById('tabs').childNodes;
      for ( var i = 0; i < tabListItems.length; i++ ) {
        if ( tabListItems[i].nodeName == "LI" ) {
          var tabLink = getFirstChildWithTagName( tabListItems[i], 'A' );
          var id = getHash( tabLink.getAttribute('href') );
          tabLinks[id] = tabLink;
          contentDivs[id] = document.getElementById( id );
        }
      }
      // Assign onclick events to the tab links, and
      // highlight the first tab
      var i = 0;
      for ( var id in tabLinks ) {
        tabLinks[id].onclick = showTab;
        tabLinks[id].onfocus = function() { this.blur() };
        if ( i == 0 ) tabLinks[id].className = 'selected';
        i++;
      }
      // Hide all content divs except the first
      var i = 0;
      for ( var id in contentDivs ) {
        if ( i != 0 ) contentDivs[id].className = 'tabContent hide';
        i++;
      }
    }

    function getFirstChildWithTagName( element, tagName ) {
      for ( var i = 0; i < element.childNodes.length; i++ ) {
        if ( element.childNodes[i].nodeName == tagName ) return element.childNodes[i];
      }
    }
    function getHash( url ) {
      var hashPos = url.lastIndexOf ( '#' );
      return url.substring( hashPos + 1 );
    }
    </script>

    </head>
    <body onload="init()">"""
  
  HtmlEnd = "</body></html>"

proc td(s: string): string =
  result = "<td>" & s.substr(0, 200).XMLEncode & "</td>"

proc generateHtml*(filename: string) =
  const selRow = """select name, category, target, action, 
                           expected, given, result
                     from TestResult
                     where [commit] = ? and machine = ?
                     order by category"""
  var db = open(connection="testament.db", user="testament", password="",
                database="testament")
  var outfile = open(filename, fmWrite)
  outfile.write(HtmlBegin)
  let thisMachine = backend.getMachine()
  outfile.write()

  let machine = db.getRow(sql"select name, os, cpu from machine where id = ?",
                           thisMachine)
  outfile.write("<p><b>$#</b></p>" % machine.join(" "))

  outfile.write("""<ul id="tabs">""")
  
  for thisCommit in db.rows(sql"select id from [Commit] order by id desc"):
    let lastCommit = thisCommit[0]
    let commit = db.getValue(sql"select hash from [Commit] where id = ?",
                              lastCommit)
    let branch = db.getValue(sql"select branch from [Commit] where id = ?",
                              lastCommit)

    outfile.writeln """<li><a href="#$#">$#: $#</a></li>""" % [
      lastCommit, branch, commit]
  outfile.write("</ul>")
  
  for thisCommit in db.rows(sql"select id from [Commit] order by id desc"):
    let lastCommit = thisCommit[0]
    outfile.write("""<div class="tabContent" id="$#">""" % lastCommit)

    outfile.write(TableHeader)
    for row in db.rows(sql(selRow), lastCommit, thisMachine):
      outfile.write("<tr>")
      for x in row:
        outfile.write(x.td)
      outfile.write("</tr>")

    outfile.write(TableFooter)
    outfile.write("</div>")
  outfile.write(HtmlEnd)
  close(db)
  close(outfile)
