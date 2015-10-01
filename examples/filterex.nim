#? stdtmpl | standard
#proc generateHTMLPage(title, currentTab, content: string,
#                      tabs: openArray[string]): string =
#  result = ""
<head><title>$title</title></head>
<body>
  <div id="menu">
    <ul>
  #for tab in items(tabs):
    #if currentTab == tab:
    <li><a id="selected"
    #else:
    <li><a
    #end if
    href="${tab}.html" title = "$title - $tab">$tab</a></li>
  #end for
    </ul>
  </div>
  <div id="content">
    $content
    A dollar: $$.
  </div>
</body>
