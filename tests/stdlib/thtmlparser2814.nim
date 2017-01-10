discard """
  output: true
"""
import htmlparser
import xmltree
import strutils
from streams import newStringStream


## builds the two cases below and test that
## ``//[dd,li]`` has "<p>that</p>" as children
##
##  <dl>
##    <dt>this</dt>
##    <dd>
##      <p>that</p>
##    </dd>
##  </dl>

##
## <ul>
##   <li>
##     <p>that</p>
##   </li>
## </ul>


for ltype in [["dl","dd"], ["ul","li"]]:
  let desc_item = if ltype[0]=="dl": "<dt>this</dt>" else: ""
  let item = "$1<$2><p>that</p></$2>" % [desc_item, ltype[1]]
  let list = """ <$1>
   $2
</$1> """ % [ltype[0], item]

  var errors : seq[string] = @[]

  let parseH = parseHtml(newStringStream(list),"statichtml", errors =errors)

  if $parseH.findAll(ltype[1])[0].child("p") != "<p>that</p>":
    echo "case " & ltype[0] & " failed !"
    quit(2)


echo "true"
