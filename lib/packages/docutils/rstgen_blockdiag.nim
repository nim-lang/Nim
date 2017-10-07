#
#        Nim's Runtime Library - blockdiag adaptor
#        (c) Copyright 2017 Federico Ceratto
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#
#
## Blockdiag rstgen adaptor
##
## See examples/blockdiag.nim for an example.

import math, os, osproc, random
from rstast import PRstNode

type
  BlockDiagRenderOutput* = object
    svg*, error*: string

proc renderBlockDiag*(n: PRstNode): BlockDiagRenderOutput =
  ## Render blockdiag diagram.
  ## Requires the blockdiag toolset from http://blockdiag.com/en/
  const
    input_fn = ".rstgen_blockdiag.tmp"
    out_fn = input_fn & ".svg"
  let
    diag_src = n.sons[n.sons.high].sons[0].text
    cmd = "blockdiag " & input_fn & " --nodoctype -Tsvg -o " & out_fn

  writeFile(input_fn, diag_src)
  let (output, exit_code) = execCmdEx(cmd, options={poStdErrToStdOut})
  removeFile input_fn

  if exit_code == 0:
    let svg = readFile out_fn
    removeFile out_fn
    return BlockDiagRenderOutput(error: "", svg: svg)

  # Fall back by showing the error message and the diagram source
  let svg = "Error rendering diagram: " & output & "\n" & diag_src
  return BlockDiagRenderOutput(error: output, svg: svg)

