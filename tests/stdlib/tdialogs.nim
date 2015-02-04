# Test the dialogs module

import dialogs, gtk2

gtk2.nimrod_init()

var x = chooseFilesToOpen(nil)
for a in items(x):
  writeln(stdout, a)

info(nil, "start with an info box")
warning(nil, "now a warning ...")
error(nil, "... and an error!")

writeln(stdout, chooseFileToOpen(nil))
writeln(stdout, chooseFileToSave(nil))
writeln(stdout, chooseDir(nil))
