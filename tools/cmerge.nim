# Simple tool to merge C projects into a single C file

import os, strtabs, pegs

proc process(dir, infile: string, outfile: TFile, processed: PStringTable) =
  if processed.hasKey(infile): return
  processed[infile] = "True"
  echo "adding: ", infile
  for line in lines(dir / infile):
    if line =~ peg"""s <- ig '#include' ig '"' {[^"]+} '"' ig
                     comment <- '/*' !'*/'* '*/' / '//' .*
                     ig <- (comment / \s+)* """:
      # follow the include file:
      process(dir, matches[0], outfile, processed)
    else:
      writeln(outfile, line)

proc main(dir, outfile: string) =
  var o: TFile
  if open(o, outfile, fmWrite):
    var processed = newStringTable([outfile, "True"])
    for infile in walkfiles(dir / "*.c"):
      process(dir, extractFilename(infile), o, processed)
    close(o)
  else:
    quit("Cannot open for writing: " & outfile)

if ParamCount() != 2:
  echo "Usage: cmerge directory outfile"
else:
  main(ParamStr(1), addFileExt(ParamStr(2), "c"))
