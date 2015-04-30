#
#
#            Nim Tester
#        (c) Copyright 2015 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## HTML generator for the tester.

import db_sqlite, cgi, backend, strutils, json

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
      for (var i = 0; i < tabListItems.length; i++) {
        if (tabListItems[i].nodeName == "LI") {
          var tabLink = getFirstChildWithTagName(tabListItems[i], 'A');
          var id = getHash(tabLink.getAttribute('href'));
          tabLinks[id] = tabLink;
          contentDivs[id] = document.getElementById(id);
        }
      }
      // Assign onclick events to the tab links, and
      // highlight the first tab
      var i = 0;
      for (var id in tabLinks) {
        tabLinks[id].onclick = showTab;
        tabLinks[id].onfocus = function() { this.blur() };
        if (i == 0) tabLinks[id].className = 'selected';
        i++;
      }
      // Hide all content divs except the first
      var i = 0;
      for (var id in contentDivs) {
        if (i != 0) contentDivs[id].className = 'tabContent hide';
        i++;
      }
    }

    function showTab() {
      var selectedId = getHash(this.getAttribute('href'));

      // Highlight the selected tab, and dim all others.
      // Also show the selected content div, and hide all others.
      for (var id in contentDivs) {
        if (id == selectedId) {
          tabLinks[id].className = 'selected';
          contentDivs[id].className = 'tabContent';
        } else {
          tabLinks[id].className = '';
          contentDivs[id].className = 'tabContent hide';
        }
      }
      // Stop the browser following the link
      return false;
    }

    function getFirstChildWithTagName(element, tagName) {
      for (var i = 0; i < element.childNodes.length; i++) {
        if (element.childNodes[i].nodeName == tagName) return element.childNodes[i];
      }
    }
    function getHash(url) {
      var hashPos = url.lastIndexOf('#');
      return url.substring(hashPos + 1);
    }
    </script>

    </head>
    <body onload="init()">"""

  HtmlEnd = "</body></html>"

proc td(s: string): string =
  result = "<td>" & s.substr(0, 200).xmlEncode & "</td>"

proc getCommit(db: TDbConn, c: int): string =
  var commit = c
  for thisCommit in db.rows(sql"select id from [Commit] order by id desc"):
    if commit == 0: result = thisCommit[0]
    inc commit

proc generateHtml*(filename: string, commit: int; onlyFailing: bool) =
  const selRow = """select name, category, target, action,
                           expected, given, result
                    from TestResult
                    where [commit] = ? and machine = ?
                    order by category"""
  var db = open(connection="testament.db", user="testament", password="",
                database="testament")
  # search for proper commit:
  let lastCommit = db.getCommit(commit)

  var outfile = open(filename, fmWrite)
  outfile.write(HtmlBegin)

  let commit = db.getValue(sql"select hash from [Commit] where id = ?",
                            lastCommit)
  let branch = db.getValue(sql"select branch from [Commit] where id = ?",
                            lastCommit)
  outfile.write("<p><b>$# $#</b></p>" % [branch, commit])

  # generate navigation:
  outfile.write("""<ul id="tabs">""")
  for m in db.rows(sql"select id, name, os, cpu from Machine order by id"):
    outfile.writeln """<li><a href="#$#">$#: $#, $#</a></li>""" % m
  outfile.write("</ul>")

  for currentMachine in db.rows(sql"select id from Machine order by id"):
    let m = currentMachine[0]
    outfile.write("""<div class="tabContent" id="$#">""" % m)

    outfile.write(TableHeader)
    for row in db.rows(sql(selRow), lastCommit, m):
      if onlyFailing and row.len > 0 and row[row.high] == "reSuccess":
        discard
      else:
        outfile.write("<tr>")
        for x in row:
          outfile.write(x.td)
        outfile.write("</tr>")

    outfile.write(TableFooter)
    outfile.write("</div>")
  outfile.write(HtmlEnd)
  close(db)
  close(outfile)

proc generateJson*(filename: string, commit: int) =
  const
    selRow = """select count(*),
                           sum(result = 'reSuccess'),
                           sum(result = 'reIgnored')
                from TestResult
                where [commit] = ? and machine = ?
                order by category"""
    selDiff = """select A.category || '/' || A.target || '/' || A.name,
                        A.result,
                        B.result
                from TestResult A
                inner join TestResult B
                on A.name = B.name and A.category = B.category
                where A.[commit] = ? and B.[commit] = ? and A.machine = ?
                   and A.result != B.result"""
    selResults = """select
                      category || '/' || target || '/' || name,
                      category, target, action, result, expected, given
                    from TestResult
                    where [commit] = ?"""
  var db = open(connection="testament.db", user="testament", password="",
                database="testament")
  let lastCommit = db.getCommit(commit)
  if lastCommit.isNil:
    quit "cannot determine commit " & $commit

  let previousCommit = db.getCommit(commit-1)

  var outfile = open(filename, fmWrite)

  let machine = $backend.getMachine(db)
  let data = db.getRow(sql(selRow), lastCommit, machine)

  outfile.writeln("""{"total": $#, "passed": $#, "skipped": $#""" % data)

  let results = newJArray()
  for row in db.rows(sql(selResults), lastCommit):
    var obj = newJObject()
    obj["name"] = %row[0]
    obj["category"] = %row[1]
    obj["target"] = %row[2]
    obj["action"] = %row[3]
    obj["result"] = %row[4]
    obj["expected"] = %row[5]
    obj["given"] = %row[6]
    results.add(obj)
  outfile.writeln(""", "results": """)
  outfile.write(results.pretty)

  if not previousCommit.isNil:
    let diff = newJArray()

    for row in db.rows(sql(selDiff), previousCommit, lastCommit, machine):
      var obj = newJObject()
      obj["name"] = %row[0]
      obj["old"] = %row[1]
      obj["new"] = %row[2]
      diff.add obj
    outfile.writeln(""", "diff": """)
    outfile.writeln(diff.pretty)

  outfile.writeln "}"
  close(db)
  close(outfile)
