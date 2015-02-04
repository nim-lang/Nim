# Test the new template file mechanism

import
  os, times

include "sunset.tmpl"

const
  tabs = [["home", "index"],
          ["news", "news"],
          ["documentation", "documentation"],
          ["download", "download"],
          ["FAQ", "question"],
          ["links", "links"]]


var i = 0
for item in items(tabs):
  var content = $i
  var file: TFile
  if open(file, changeFileExt(item[1], "html"), fmWrite):
    write(file, sunsetTemplate(current=item[1], ticker="", content=content,
                               tabs=tabs))
    close(file)
  else:
    write(stdout, "cannot open file for writing")
  inc(i)
