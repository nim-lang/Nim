# Test the dialogs module

import dialogs, gtk2

gtk2.nimrod_init()

var x = ChooseFilesToOpen(nil)
for a in items(x):
  writeln(stdout, a)

info(nil, "start with an info box")
warning(nil, "now a warning ...")
error(nil, "... and an error!")

writeln(stdout, ChooseFileToOpen(nil))
writeln(stdout, ChooseFileToSave(nil))
writeln(stdout, ChooseDir(nil))
