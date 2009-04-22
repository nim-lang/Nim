
template withOpenFile(f, filename, mode: expr, actions: stmt): stmt =
  block:
    var f: TFile
    if openFile(f, filename, mode):
      try:
        actions
      finally:
        closeFile(f)
    else:
      quit("cannot open for writing: " & filename)
    
withOpenFile(txt, "ttempl3.txt", fmWrite):
  writeln(txt, "line 1")
  txt.writeln("line 2")
