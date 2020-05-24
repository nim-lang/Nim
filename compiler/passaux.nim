#
#
#           The Nim Compiler
#        (c) Copyright 2012 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## implements some little helper passes

import
  ast, passes, idents, msgs, options, idgen, lineinfos

from modulegraphs import ModuleGraph, PPassContext

type
  VerboseRef = ref object of PPassContext
    config: ConfigRef

proc verboseOpen(graph: ModuleGraph; s: PSym): PPassContext =
  #MessageOut('compiling ' + s.name.s);
  let flag = if optListFullPaths in graph.config.globalOptions: foAbs else: foShort
  let fname = graph.config.toFilenameOption(s.position.FileIndex, flag)
  result = VerboseRef(config: graph.config)
  rawMessage(graph.config, hintProcessing, fname)

proc verboseProcess(context: PPassContext, n: PNode): PNode =
  result = n
  let v = VerboseRef(context)
  if v.config.verbosity == 3:
    # system.nim deactivates all hints, for verbosity:3 we want the processing
    # messages nonetheless, so we activate them again (but honor cmdlineNotes)
    v.config.setNote(hintProcessing)
    message(v.config, n.info, hintProcessing, $idgen.gFrontEndId)

const verbosePass* = makePass(open = verboseOpen, process = verboseProcess)
